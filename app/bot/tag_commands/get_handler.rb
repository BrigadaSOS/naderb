module TagCommands
  module GetHandler
    def self.command_schema
      {
        name: "get",
        description: "Obtiene un tag existente",
        parameters: {
          name: { name: "name", type: "string", required: true, description: "Nombre del tag" }
        }
      }
    end

    def self.included(base)
      base.define_subcommand(:tag, command_schema) do |event|
        event.defer(ephemeral: false)

        params = base.extract_params_from_event(command_schema, event)
        tag = base.find_tag_or_respond!(event, params[:name])
        next unless tag

        if tag.discord_cdn_url?
          send_tag_with_cdn_url(event, tag)
        elsif tag.image.attached?
          send_tag_with_image_upload(event, tag)
        else
          send_tag_text_only(event, tag)
        end
      end
    end

    def self.send_tag_with_cdn_url(event, tag)
      Rails.logger.info "Sending tag '#{tag.name}' with cached Discord CDN URL"

      response_text = [ tag.content, tag.discord_cdn_url ].join("\n")

      event.edit_response(content: response_text)
    end

    def self.send_tag_with_image_upload(event, tag)
      Rails.logger.info "Uploading image for tag '#{tag.name}'"

      file = File.open(ActiveStorage::Blob.service.path_for(tag.image.key))
      # TODO: Edge case. If the image doesn't have an image like format it will fail the attachment until the second time which uses the CDN. We have to check this case
      response = event.edit_response(
        content: tag.content,
        attachments: [ file ]
      )

      file.close
      cache_cdn_url_from_response(tag, response)
    end

    def self.send_tag_text_only(event, tag)
      Rails.logger.info "Sending tag '#{tag.name}' without image"
      event.edit_response(content: self.content)
    end

    def self.cache_cdn_url_from_response(tag, response)
      return unless response.attachments.any?

      discord_cdn_url = response.attachments.first.url
      Rails.logger.info "Discord CDN URL received: #{discord_cdn_url}"
      tag.update!(discord_cdn_url: discord_cdn_url)
    end
  end
end
