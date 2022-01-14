# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sanitizable do
  let_it_be(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
      include Sanitizable

      attribute :id, :integer
      attribute :name, :string
      attribute :description, :string
      attribute :html_body, :string

      sanitizes! :name, :description

      def self.model_name
        ActiveModel::Name.new(self, nil, 'SomeModel')
      end
    end
  end

  shared_examples 'noop' do
    it 'has no effect' do
      expect(subject).to eq(input)
    end
  end

  shared_examples 'a sanitizable field' do |field|
    let(:record) { klass.new(id: 1, name: input, description: input, html_body: input) }

    before do
      record.valid?
    end

    subject { record.public_send(field) }

    describe field do
      context 'when input is nil' do
        let_it_be(:input) { nil }

        it_behaves_like 'noop'
      end

      context 'when input does not contain any html' do
        let_it_be(:input) { 'hello, world!' }

        it_behaves_like 'noop'
      end

      context 'when input contains html' do
        let_it_be(:input) { 'hello<script>alert(1)</script>' }

        it 'sanitizes the input' do
          expect(subject).to eq('hello')
        end

        context 'when input includes html entities' do
          let(:input) { '<div>hello&world</div>' }

          it 'does not escape them' do
            expect(subject).to eq(' hello&world ')
          end
        end
      end

      context 'when input contains pre-escaped html entities' do
        let_it_be(:input) { '&lt;script&gt;alert(1)&lt;/script&gt;' }

        it_behaves_like 'noop'

        it 'is not valid', :aggregate_failures do
          expect(record).not_to be_valid
          expect(record.errors.full_messages).to include('Name cannot contain escaped HTML entities')
        end
      end
    end
  end

  shared_examples 'a non-sanitizable field' do |field, input|
    describe field do
      subject { klass.new(field => input).valid? }

      it 'has no effect' do
        expect(Sanitize).not_to receive(:fragment)

        subject
      end
    end
  end

  it_behaves_like 'a non-sanitizable field', :id, 1
  it_behaves_like 'a non-sanitizable field', :html_body, 'hello<script>alert(1)</script>'

  it_behaves_like 'a sanitizable field', :name
  it_behaves_like 'a sanitizable field', :description
end
