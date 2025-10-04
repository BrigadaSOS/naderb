# frozen_string_literal: true

require "uuid_v7"

UuidV7.configure do |config|
  # config.field_name = :id # default :id
  config.implicit_inclusion_strategy = false # Disable automatic inclusion to avoid conflicts with Devise
  # config.throw_invalid_uuid = false # default false
end
