class Document < ApplicationRecord
  STATES = %w[pending validating validation_failed processing completed failed].freeze
  TRANSITIONS = {
    start_validation: "validating",
    validation_succeed: "processing",
    validation_fail: "validation_failed",
    complete: "completed",
    fail: "failed"
  }.freeze

  has_one_attached :svg_file
  has_one_attached :pdf_file

  validates :svg_file, :original_file_name, presence: true
  validates :status, inclusion: { in: STATES }

  STATES.each do |state|
    define_method "#{state}?" do
      status == state
    end
  end

  TRANSITIONS.each do |method_name, new_state|
    define_method "#{method_name}!" do
      logger.info "Document #{id} transition #{status} to #{new_state}"

      update!(status: new_state)
    end
  end

  def svg_content
    return nil unless svg_file.attached?

    svg_file.download
  end
end
