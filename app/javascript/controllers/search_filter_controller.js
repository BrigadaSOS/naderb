import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "clearButton"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.debounceTimer = null
    this.frameLoadListener = this.updateURL.bind(this)
    document.addEventListener("turbo:frame-load", this.frameLoadListener)
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    document.removeEventListener("turbo:frame-load", this.frameLoadListener)
  }

  filter(event) {
    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Set up new debounced request
    this.debounceTimer = setTimeout(() => {
      this.formTarget.requestSubmit()
      this.toggleClearButton()
    }, this.delayValue)
  }

  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ''

    // Navigate to clean URL via turbo frame
    const frame = document.getElementById('tags_container')
    if (frame) {
      frame.src = this.formTarget.action
    }

    // Update URL immediately
    window.history.pushState({}, '', this.formTarget.action)

    // Hide clear button
    this.toggleClearButton()
  }

  updateURL(event) {
    // Update URL when the tags_container frame loads
    if (event.target.id === "tags_container") {
      const url = new URL(this.formTarget.action)
      const searchValue = this.inputTarget.value.trim()

      if (searchValue) {
        url.searchParams.set('search', searchValue)
      } else {
        url.searchParams.delete('search')
      }

      window.history.pushState({}, '', url.toString())
    }
  }

  toggleClearButton() {
    if (this.hasClearButtonTarget) {
      const hasValue = this.inputTarget.value.trim().length > 0
      this.clearButtonTarget.style.display = hasValue ? '' : 'none'
    }
  }
}
