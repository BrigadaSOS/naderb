import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "submitButton", "deleteButton", "toggleButton"]
  static values = { readOnly: Boolean }

  connect() {
    this.updateMode()
  }

  toggle(event) {
    event.stopPropagation()
    this.readOnlyValue = !this.readOnlyValue
    this.updateMode()
  }

  toggleButtonTargetConnected() {
    this.updateMode()
  }

  updateMode() {

    this.fieldTargets.forEach(field => {
      field.disabled = this.readOnlyValue

      if (this.readOnlyValue) {
        field.classList.add("cursor-not-allowed", "opacity-60")
        field.classList.remove("focus:outline-none", "focus:ring-2", "focus:ring-blue-500")
      } else {
        field.classList.remove("cursor-not-allowed", "opacity-60")
        field.classList.add("focus:outline-none", "focus:ring-2", "focus:ring-blue-500")
      }
    })

    // Show/hide action buttons
    this.submitButtonTargets.forEach(button => {
      button.style.display = this.readOnlyValue ? "none" : "inline-block"
    })

    this.deleteButtonTargets.forEach(button => {
      button.style.display = this.readOnlyValue ? "none" : "inline-block"
    })

    // Update toggle button text
    this.toggleButtonTargets.forEach(button => {
      button.textContent = this.readOnlyValue ? "Edit" : "View"
      button.className = this.readOnlyValue
        ? "bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded text-sm transition-colors"
        : "bg-gray-600 hover:bg-gray-700 text-white px-3 py-1 rounded text-sm transition-colors"
    })
  }
}