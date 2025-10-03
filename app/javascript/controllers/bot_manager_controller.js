import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["status", "startBtn", "stopBtn", "restartBtn", "forceStopBtn", "logs", "uptime", "errorMessage"]
  static values = {
    statusUrl: String,
    startUrl: String,
    stopUrl: String,
    restartUrl: String,
    forceStopUrl: String
  }

  connect() {
    console.log("Bot manager controller connected")
    this.consumer = createConsumer()
    this.uptimeSeconds = 0
    this.uptimeInterval = null
    this.updateStatus()
    this.subscribeToBot()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    this.stopUptimeTimer()
  }

  subscribeToBot() {
    this.subscription = this.consumer.subscriptions.create("BotChannel", {
      connected: () => {
        console.log("Connected to BotChannel")
        this.appendLog("Connected to bot updates stream", "info")
      },

      disconnected: () => {
        console.log("Disconnected from BotChannel")
      },

      received: (data) => {
        if (data.type === "log") {
          this.appendLog(data.message, data.level || "info")
        } else if (data.type === "status") {
          this.updateStatusDisplay(data.status)
          this.updateButtons(data.status.status)
          this.updateUptime(data.status.uptime)
          this.updateErrorMessage(data.status.error_message)
        }
      }
    })
  }

  appendLog(message, level = "info") {
    if (!this.hasLogsTarget) return

    const timestamp = new Date().toLocaleTimeString()
    const logEntry = document.createElement("div")
    logEntry.className = `py-1 ${this.getLogColorClass(level)}`
    logEntry.innerHTML = `<span class="text-gray-500">[${timestamp}]</span> ${this.escapeHtml(message)}`

    this.logsTarget.appendChild(logEntry)

    // Auto-scroll to bottom
    this.logsTarget.scrollTop = this.logsTarget.scrollHeight

    // Limit log entries to prevent memory issues
    const maxLogs = 500
    while (this.logsTarget.children.length > maxLogs) {
      this.logsTarget.removeChild(this.logsTarget.firstChild)
    }
  }

  getLogColorClass(level) {
    switch (level) {
      case "error":
        return "text-red-400"
      case "warn":
        return "text-yellow-400"
      case "info":
      default:
        return "text-gray-300"
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  async updateStatus() {
    try {
      const response = await fetch(this.statusUrlValue)
      const data = await response.json()

      this.updateStatusDisplay(data)
      this.updateButtons(data.status)
      this.updateUptime(data.uptime)
      this.updateErrorMessage(data.error_message)
    } catch (error) {
      console.error("Failed to update status:", error)
    }
  }

  updateStatusDisplay(data) {
    if (!this.hasStatusTarget) return

    const statusMap = {
      stopped: { text: "Stopped", color: "text-gray-400 bg-gray-400/20" },
      starting: { text: "Starting...", color: "text-yellow-400 bg-yellow-400/20" },
      running: { text: "Running", color: "text-green-400 bg-green-400/20" },
      error: { text: "Error", color: "text-red-400 bg-red-400/20" }
    }

    const statusInfo = statusMap[data.status] || statusMap.stopped
    this.statusTarget.textContent = statusInfo.text
    this.statusTarget.className = `px-2 py-1 rounded text-sm ${statusInfo.color}`
  }

  updateButtons(status) {
    const isRunningOrStarting = status === "running" || status === "starting"
    const isStopped = status === "stopped" || status === "error"
    const isStarting = status === "starting"
    const isStopping = status === "stopping"

    // Disable all buttons if we're in a transitional state
    const isTransitioning = isStarting || isStopping

    if (this.hasStartBtnTarget) {
      this.startBtnTarget.disabled = isRunningOrStarting || isTransitioning
      this.startBtnTarget.classList.toggle("opacity-50", isRunningOrStarting || isTransitioning)
      this.startBtnTarget.classList.toggle("cursor-not-allowed", isRunningOrStarting || isTransitioning)
    }

    if (this.hasStopBtnTarget) {
      this.stopBtnTarget.disabled = isStopped || isTransitioning
      this.stopBtnTarget.classList.toggle("opacity-50", isStopped || isTransitioning)
      this.stopBtnTarget.classList.toggle("cursor-not-allowed", isStopped || isTransitioning)
    }

    if (this.hasRestartBtnTarget) {
      this.restartBtnTarget.disabled = isTransitioning
      this.restartBtnTarget.classList.toggle("opacity-50", isTransitioning)
      this.restartBtnTarget.classList.toggle("cursor-not-allowed", isTransitioning)
    }

    if (this.hasForceStopBtnTarget) {
      this.forceStopBtnTarget.disabled = isStopped || isTransitioning
      this.forceStopBtnTarget.classList.toggle("opacity-50", isStopped || isTransitioning)
      this.forceStopBtnTarget.classList.toggle("cursor-not-allowed", isStopped || isTransitioning)
    }
  }

  updateUptime(uptime) {
    if (!this.hasUptimeTarget || !uptime) {
      if (this.hasUptimeTarget) {
        this.uptimeTarget.textContent = "N/A"
      }
      this.stopUptimeTimer()
      return
    }

    // Store the uptime value and start the timer
    this.uptimeSeconds = uptime
    this.displayUptime()
    this.startUptimeTimer()
  }

  displayUptime() {
    if (!this.hasUptimeTarget) return

    const hours = Math.floor(this.uptimeSeconds / 3600)
    const minutes = Math.floor((this.uptimeSeconds % 3600) / 60)
    const seconds = Math.floor(this.uptimeSeconds % 60)

    this.uptimeTarget.textContent = `${hours}h ${minutes}m ${seconds}s`
  }

  startUptimeTimer() {
    // Clear any existing interval
    this.stopUptimeTimer()

    // Increment uptime every second
    this.uptimeInterval = setInterval(() => {
      this.uptimeSeconds++
      this.displayUptime()
    }, 1000)
  }

  stopUptimeTimer() {
    if (this.uptimeInterval) {
      clearInterval(this.uptimeInterval)
      this.uptimeInterval = null
    }
  }

  updateErrorMessage(errorMessage) {
    if (!this.hasErrorMessageTarget) return

    if (errorMessage) {
      this.errorMessageTarget.textContent = errorMessage
      this.errorMessageTarget.classList.remove("hidden")
    } else {
      this.errorMessageTarget.classList.add("hidden")
    }
  }

  async start(event) {
    event.preventDefault()
    // Immediately disable buttons to prevent multiple clicks
    this.disableAllButtons()
    await this.sendCommand(this.startUrlValue, "Starting bot...")
  }

  async stop(event) {
    event.preventDefault()
    // Immediately disable buttons to prevent multiple clicks
    this.disableAllButtons()
    await this.sendCommand(this.stopUrlValue, "Stopping bot...")
  }

  async restart(event) {
    event.preventDefault()
    // Immediately disable buttons to prevent multiple clicks
    this.disableAllButtons()
    await this.sendCommand(this.restartUrlValue, "Restarting bot...")
  }

  async forceStop(event) {
    event.preventDefault()
    if (confirm("Force stop the bot? This should only be used if normal stop is not working.")) {
      await this.sendCommand(this.forceStopUrlValue, "Force stopping bot...")
    }
  }

  async sendCommand(url, loadingMessage) {
    try {
      this.appendLog(loadingMessage, "info")

      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      const data = await response.json()

      if (data.success) {
        this.appendLog(data.message, "info")
      } else {
        this.appendLog(`Error: ${data.message}`, "error")

        // If we get an error about bot not running/already running, refresh the status
        // This can happen after app restart when frontend state is stale
        if (data.message.includes("not running") || data.message.includes("already")) {
          this.appendLog("Refreshing bot status...", "info")
          await this.updateStatus()
        }
      }
    } catch (error) {
      this.appendLog(`Request failed: ${error.message}`, "error")
    }
  }

  disableAllButtons() {
    const buttons = [
      this.startBtnTarget,
      this.stopBtnTarget,
      this.restartBtnTarget,
      this.forceStopBtnTarget
    ]

    buttons.forEach(btn => {
      if (btn) {
        btn.disabled = true
        btn.classList.add("opacity-50", "cursor-not-allowed")
      }
    })
  }

  clearLogs() {
    if (this.hasLogsTarget) {
      this.logsTarget.innerHTML = ""
      this.appendLog("Logs cleared", "info")
    }
  }
}
