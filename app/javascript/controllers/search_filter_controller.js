import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.debounceTimer = null
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  filter(event) {
    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Set up new debounced request
    this.debounceTimer = setTimeout(() => {
      this.submitForm()
    }, this.delayValue)
  }

  submitForm() {
    // Use requestSubmit() instead of submit() to ensure Turbo intercepts properly
    this.formTarget.requestSubmit()
  }
}