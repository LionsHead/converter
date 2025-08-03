require 'rails_helper'

RSpec.describe HtmlBuilder do
  let(:svg_content) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:watermark_text) { 'Sample Watermark' }

  subject { described_class.new(svg_content, watermark_text) }

  describe '#call' do
    it { should respond_to(:call) }

    context 'returned HTML' do
      subject(:html_output) { described_class.call(svg_content, watermark_text).data }

      it { should be_a(String) }
      it { should include('<!DOCTYPE html>') }
      it { should include(svg_content) }
      it { should include(watermark_text) }
      it { should include('<div class="page">') }
      it { should include('<div class="content">') }
      it { should include('<div class="watermark">') }
    end
  end
end
