import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.frameLoadListener = this.handleFrameLoad.bind(this)
    this.submitEndListener = this.handleSubmitEnd.bind(this)
    this.popStateListener = this.handlePopState.bind(this)
    this.clickListener = this.handleClick.bind(this)

    document.addEventListener("turbo:frame-load", this.frameLoadListener)
    document.addEventListener("turbo:submit-end", this.submitEndListener)
    window.addEventListener("popstate", this.popStateListener)
    document.addEventListener("click", this.clickListener)

    this.turboFrame = document.getElementById('tag_form')
    this.lastClickTime = 0
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.frameLoadListener)
    document.removeEventListener("turbo:submit-end", this.submitEndListener)
    window.removeEventListener("popstate", this.popStateListener)
    document.removeEventListener("click", this.clickListener)
  }

  // Close modal - advance history by navigating frame to main page
  close(event) {
    // Prevent double-clicks
    const now = Date.now()
    if (now - this.lastClickTime < 500) {
      event?.preventDefault()
      return
    }
    this.lastClickTime = now

    if (this.turboFrame) {
      this.turboFrame.src = '/dashboard/tags'
    }
  }

  // Close on backdrop click
  closeOnBackdrop(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  // Show the modal
  showModal() {
    this.element.classList.remove("hidden")
    this.element.classList.add("flex")
  }

  // Hide the modal
  hideModal() {
    this.element.classList.add("hidden")
    this.element.classList.remove("flex")
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
    if (event.detail.success) {
      this.close()
    }
  }

  // Handle browser back/forward navigation
  handlePopState(event) {
    // Let Turbo handle all navigation
    // handleFrameLoad will manage modal visibility when frame content changes
  }

  // Handle clicks on links with turbo-frame data attribute
  handleClick(event) {
    const link = event.target.closest('a[data-turbo-frame]')
    if (link && link.dataset.turboFrame === 'tag_form') {
      this.turboFrame = document.getElementById('tag_form')
    }
  }

  // Helper method to clear frame content
  clearFrame() {
    if (this.turboFrame) {
      this.turboFrame.innerHTML = ''
      this.turboFrame.removeAttribute('src')
    }
  }
}