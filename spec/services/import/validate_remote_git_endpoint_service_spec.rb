# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ValidateRemoteGitEndpointService do
  include StubRequests

  let_it_be(:base_url) { 'http://demo.host/path' }
  let_it_be(:endpoint_url) { "#{base_url}/info/refs?service=git-upload-pack" }
  let_it_be(:error_message) { "#{base_url} is not a valid HTTP Git repository" }

  describe '#execute' do
    let(:valid_response) do
      { status: 200,
        body: '001e# service=git-upload-pack',
        headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' } }
    end

    it 'correctly handles URLs with fragment' do
      allow(Gitlab::HTTP).to receive(:get)

      described_class.new(url: "#{base_url}#somehash").execute

      expect(Gitlab::HTTP).to have_received(:get).with(endpoint_url, basic_auth: nil, stream_body: true, follow_redirects: false)
    end

    context 'when receiving HTTP response' do
      subject { described_class.new(url: base_url) }

      it 'returns success when HTTP response is valid and contains correct payload' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response)

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end

      it 'reports error when status code is not 200' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response.merge({ status: 301 }))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(error_message)
      end

      it 'reports error when invalid URL is provided' do
        result = described_class.new(url: 1).execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('1 is not a valid URL')
      end

      it 'reports error when required header is missing' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response.merge({ headers: nil }))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(error_message)
      end

      it 'reports error when body is in invalid format' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response.merge({ body: 'invalid content' }))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(error_message)
      end

      it 'reports error when exception is raised' do
        stub_full_request(endpoint_url, method: :get).to_raise(SocketError.new('dummy message'))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(error_message)
      end
    end

    it 'passes basic auth when credentials are provided' do
      allow(Gitlab::HTTP).to receive(:get)

      described_class.new(url: "#{base_url}#somehash", user: 'user', password: 'password').execute

      expect(Gitlab::HTTP).to have_received(:get).with(endpoint_url, basic_auth: { username: 'user', password: 'password' }, stream_body: true, follow_redirects: false)
    end
  end
end
