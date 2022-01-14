# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SendFileUpload do
  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include ObjectStorage::Concern

      storage_options Gitlab.config.uploads

      private

      # user/:id
      def dynamic_segment
        File.join(model.class.underscore, model.id.to_s)
      end
    end
  end

  let(:controller_class) do
    Class.new do
      include SendFileUpload

      def params
        {}
      end

      def current_user; end
    end
  end

  let(:object) { build_stubbed(:user) }
  let(:uploader) { uploader_class.new(object, :file) }

  describe '#send_upload' do
    let(:controller) { controller_class.new }
    let(:temp_file) { Tempfile.new('test') }
    let(:params) { {} }

    subject { controller.send_upload(uploader, **params) }

    before do
      FileUtils.touch(temp_file)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    shared_examples 'handles image resize requests' do
      let(:headers) { double }
      let(:image_requester) { build(:user) }
      let(:image_owner) { build(:user) }
      let(:params) do
        { attachment: 'avatar.png' }
      end

      before do
        allow(uploader).to receive(:image_safe_for_scaling?).and_return(true)
        allow(uploader).to receive(:mounted_as).and_return(:avatar)

        allow(controller).to receive(:headers).and_return(headers)
        # both of these are valid cases, depending on whether we are dealing with
        # local or remote files
        allow(controller).to receive(:send_file)
        allow(controller).to receive(:redirect_to)

        allow(controller).to receive(:current_user).and_return(image_requester)
        allow(uploader).to receive(:model).and_return(image_owner)
      end

      it_behaves_like 'handles image resize requests allowed by FF'

      context 'when FF is disabled' do
        before do
          stub_feature_flags(dynamic_image_resizing: false)
        end

        it_behaves_like 'bypasses image resize requests not allowed by FF'
      end
    end

    shared_examples 'bypasses image resize requests not allowed by FF' do
      it 'does not write workhorse command header' do
        expect(headers).not_to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-scaled-img:/)

        subject
      end
    end

    shared_examples 'handles image resize requests allowed by FF' do
      context 'with valid width parameter' do
        it 'renders OK with workhorse command header' do
          expect(controller).not_to receive(:send_file)
          expect(controller).to receive(:params).at_least(:once).and_return(width: '64')
          expect(controller).to receive(:head).with(:ok)

          expect(Gitlab::Workhorse).to receive(:send_scaled_image).with(a_string_matching('^(/.+|https://.+)'), 64, 'image/png').and_return([
            Gitlab::Workhorse::SEND_DATA_HEADER, "send-scaled-img:faux"
          ])
          expect(headers).to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, "send-scaled-img:faux")

          subject
        end
      end

      context 'with missing width parameter' do
        it 'does not write workhorse command header' do
          expect(headers).not_to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-scaled-img:/)

          subject
        end
      end

      context 'with invalid width parameter' do
        it 'does not write workhorse command header' do
          expect(controller).to receive(:params).at_least(:once).and_return(width: 'not a number')
          expect(headers).not_to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-scaled-img:/)

          subject
        end
      end

      context 'with width that is not allowed' do
        it 'does not write workhorse command header' do
          expect(controller).to receive(:params).at_least(:once).and_return(width: '63')
          expect(headers).not_to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-scaled-img:/)

          subject
        end
      end

      context 'when image file is not an avatar' do
        it 'does not write workhorse command header' do
          expect(uploader).to receive(:mounted_as).and_return(nil) # FileUploader is not mounted
          expect(headers).not_to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-scaled-img:/)

          subject
        end
      end

      context 'when image file type is not considered safe for scaling' do
        it 'does not write workhorse command header' do
          expect(uploader).to receive(:image_safe_for_scaling?).and_return(false)
          expect(headers).not_to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-scaled-img:/)

          subject
        end
      end
    end

    context 'when local file is used' do
      before do
        uploader.store!(temp_file)
      end

      it 'sends a file' do
        expect(controller).to receive(:send_file).with(uploader.path, anything)

        subject
      end

      it_behaves_like 'handles image resize requests'
    end

    context 'with inline image' do
      let(:filename) { 'test.png' }
      let(:params) { { disposition: 'inline', attachment: filename } }

      it 'sends a file with inline disposition' do
        expected_params = {
          filename: 'test.png',
          disposition: 'inline'
        }
        expect(controller).to receive(:send_file).with(uploader.path, expected_params)

        subject
      end
    end

    context 'with attachment' do
      let(:filename) { 'test.js' }
      let(:params) { { attachment: filename } }

      it 'sends a file with content-type of text/plain' do
        expected_params = {
          content_type: 'text/plain',
          filename: 'test.js',
          disposition: 'attachment'
        }
        expect(controller).to receive(:send_file).with(uploader.path, expected_params)

        subject
      end

      context 'with a proxied file in object storage' do
        before do
          stub_uploads_object_storage(uploader: uploader_class)
          uploader.object_store = ObjectStorage::Store::REMOTE
          uploader.store!(temp_file)
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { true }
        end

        it 'sends a file with a custom type' do
          headers = double
          expected_headers = /response-content-disposition=attachment%3B%20filename%3D%22test.js%22%3B%20filename%2A%3DUTF-8%27%27test.js&response-content-type=application%2Fjavascript/
          expect(Gitlab::Workhorse).to receive(:send_url).with(expected_headers).and_call_original
          expect(headers).to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-url:/)

          expect(controller).not_to receive(:send_file)
          expect(controller).to receive(:headers) { headers }
          expect(controller).to receive(:head).with(:ok)

          subject
        end
      end
    end

    context 'when remote file is used' do
      before do
        stub_uploads_object_storage(uploader: uploader_class)
        uploader.object_store = ObjectStorage::Store::REMOTE
        uploader.store!(temp_file)
      end

      shared_examples 'proxied file' do
        it 'sends a file' do
          headers = double
          expect(Gitlab::Workhorse).not_to receive(:send_url).with(/response-content-disposition/)
          expect(Gitlab::Workhorse).not_to receive(:send_url).with(/response-content-type/)
          expect(Gitlab::Workhorse).to receive(:send_url).and_call_original

          expect(headers).to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-url:/)
          expect(controller).not_to receive(:send_file)
          expect(controller).to receive(:headers) { headers }
          expect(controller).to receive(:head).with(:ok)

          subject
        end
      end

      context 'and proxying is enabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { true }
        end

        it_behaves_like 'proxied file'
      end

      context 'and proxying is disabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { false }
        end

        it 'sends a file' do
          expect(controller).to receive(:redirect_to).with(/#{uploader.path}/)

          subject
        end

        context 'with proxy requested' do
          let(:params) { { proxy: true } }

          it_behaves_like 'proxied file'
        end
      end

      it_behaves_like 'handles image resize requests'
    end
  end
end
