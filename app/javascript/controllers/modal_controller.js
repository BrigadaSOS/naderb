import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    closeUrl: String
  }

  connect() {
    // Don't call showModal() - let CSS handle the display
    // The checkbox + peer-checked handles visibility
  }

  close(event) {
    event?.preventDefault()
    this.performClose()
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) {
      this.performClose()
    }
  }

  performClose() {
    // Uncheck the checkbox to trigger disappear animation
    const checkbox = document.getElementById('modal-toggle')
    if (checkbox) {
      checkbox.checked = false
    }

    // Wait for animation to complete before navigating
    if (this.hasCloseUrlValue) {
      setTimeout(() => {
        Turbo.visit(this.closeUrlValue, { action: "advance" })
      }, 300) // Match animation duration
    }
  }
}
