import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.frameLoadListener = this.handleFrameLoad.bind(this)
    this.submitEndListener = this.handleSubmitEnd.bind(this)
    this.popStateListener = this.handlePopState.bind(this)

    document.addEventListener("turbo:frame-load", this.frameLoadListener)
    document.addEventListener("turbo:submit-end", this.submitEndListener)
    window.addEventListener("popstate", this.popStateListener)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.frameLoadListener)
    document.removeEventListener("turbo:submit-end", this.submitEndListener)
    window.removeEventListener("popstate", this.popStateListener)
  }

  // Close on backdrop click - navigate to index (let Rails handle the rest)
  closeOnBackdrop(event) {
    if (event.target === this.element) {
      Turbo.visit('/dashboard/tags')
    }
  }

  // Handle Turbo frame load events - show modal and update URL
  handleFrameLoad(event) {
    if (event.target.id === "tag_form") {
      const frameContent = event.target.innerHTML.trim()

      if (frameContent) {
        // Update URL to match the loaded content
        const frameUrl = event.target.getAttribute('src')
        if (frameUrl && window.location.pathname !== frameUrl) {
          window.history.pushState({}, '', frameUrl)
        }

        this.element.classList.remove("hidden")
        this.element.classList.add("flex")
      } else {
        this.element.classList.add("hidden")
        this.element.classList.remove("flex")
      }
    }
  }

  // Handle successful form submissions - navigate back to index
  handleSubmitEnd(event) {
    if (event.detail.success) {
      Turbo.visit('/dashboard/tags')
    }
  }

  // Handle browser back/forward navigation
  handlePopState(event) {
    if (window.location.pathname === '/dashboard/tags') {
      // User navigated back to index - just hide the modal
      this.element.classList.add("hidden")
      this.element.classList.remove("flex")

      // Clear the frame content
      const turboFrame = document.getElementById('tag_form')
      if (turboFrame) {
        turboFrame.innerHTML = ''
        turboFrame.removeAttribute('src')
      }
    }
  }
}