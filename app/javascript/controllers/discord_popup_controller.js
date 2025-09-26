import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  show() {
    this.element.classList.remove("hidden")
    this.element.classList.add("flex")
  }

  hide() {
    this.element.classList.remove("flex")
    this.element.classList.add("hidden")
  }

  close(event) {
    if (event.target === this.overlayTarget) {
      this.hide()
    }
  }

  joinDiscord() {
    const discordUrl = this.element.dataset.discordUrl
    if (discordUrl) {
      window.open(discordUrl, '_blank')
    }
  }
}