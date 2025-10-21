import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "banner"]
  static values = {
    confirmMessage: String
  }

  connect() {
    console.log("Profile form controller connected")

    // Store original form values
    this.originalValues = this.getFormValues()
    this.isDirty = false
    this.hideBanner()

    // Bind the beforeunload handler
    this.boundBeforeUnload = this.handleBeforeUnload.bind(this)
    window.addEventListener("beforeunload", this.boundBeforeUnload)
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.boundBeforeUnload)
  }

  // Get current form values as an object
  getFormValues() {
    const formData = new FormData(this.formTarget)
    const values = {}

    for (const [key, value] of formData.entries()) {
      values[key] = value
    }

    return values
  }

  // Called on any form change or input event
  checkDirty(event) {
    console.log("Form changed, checking dirty state")

    const currentValues = this.getFormValues()
    let hasChanges = false

    // Compare current values with original
    for (const key in currentValues) {
      if (currentValues[key] !== this.originalValues[key]) {
        console.log(`Change detected in ${key}: ${this.originalValues[key]} -> ${currentValues[key]}`)
        hasChanges = true
        break
      }
    }

    this.isDirty = hasChanges

    if (this.isDirty) {
      this.showBanner()
    } else {
      this.hideBanner()
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("hidden")
    }
  }

  discard(event) {
    event.preventDefault()

    // Reset form to original values
    const form = this.formTarget

    // Reset each field to its original value
    for (const key in this.originalValues) {
      const input = form.elements[key]
      if (input) {
        input.value = this.originalValues[key]
      }
    }

    this.isDirty = false
    this.hideBanner()
  }

  // Called when form is being submitted
  submit(event) {
    console.log("Form is being submitted, disabling beforeunload warning")
    // Mark as not dirty so beforeunload doesn't trigger
    this.isDirty = false
  }

  handleBeforeUnload(event) {
    if (this.isDirty) {
      // Modern browsers ignore custom message but still show dialog
      event.preventDefault()
      event.returnValue = this.confirmMessageValue || "You have unsaved changes. Are you sure you want to leave?"
      return event.returnValue
    }
  }
}
