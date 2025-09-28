import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: Number, dismissible: Boolean }

  connect() {
    // Auto-dismiss if duration is set and dismissible is true
    if (this.dismissibleValue && this.durationValue > 0) {
      this.timeoutId = setTimeout(() => {
        this.dismiss()
      }, this.durationValue)
    }

    // Add animation for entry from bottom-right
    this.element.style.transform = "translateX(100%) translateY(20px)"
    this.element.style.opacity = "0"

    // Use requestAnimationFrame to ensure the initial styles are applied
    requestAnimationFrame(() => {
      this.element.style.transform = "translateX(0) translateY(0)"
      this.element.style.opacity = "1"
    })
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  dismiss() {
    // Clear timeout if it exists
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    // Animate out to bottom-right
    this.element.style.transform = "translateX(100%) translateY(20px)"
    this.element.style.opacity = "0"

    // Remove element after animation
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove()
      }
    }, 300) // Match the transition duration
  }

  // Allow manual dismissal even if dismissible is false (for programmatic control)
  forceDismiss() {
    this.dismiss()
  }

  // Pause auto-dismiss on hover
  pauseAutoDismiss() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.isPaused = true
    }
  }

  // Resume auto-dismiss when hover ends
  resumeAutoDismiss() {
    if (this.isPaused && this.dismissibleValue && this.durationValue > 0) {
      this.timeoutId = setTimeout(() => {
        this.dismiss()
      }, 2000) // Give 2 more seconds after hover ends
      this.isPaused = false
    }
  }
}