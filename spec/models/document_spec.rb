require 'rails_helper'

RSpec.describe Document, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:svg_file) }
    it { should validate_presence_of(:original_file_name) }
    it { should validate_inclusion_of(:status).in_array(Document::STATES) }
  end

  describe 'attachments' do
    it { should have_one_attached(:svg_file) }
    it { should have_one_attached(:pdf_file) }
  end

  describe 'state machine methods' do
    let(:document) { create(:document, :with_svg_file) }

    describe 'state checking methods' do
      Document::STATES.each do |state|
        it "responds to #{state}? method" do
          expect(document).to respond_to("#{state}?")
        end
      end

      it 'returns correct state' do
        document.update!(status: 'validating')

        expect(document.validating?).to be true
        expect(document.pending?).to be false
        expect(document.completed?).to be false
      end
    end

    describe 'transition methods' do
      it 'responds to all transition methods' do
        expect(document).to respond_to(:start_validation!)
        expect(document).to respond_to(:validation_succeed!)
        expect(document).to respond_to(:validation_fail!)
        expect(document).to respond_to(:complete!)
        expect(document).to respond_to(:fail!)
      end

      it 'transitions states correctly' do
        expect(document.pending?).to be true

        document.start_validation!
        expect(document.validating?).to be true

        document.validation_succeed!
        expect(document.processing?).to be true

        document.complete!
        expect(document.completed?).to be true
      end

      it 'handles validation failure path' do
        document.start_validation!
        document.validation_fail!

        expect(document.validation_failed?).to be true
      end

      it 'handles processing failure' do
        document.start_validation!
        document.validation_succeed!
        document.fail!

        expect(document.failed?).to be true
      end
    end
  end

  describe '#svg_content' do
    context 'when svg_file is attached' do
      let(:document) { create(:document, :with_svg_file) }

      it 'returns svg content' do
        content = document.svg_content

        expect(content).to be_present
        expect(content).to include('<svg')
        expect(content).to include('xmlns="http://www.w3.org/2000/svg"')
      end
    end

    context 'when svg_file is not attached' do
      let(:document) { build(:document) }

      it 'returns nil' do
        expect(document.svg_content).to be_nil
      end
    end
  end
end
