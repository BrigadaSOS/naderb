FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "tag_#{n}" }
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    guild_id { "999888777" }

    # Image variations
    trait :with_image_url do
      content { Faker::LoremFlickr.image(size: "400x300", search_terms: [ 'cat' ]) }
    end

    trait :with_random_image do
      content do
        search_term = %w[cat dog nature space city technology food].sample
        Faker::LoremFlickr.image(size: "#{rand(300..600)}x#{rand(300..600)}", search_terms: [ search_term ])
      end
    end

    trait :with_grayscale_image do
      content { Faker::LoremFlickr.grayscale_image(size: "400x300", search_terms: [ 'nature' ]) }
    end

    trait :with_colorized_image do
      content do
        color = %w[red green blue].sample
        Faker::LoremFlickr.colorized_image(size: "400x300", color: color, search_terms: [ 'abstract' ])
      end
    end

    trait :with_pixelated_image do
      content { Faker::LoremFlickr.pixelated_image(size: "400x300", search_terms: [ 'retro', 'gaming' ]) }
    end

    # Content length variations
    trait :long_content do
      content { Faker::Lorem.paragraph(sentence_count: 20, supplemental: true, random_sentences_to_add: 10) }
    end

    trait :short_content do
      content { Faker::Lorem.sentence }
    end

    trait :minimal_content do
      content { Faker::Lorem.word }
    end

    # Fun content types
    trait :with_quote do
      content { Faker::Quote.famous_last_words }
    end

    trait :with_fact do
      content { Faker::ChuckNorris.fact }
    end

    trait :with_hipster_text do
      content { Faker::Hipster.paragraph(sentence_count: 2) }
    end

    # Technical content
    trait :with_url do
      content { Faker::Internet.url }
    end

    trait :with_code do
      content { "```ruby\n#{Faker::Lorem.paragraph(sentence_count: 3)}\n```" }
    end

    trait :with_markdown do
      content do
        <<~MARKDOWN
          # #{Faker::Lorem.sentence}

          #{Faker::Lorem.paragraph}

          - #{Faker::Lorem.sentence}
          - #{Faker::Lorem.sentence}
        MARKDOWN
      end
    end

    # Temporal variations
    trait :recently_created do
      created_at { Faker::Time.between(from: 7.days.ago, to: Time.now) }
    end

    trait :old do
      created_at { Faker::Time.between(from: 1.year.ago, to: 6.months.ago) }
    end

    trait :recently_updated do
      updated_at { Faker::Time.between(from: 1.day.ago, to: Time.now) }
    end
  end
end
