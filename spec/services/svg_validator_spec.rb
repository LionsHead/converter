require 'rails_helper'

RSpec.describe SvgValidator do
  let(:valid_svg) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:invalid_svg) { '<svg><circle cx="50" cy="50" r="40" fill="red">' }
  let(:empty_svg) { '' }
  let(:nil_svg) { nil }

  describe '#call' do
    subject { described_class.new(valid_svg) }

    it { should respond_to(:call) }

    context 'with valid SVG content' do
      subject { described_class.call(valid_svg) }

      it { should be_success }
    end

    context 'with empty SVG content' do
      subject { described_class.call(empty_svg) }

      it { should be_failure }

      it 'has correct error message' do
        expect(subject.error).to eq('Empty SVG content')
      end
    end

    context 'with nil SVG content' do
      subject { described_class.call(nil_svg) }

      it { should be_failure }

      it 'has correct error message' do
        expect(subject.error).to eq('Empty SVG content')
      end
    end

    context 'with invalid XML structure' do
      subject { described_class.call(invalid_svg) }

      it { should be_failure }

      it 'has correct error message' do
        expect(subject.error).to eq('Invalid XML structure')
      end

      it 'includes errors in data' do
        expect(subject.data).to have_key(:errors)
        expect(subject.data[:errors]).to include('Invalid XML structure')
      end
    end
  end
end
