import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { type: String }

  connect() {
    // Get duration based on type
    const duration = this.getDuration()

    // Trigger slide-in animation by adding class after a tiny delay
    // This ensures the animation plays even for server-rendered toasts
    requestAnimationFrame(() => {
      this.element.classList.add("toast-slide-in")
    })

    // Auto-dismiss after duration
    this.timeoutId = setTimeout(() => {
      this.dismiss()
    }, duration)

    // Listen for animation end to remove the element after slide-out
    this.element.addEventListener("animationend", this.handleAnimationEnd.bind(this))
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

    // Remove slide-in and add slide-out animation
    this.element.classList.remove("toast-slide-in")
    this.element.classList.add("toast-slide-out")
  }

  handleAnimationEnd(event) {
    // Only remove when slide-out animation completes
    if (event.animationName === "toast-slide-out-right") {
      this.element.remove()
    }
  }

  getDuration() {
    const type = this.typeValue || "info"

    switch (type.toString()) {
      case "alert":
      case "error":
      case "danger":
        return 7000
      case "warning":
        return 6000
      default:
        return 5000
    }
  }
}
