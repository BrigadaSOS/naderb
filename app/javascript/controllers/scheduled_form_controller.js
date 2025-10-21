import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "testResult",
    "testResultContent",
    "countdown",
    "countdownText",
    "channelSelect",
    "channelInfo",
    "selectedChannelId",
    "variablesCard",
    "variablesList",
    "objectProperties",
    "exampleTemplate",
    "exampleCode",
    "queryMetadata"
  ]

  connect() {
    this.loadChannels()
    this.updateCountdown()

    // Show variables card if a query is already selected (edit mode)
    const dataQuerySelect = document.getElementById('scheduled_message_data_query')
    if (dataQuerySelect && dataQuerySelect.value) {
      this.onDataQueryChange({ target: dataQuerySelect })
    }
  }

  async loadChannels() {
    try {
      const response = await fetch('/dashboard/server/scheduled/channels', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      const data = await response.json()

      if (data.success && data.channels) {
        // Get current channel ID if editing
        const currentChannelId = this.channelSelectTarget.dataset.currentValue || ''

        // Clear existing options
        this.channelSelectTarget.innerHTML = ''

        // Add default option
        const defaultOption = document.createElement('option')
        defaultOption.value = ''
        defaultOption.textContent = 'Select a channel...'
        this.channelSelectTarget.appendChild(defaultOption)

        // Add channel options
        data.channels.forEach(channel => {
          const option = document.createElement('option')
          option.value = channel.id
          option.textContent = `# ${channel.name}`
          if (channel.id === currentChannelId) {
            option.selected = true
          }
          this.channelSelectTarget.appendChild(option)
        })

        // Update channel info display
        this.updateChannelInfo()
        this.channelSelectTarget.addEventListener('change', () => this.updateChannelInfo())
      }
    } catch (error) {
      console.error('Error loading channels:', error)
      this.channelSelectTarget.innerHTML = '<option value="">Error loading channels</option>'
    }
  }

  updateChannelInfo() {
    const selectedChannel = this.channelSelectTarget.value
    if (selectedChannel) {
      this.selectedChannelIdTarget.textContent = selectedChannel
      this.channelInfoTarget.classList.remove('hidden')
    } else {
      this.channelInfoTarget.classList.add('hidden')
    }
  }


  async testSend(event) {
    event.preventDefault()

    // Get the form and create a temporary ScheduledMessage to send
    const formData = new FormData(this.element)

    // We need to save the message first if it's new, or use existing test_execute endpoint
    const messageId = this.element.action.match(/\/scheduled\/(\d+)/)?.[1]

    if (!messageId) {
      this.testResultContentTarget.textContent = 'Please save the message first before testing.'
      this.testResultContentTarget.className = 'w-full px-3 py-2 border border-red-200 rounded-md bg-red-50 text-red-700 font-mono text-sm whitespace-pre-wrap'
      this.testResultTarget.classList.remove('hidden')
      return
    }

    try {
      const response = await fetch(`/dashboard/server/scheduled/${messageId}/test_execute`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      const data = await response.json()

      if (data.success) {
        const message = data.skipped
          ? `Message skipped: ${data.message}`
          : 'Test message sent successfully! Check the Discord channel.'
        this.testResultContentTarget.textContent = message
        this.testResultContentTarget.className = 'w-full px-3 py-2 border border-green-200 rounded-md bg-green-50 text-green-700 font-mono text-sm whitespace-pre-wrap'
        this.testResultTarget.classList.remove('hidden')
      } else {
        this.testResultContentTarget.textContent = `Error: ${data.error}`
        this.testResultContentTarget.className = 'w-full px-3 py-2 border border-red-200 rounded-md bg-red-50 text-red-700 font-mono text-sm whitespace-pre-wrap'
        this.testResultTarget.classList.remove('hidden')
      }
    } catch (error) {
      this.testResultContentTarget.textContent = `Error: ${error.message}`
      this.testResultContentTarget.className = 'w-full px-3 py-2 border border-red-200 rounded-md bg-red-50 text-red-700 font-mono text-sm whitespace-pre-wrap'
      this.testResultTarget.classList.remove('hidden')
    }
  }

  updateCountdown() {
    const schedule = document.getElementById('scheduled_message_schedule')?.value
    const timezone = document.getElementById('scheduled_message_timezone')?.value

    if (!schedule || !timezone) {
      this.countdownTarget.classList.add('hidden')
      return
    }

    // Parse the schedule and calculate next execution time
    const nextTime = this.calculateNextExecution(schedule, timezone)

    if (nextTime) {
      const now = new Date()
      const diff = nextTime - now

      if (diff > 0) {
        const timeString = this.formatTimeDifference(diff)
        this.countdownTextTarget.textContent = timeString
        this.countdownTarget.classList.remove('hidden')
      } else {
        this.countdownTarget.classList.add('hidden')
      }
    } else {
      this.countdownTarget.classList.add('hidden')
    }
  }

  calculateNextExecution(schedule, timezone) {
    // This is a simplified parser - doesn't handle all cases perfectly
    const now = new Date()

    // Try to parse "every day at Xam/pm" or "at Xam/pm"
    const dailyMatch = schedule.match(/at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?/i)
    if (dailyMatch) {
      let hour = parseInt(dailyMatch[1])
      const minute = dailyMatch[2] ? parseInt(dailyMatch[2]) : 0
      const ampm = dailyMatch[3]?.toLowerCase()

      if (ampm === 'pm' && hour < 12) hour += 12
      if (ampm === 'am' && hour === 12) hour = 0

      const next = new Date(now)
      next.setHours(hour, minute, 0, 0)

      // If time already passed today, move to tomorrow
      if (next <= now) {
        next.setDate(next.getDate() + 1)
      }

      return next
    }

    // Try to parse "every X hours/minutes"
    const intervalMatch = schedule.match(/every (\d+) (hour|minute)s?/i)
    if (intervalMatch) {
      const amount = parseInt(intervalMatch[1])
      const unit = intervalMatch[2].toLowerCase()

      const next = new Date(now)
      if (unit === 'hour') {
        next.setHours(next.getHours() + amount)
      } else if (unit === 'minute') {
        next.setMinutes(next.getMinutes() + amount)
      }

      return next
    }

    return null
  }

  formatTimeDifference(milliseconds) {
    const seconds = Math.floor(milliseconds / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    const days = Math.floor(hours / 24)
    const months = Math.floor(days / 30)

    const parts = []
    if (months > 0) parts.push(`${months} month${months > 1 ? 's' : ''}`)
    if (days % 30 > 0) parts.push(`${days % 30} day${days % 30 > 1 ? 's' : ''}`)
    if (hours % 24 > 0) parts.push(`${hours % 24} hour${hours % 24 > 1 ? 's' : ''}`)
    if (minutes % 60 > 0) parts.push(`${minutes % 60} minute${minutes % 60 > 1 ? 's' : ''}`)

    return parts.length > 0 ? parts.join(', ') : 'less than a minute'
  }

  onDataQueryChange(event) {
    const queryType = event.target.value

    if (!queryType) {
      // Hide variables card when no query is selected
      if (this.hasVariablesCardTarget) {
        this.variablesCardTarget.classList.add('hidden')
      }
      return
    }

    // Find metadata for this query type
    const metadataElement = this.queryMetadataTargets.find(
      el => el.dataset.queryType === queryType
    )

    if (!metadataElement) {
      if (this.hasVariablesCardTarget) {
        this.variablesCardTarget.classList.add('hidden')
      }
      return
    }

    const metadata = JSON.parse(metadataElement.textContent)

    // Show the variables card
    if (this.hasVariablesCardTarget) {
      this.variablesCardTarget.classList.remove('hidden')
    }

    // Render variables list
    if (this.hasVariablesListTarget && metadata.variables) {
      this.variablesListTarget.innerHTML = metadata.variables.map(variable => `
        <div class="text-xs">
          <code class="text-accent font-semibold">${variable.name}</code>
          <span class="text-muted-foreground">: ${variable.type}</span>
          <p class="text-muted-foreground ml-4 mt-1">${variable.description}</p>
        </div>
      `).join('')
    }

    // Render object properties if any
    if (this.hasObjectPropertiesTarget) {
      if (metadata.object_properties && metadata.object_properties.length > 0) {
        this.objectPropertiesTarget.classList.remove('hidden')
        this.objectPropertiesTarget.innerHTML = metadata.object_properties.map(obj => `
          <div class="text-xs">
            <p class="font-semibold text-foreground mb-2">${obj.object} properties:</p>
            <div class="ml-4 space-y-1">
              ${obj.properties.map(prop => `
                <div>
                  <code class="text-accent">${prop.name}</code>
                  <span class="text-muted-foreground">: ${prop.type}</span>
                  <span class="text-muted-foreground">- ${prop.description}</span>
                </div>
              `).join('')}
            </div>
          </div>
        `).join('')
      } else {
        this.objectPropertiesTarget.classList.add('hidden')
      }
    }

    // Render example template if available
    if (this.hasExampleTemplateTarget && this.hasExampleCodeTarget) {
      if (metadata.example) {
        this.exampleTemplateTarget.classList.remove('hidden')
        this.exampleCodeTarget.textContent = metadata.example.trim()
      } else {
        this.exampleTemplateTarget.classList.add('hidden')
      }
    }
  }
}
