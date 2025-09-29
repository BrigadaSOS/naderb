import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["results"]

  async inspect(event) {
    const button = event.currentTarget
    const tableName = button.dataset.tableName

    if (!tableName) {
      console.error("No table name provided")
      return
    }

    // Show loading state
    button.disabled = true
    button.textContent = "Loading..."

    try {
      const response = await fetch(`/dashboard/admin/data/1/inspect?table_name=${tableName}&page=1`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()
      this.displayTable(data)

    } catch (error) {
      console.error("Error fetching table data:", error)
      this.displayError(`Failed to load table data: ${error.message}`)
    } finally {
      // Reset button state
      button.disabled = false
      button.textContent = "Inspect"
    }
  }

  displayTable(data) {
    const resultsTarget = this.resultsTarget

    if (data.error) {
      this.displayError(data.error)
      return
    }

    // Build HTML for the table
    let html = `
      <div class="bg-gray-800 rounded-lg p-6 mt-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-xl font-semibold text-white">Table: ${data.table_name}</h3>
          <button class="text-sm text-gray-400 hover:text-white" data-action="click->table-inspect#closeTable">
            ✕ Close
          </button>
        </div>

        <div class="mb-4 text-sm text-gray-300">
          Showing ${data.records.length} of ${data.pagination.total_count} records
          (Page ${data.pagination.current_page} of ${data.pagination.total_pages})
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-gray-600">
                ${data.columns.map(col => `<th class="text-left py-2 px-3 text-gray-300 font-medium">${col}</th>`).join('')}
              </tr>
            </thead>
            <tbody>
              ${data.records.map(record => `
                <tr class="border-b border-gray-700 hover:bg-gray-700/50">
                  ${data.columns.map(col => `
                    <td class="py-2 px-3 text-gray-300">
                      <div class="max-w-xs truncate" title="${this.escapeHtml(record[col] || '')}">
                        ${this.escapeHtml(record[col] || '')}
                      </div>
                    </td>
                  `).join('')}
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>

        ${this.renderPagination(data)}
      </div>
    `

    resultsTarget.innerHTML = html
    resultsTarget.classList.remove("hidden")

    // Scroll to results
    resultsTarget.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  renderPagination(data) {
    if (data.pagination.total_pages <= 1) return ''

    const pagination = data.pagination
    let paginationHtml = '<div class="flex items-center justify-between mt-4">'

    // Previous button
    if (pagination.has_prev) {
      paginationHtml += `
        <button class="text-sm bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded"
                data-action="click->table-inspect#loadPage"
                data-page="${pagination.current_page - 1}"
                data-table-name="${data.table_name}">
          Previous
        </button>
      `
    } else {
      paginationHtml += '<div></div>'
    }

    // Page info
    paginationHtml += `
      <span class="text-sm text-gray-300">
        Page ${pagination.current_page} of ${pagination.total_pages}
      </span>
    `

    // Next button
    if (pagination.has_next) {
      paginationHtml += `
        <button class="text-sm bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded"
                data-action="click->table-inspect#loadPage"
                data-page="${pagination.current_page + 1}"
                data-table-name="${data.table_name}">
          Next
        </button>
      `
    } else {
      paginationHtml += '<div></div>'
    }

    paginationHtml += '</div>'
    return paginationHtml
  }

  async loadPage(event) {
    const button = event.currentTarget
    const page = button.dataset.page
    const tableName = button.dataset.tableName

    button.disabled = true
    button.textContent = "Loading..."

    try {
      const response = await fetch(`/dashboard/admin/data/1/inspect?table_name=${tableName}&page=${page}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()
      this.displayTable(data)

    } catch (error) {
      console.error("Error loading page:", error)
      this.displayError(`Failed to load page: ${error.message}`)
    }
  }

  closeTable() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
  }

  displayError(message) {
    const resultsTarget = this.resultsTarget
    resultsTarget.innerHTML = `
      <div class="bg-red-900/50 border border-red-700 rounded-lg p-4 mt-6">
        <div class="flex items-center justify-between">
          <div class="text-red-200">${message}</div>
          <button class="text-red-300 hover:text-red-100" data-action="click->table-inspect#closeTable">
            ✕ Close
          </button>
        </div>
      </div>
    `
    resultsTarget.classList.remove("hidden")
  }

  escapeHtml(text) {
    if (text === null || text === undefined) return ''
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
}