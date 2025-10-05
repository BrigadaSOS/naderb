import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.frameLoadListener = this.handleFrameLoad.bind(this)
    this.submitEndListener = this.handleSubmitEnd.bind(this)
    this.clickListener = this.handleClick.bind(this)
    this.cancelListener = this.handleCancel.bind(this)

    document.addEventListener("turbo:frame-load", this.frameLoadListener)
    document.addEventListener("turbo:submit-end", this.submitEndListener)
    document.addEventListener("click", this.clickListener)
    document.addEventListener("cancel", this.cancelListener)

    this.turboFrame = document.getElementById('tag_form')
    // Open modal on page load if content is pre-loaded
    if (this.element.dataset.modalOpenOnLoad === "true") {
      const hasFormContent = this.turboFrame?.querySelector('form')
      if (hasFormContent) {
        this.showModal()
      }
    }
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.frameLoadListener)
    document.removeEventListener("turbo:submit-end", this.submitEndListener)
    document.removeEventListener("click", this.clickListener)
    document.removeEventListener("cancel", this.cancelListener)
  }

  close() {
    this.turboFrame.src = '/dashboard/server/tags'
  }

  // Close on backdrop click
  closeOnBackdrop(event) {
    // Check if click was directly on the dialog element (backdrop area)
    if (event.target === this.element) {
      this.close()
    }
  }

  // Show the modal
  showModal() {
    this.element.showModal()
  }

  // Hide the modal
  hideModal() {
    this.element.close()
  }

  // Handle Turbo frame load events
  handleFrameLoad(event) {
    if (event.target.id === "tag_form") {
      const hasFormContent = event.target.querySelector('form')

      if (hasFormContent) {
        this.showModal()
      } else {
        this.hideModal()
      }
    }
  }

  // Handle successful form submissions
  handleSubmitEnd(event) {
    if (event.detail.success && this.element.contains(event.target)) {
      this.close()
    }
  }

  // Handle clicks on links with turbo-frame data attribute
  handleClick(event) {
    const link = event.target.closest('a[data-turbo-frame]')
    if (link && link.dataset.turboFrame === 'tag_form') {
      this.turboFrame = document.getElementById('tag_form')
    }
  }

  // Handle ESC key press (cancel event)
  handleCancel(event) {
    event.preventDefault()
    this.close()
  }

  // Helper method to clear frame content
  clearFrame() {
    if (this.turboFrame) {
      this.turboFrame.innerHTML = ''
      this.turboFrame.removeAttribute('src')
    }
  }
}
