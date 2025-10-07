import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "preview", "previewImage"]

  connect() {
    this.updatePreview()
    // Listen for image load errors
    this.previewImageTarget.addEventListener('error', () => {
      this.previewTarget.classList.add("hidden")
      this.previewTarget.classList.remove("flex", "justify-center")
    })
  }

  updatePreview() {
    const content = this.contentTarget.value.trim()

    if (this.isImageUrl(content)) {
      // Try to load the image
      this.previewImageTarget.src = content
      this.previewTarget.classList.remove("hidden")
      this.previewTarget.classList.add("flex", "justify-center")
    } else {
      this.previewTarget.classList.add("hidden")
      this.previewTarget.classList.remove("flex", "justify-center")
    }
  }

  isImageUrl(url) {
    if (!url) return false

    try {
      const uri = new URL(url)
      // Check if it's http or https
      if (!['http:', 'https:'].includes(uri.protocol)) return false

      // More lenient: check for image extensions OR assume it could be an image
      // This handles dynamic image services like picsum.photos, imgur, etc.
      const hasImageExtension = /\.(jpe?g|png|gif|webp|bmp|svg)$/i.test(uri.pathname)

      // If it has an extension, it must be an image extension
      const hasExtension = /\.[a-z0-9]+$/i.test(uri.pathname)
      if (hasExtension && !hasImageExtension) return false

      // Otherwise, try to display it as an image (no extension or has image extension)
      return true
    } catch {
      return false
    }
  }
}
