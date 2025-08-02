FactoryBot.define do
  factory :document do
    original_file_name { 'test.svg' }
    status { 'pending' }

    after(:build) do |document|
      document.svg_file.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test.svg')),
        filename: 'test.svg',
        content_type: 'image/svg+xml'
      )
    end
  end
end
