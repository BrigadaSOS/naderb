import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "clearButton"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.debounceTimer = null
    this.frameLoadListener = this.updateURL.bind(this)
    this.renderListener = this.syncInputWithURL.bind(this)

    document.addEventListener("turbo:frame-load", this.frameLoadListener)
    document.addEventListener("turbo:render", this.renderListener)

    // Sync permanent input with URL on initial load
    this.syncInputWithURL()
  }

  syncInputWithURL() {
    const urlParams = new URLSearchParams(window.location.search)
    const searchParam = urlParams.get('search') || ''
    if (this.hasInputTarget && this.inputTarget.value !== searchParam) {
      this.inputTarget.value = searchParam
    }
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    document.removeEventListener("turbo:frame-load", this.frameLoadListener)
    document.removeEventListener("turbo:render", this.renderListener)
  }

  filter(event) {
    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Set up new debounced request
    this.debounceTimer = setTimeout(() => {
      // Add animating class to tags_list before submitting
      const tagsList = document.getElementById('tags_list')
      if (tagsList) {
        tagsList.classList.add('animating')
      }

      this.formTarget.requestSubmit()
      this.toggleClearButton()
    }, this.delayValue)
  }

  clear(event) {
    // Clear the input immediately for instant feedback
    this.inputTarget.value = ''
    // Let the link's turbo_action: "advance" handle navigation
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
