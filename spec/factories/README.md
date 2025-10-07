# Factory Usage Guide

This guide shows how to use our enhanced factories with Faker.

## User Factory

### Basic Usage
```ruby
create(:user)  # Creates user with random username, display name, avatar, locale
```

### Traits

**`:inactive`** - Inactive user with past updated_at timestamp
```ruby
create(:user, :inactive)
```

**`:with_real_name`** - Uses realistic full name instead of username
```ruby
create(:user, :with_real_name)
# => display_name: "John Smith"
```

**`:recently_created`** - User created in last 7 days
```ruby
create(:user, :recently_created)
```

**`:veteran`** - User created 1-2 years ago
```ruby
create(:user, :veteran)
```

**`:with_tags`** - Creates user with multiple tags
```ruby
create(:user, :with_tags, tags_count: 5)
```

### Combined Traits
```ruby
create(:user, :veteran, :with_real_name, :with_tags, tags_count: 10)
```

## Tag Factory

### Basic Usage
```ruby
create(:tag)  # Creates tag with Lorem ipsum paragraph content
```

### Image Traits

**`:with_image_url`** - Cat image
```ruby
create(:tag, :with_image_url)
# => content: "https://loremflickr.com/400/300/cat"
```

**`:with_random_image`** - Random subject image (cat, dog, nature, space, city, technology, food)
```ruby
create(:tag, :with_random_image)
# => content: "https://loremflickr.com/450/350/nature"
```

**`:with_grayscale_image`** - Grayscale nature image
```ruby
create(:tag, :with_grayscale_image)
# => content: "https://loremflickr.com/g/400/300/nature"
```

**`:with_colorized_image`** - Color-filtered image (red, green, or blue)
```ruby
create(:tag, :with_colorized_image)
# => content: "https://loremflickr.com/red/400/300/abstract"
```

**`:with_pixelated_image`** - Pixelated retro/gaming image
```ruby
create(:tag, :with_pixelated_image)
# => content: "https://loremflickr.com/p/400/300/retro,gaming"
```

### Content Length Traits

**`:short_content`** - Single sentence
```ruby
create(:tag, :short_content)
# => content: "Quasi accusantium et id."
```

**`:minimal_content`** - Single word
```ruby
create(:tag, :minimal_content)
# => content: "voluptas"
```

**`:long_content`** - Multiple paragraphs
```ruby
create(:tag, :long_content)
# => content: "Lorem ipsum dolor sit amet..." (20+ sentences)
```

### Fun Content Traits

**`:with_quote`** - Famous last words
```ruby
create(:tag, :with_quote)
# => content: "I should never have switched from Scotch to Martinis."
```

**`:with_fact`** - Chuck Norris fact
```ruby
create(:tag, :with_fact)
# => content: "Chuck Norris can divide by zero."
```

**`:with_hipster_text`** - Hipster lorem ipsum
```ruby
create(:tag, :with_hipster_text)
# => content: "Stumptown neutra tilde biodiesel sustainable..."
```

### Technical Content Traits

**`:with_url`** - Random URL
```ruby
create(:tag, :with_url)
# => content: "https://example.com/path"
```

**`:with_code`** - Code block with markdown
```ruby
create(:tag, :with_code)
# => content: "```ruby\nLorem ipsum...\n```"
```

**`:with_markdown`** - Formatted markdown document
```ruby
create(:tag, :with_markdown)
# => content: "# Heading\n\nParagraph...\n\n- Item 1\n- Item 2"
```

### Temporal Traits

**`:recently_created`** - Created in last 7 days
```ruby
create(:tag, :recently_created)
```

**`:old`** - Created 6-12 months ago
```ruby
create(:tag, :old)
```

**`:recently_updated`** - Updated in last 24 hours
```ruby
create(:tag, :recently_updated)
```

### Combined Traits
```ruby
# Old tag with a quote that was recently updated
create(:tag, :old, :with_quote, :recently_updated)

# Recently created pixelated image tag
create(:tag, :recently_created, :with_pixelated_image)
```

## Testing Scenarios

### User with various tags
```ruby
user = create(:user, :veteran, :with_real_name)
create(:tag, :with_image_url, user: user)
create(:tag, :with_quote, user: user)
create(:tag, :with_markdown, user: user)
```

### Testing search/filtering
```ruby
# Create tags with different ages
create(:tag, :old, name: "old_tag")
create(:tag, :recently_created, name: "new_tag")
```

### Testing content display
```ruby
# Various content types for UI testing
create(:tag, :minimal_content)   # Tests short content
create(:tag, :long_content)       # Tests overflow/truncation
create(:tag, :with_image_url)     # Tests image rendering
create(:tag, :with_markdown)      # Tests markdown rendering
```

## Faker Features Used

- `Faker::Internet.username` - Random usernames
- `Faker::Internet.password` - Secure random passwords
- `Faker::Name.name` - Realistic full names
- `Faker::Avatar.image` - Avatar URLs
- `Faker::Lorem` - Lorem ipsum text in various lengths
- `Faker::Quote` - Famous quotes
- `Faker::ChuckNorris.fact` - Chuck Norris facts
- `Faker::Hipster` - Hipster lorem ipsum
- `Faker::LoremFlickr` - Dynamic placeholder images
- `Faker::Time.between` / `Faker::Time.backward` - Realistic timestamps
