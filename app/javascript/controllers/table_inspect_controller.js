import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    // Clear the turbo frame to hide the results
    const frame = document.getElementById("table-inspection-results")
    if (frame) {
      frame.innerHTML = ""
    }
  }
}