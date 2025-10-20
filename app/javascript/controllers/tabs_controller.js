import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel", "modeInput", "imageInput", "imagePreview", "removeImageInput", "newImagePreview"]

  connect() {
    // If tag has an attached image, start in image tab with content disabled
    if (this.hasImagePreviewTarget) {
      this.switchToTab("image")
      this.disableContentTab()
    } else {
      this.switchToTab("content")
    }
  }

  switch(event) {
    const tab = event.currentTarget

    // Don't switch if tab is disabled
    if (tab.disabled || tab.classList.contains("opacity-50")) return

    this.switchToTab(tab.dataset.tabId)
  }

  switchToTab(tabId) {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tabId === tabId) {
        tab.classList.remove("border-transparent", "text-muted-foreground")
        tab.classList.add("border-primary", "text-primary")
      } else {
        tab.classList.remove("border-primary", "text-primary")
        tab.classList.add("border-transparent", "text-muted-foreground")
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tabId === tabId) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })

    // Update hidden input mode field
    if (this.hasModeInputTarget) {
      this.modeInputTarget.value = tabId
    }
  }

  handleImageChange(event) {
    const fileInput = event.target

    if (fileInput.files?.length > 0) {
      // Hide old persisted image preview when uploading new image
      this.imagePreviewTarget?.remove()

      this.disableContentTab()
      this.showImagePreview(fileInput.files[0])
    } else {
      this.hideImagePreview()
      this.enableContentTab()
    }
  }

  showImagePreview(file) {
    let previewContainer = this.element.querySelector('[data-tabs-target="newImagePreview"]')

    if (!previewContainer) {
      const imagePanel = this.panelTargets.find(panel => panel.dataset.tabId === "image")
      if (!imagePanel) return

      previewContainer = document.createElement('div')
      previewContainer.setAttribute('data-tabs-target', 'newImagePreview')
      previewContainer.className = 'mt-3'
      imagePanel.appendChild(previewContainer)
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      const removeButtonText = this.element.dataset.removeImageText || 'Remove Image'

      previewContainer.innerHTML = `
        <div class="flex justify-center">
          <img src="${e.target.result}" alt="Preview" class="max-w-full max-h-64 object-contain rounded border border-border">
        </div>
        <div class="mt-2 flex justify-center">
          <button
            type="button"
            data-action="click->tabs#clearFileInput"
            class="bg-destructive hover:bg-destructive/90 text-destructive-foreground px-3 py-1 rounded text-sm transition-colors"
          >
            ${removeButtonText}
          </button>
        </div>
      `
    }
    reader.readAsDataURL(file)
  }

  hideImagePreview() {
    this.element.querySelector('[data-tabs-target="newImagePreview"]')?.remove()
  }

  clearFileInput() {
    if (!this.hasImageInputTarget) return

    this.imageInputTarget.value = ""
    this.imageInputTarget.dispatchEvent(new Event('change'))
  }

  removeImage() {
    if (!this.hasRemoveImageInputTarget) return

    this.removeImageInputTarget.value = "true"
    this.imagePreviewTarget?.remove()

    if (this.hasImageInputTarget) {
      this.imageInputTarget.value = ""
    }

    this.enableContentTab()
    this.switchToTab("content")
  }

  disableContentTab() {
    this.#toggleContentTab(true)
  }

  enableContentTab() {
    this.#toggleContentTab(false)
  }

  #toggleContentTab(disabled) {
    const contentTab = this.tabTargets.find(tab => tab.dataset.tabId === "content")
    if (!contentTab) return

    contentTab.classList.toggle("opacity-50", disabled)
    contentTab.classList.toggle("cursor-not-allowed", disabled)
    contentTab.disabled = disabled
  }
}
