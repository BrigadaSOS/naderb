import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["adminSelect", "moderatorSelect", "trustedSelect"]

  connect() {
    this.loadRoles()
  }

  async loadRoles() {
    try {
      const response = await fetch('/dashboard/admin/config/fetch_discord_roles')
      const data = await response.json()

      if (data.error) {
        console.error('Error loading roles:', data.error)
        this.showError('Failed to load Discord roles')
        return
      }

      const roles = data.roles || []

      // Get current role configurations from the server
      const currentAdmin = this.getCurrentRoles('admin')
      const currentModerator = this.getCurrentRoles('moderator')
      const currentTrusted = this.getCurrentRoles('trusted')

      // Populate all three selects
      this.populateSelect(this.adminSelectTarget, roles, currentAdmin)
      this.populateSelect(this.moderatorSelectTarget, roles, currentModerator)
      this.populateSelect(this.trustedSelectTarget, roles, currentTrusted)
    } catch (error) {
      console.error('Error fetching roles:', error)
      this.showError('Failed to load Discord roles')
    }
  }

  populateSelect(selectElement, roles, selectedIds) {
    // Clear existing options
    selectElement.innerHTML = ''

    // Add roles as options
    roles.forEach(role => {
      const option = document.createElement('option')
      option.value = role.id
      option.textContent = role.name

      // Pre-select if role is in current configuration
      if (selectedIds.includes(role.id)) {
        option.selected = true
      }

      // Add color indicator if role has a color
      if (role.color && role.color !== 0) {
        const colorHex = '#' + role.color.toString(16).padStart(6, '0')
        option.style.color = colorHex
      }

      selectElement.appendChild(option)
    })

    // If no roles loaded, show message
    if (roles.length === 0) {
      const option = document.createElement('option')
      option.textContent = 'No roles available'
      option.disabled = true
      selectElement.appendChild(option)
    }
  }

  getCurrentRoles(type) {
    // Try to get current roles from a data attribute if passed from server
    const dataAttr = this.element.dataset[`current${type.charAt(0).toUpperCase() + type.slice(1)}Roles`]
    if (dataAttr) {
      try {
        return JSON.parse(dataAttr)
      } catch (e) {
        return []
      }
    }
    return []
  }

  showError(message) {
    // You can implement a toast notification here
    alert(message)
  }
}
