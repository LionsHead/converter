FactoryBot.define do
  factory :document do
    original_file_name { 'test_image.svg' }
    status { 'pending' }

    trait :with_svg_file do
      after(:build) do |document|
        svg_content = <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
            <circle cx="50" cy="50" r="40" fill="blue"/>
          </svg>
        SVG

        document.svg_file.attach(
          io: StringIO.new(svg_content),
          filename: 'test.svg',
          content_type: 'image/svg+xml'
        )
      end
    end

    trait :with_pdf_file do
      after(:build) do |document|
        document.pdf_file.attach(
          io: StringIO.new('fake pdf content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end
    end

    trait :validating do
      status { "validating" }
    end

    trait :processing do
      status { "processing" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :validation_failed do
      status { "validation_failed" }
    end
  end
end
