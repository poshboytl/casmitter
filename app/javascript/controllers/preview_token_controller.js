import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "input"]
  static values = { previewToken: String }

  connect() {
    this.setupStatusChangeListener()
  }

  disconnect() {
    this.removeStatusChangeListener()
  }

  setupStatusChangeListener() {
    // Listen for status select changes
    const statusSelect = document.querySelector('select[name="episode[status]"]')
    if (statusSelect) {
      this.statusSelect = statusSelect
      this.statusSelect.addEventListener('change', this.handleStatusChange.bind(this))
    }
  }

  removeStatusChangeListener() {
    if (this.statusSelect) {
      this.statusSelect.removeEventListener('change', this.handleStatusChange.bind(this))
    }
  }

  handleStatusChange(event) {
    const isPreview = event.target.value === 'preview'
    this.togglePreviewSection(isPreview)
  }

  togglePreviewSection(show) {
    const section = document.querySelector('.preview-token-section')
    if (section) {
      if (show) {
        section.classList.remove('hidden')
      } else {
        section.classList.add('hidden')
      }
    }
  }

  copyToken(event) {
    event.preventDefault()
    
    let urlToCopy = ''
    
    // Get URL from different sources based on context
    if (this.hasPreviewTokenValue && this.previewTokenValue) {
      // From index page (token passed as value) - build full URL
      const baseUrl = window.location.origin
      urlToCopy = `${baseUrl}/episodes/${this.previewTokenValue}`
    } else if (this.hasInputTarget) {
      // From form page (URL from input field)
      urlToCopy = this.inputTarget.value
    } else {
      // Fallback: try to get token from the button's data attribute
      const token = this.element.getAttribute('data-preview-token-value')
      if (token) {
        const baseUrl = window.location.origin
        urlToCopy = `${baseUrl}/episodes/${token}`
      } else {
        // Last resort: try to find any preview URL input
        const urlInput = document.querySelector('input[data-preview-token-target="input"]')
        if (urlInput) {
          urlToCopy = urlInput.value
        }
      }
    }

    if (!urlToCopy) {
      this.showCopyMessage('No preview URL available', 'error')
      return
    }

    // Copy to clipboard
    this.copyToClipboard(urlToCopy)
  }

  async copyToClipboard(text) {
    try {
      if (navigator.clipboard && window.isSecureContext) {
        // Use modern clipboard API
        await navigator.clipboard.writeText(text)
        this.showCopyMessage('Preview URL copied to clipboard!', 'success')
      } else {
        // Fallback for older browsers
        const textArea = document.createElement('textarea')
        textArea.value = text
        textArea.style.position = 'fixed'
        textArea.style.left = '-999999px'
        textArea.style.top = '-999999px'
        document.body.appendChild(textArea)
        textArea.focus()
        textArea.select()
        
        try {
          document.execCommand('copy')
          this.showCopyMessage('Preview URL copied to clipboard!', 'success')
        } catch (err) {
          console.error('Fallback copy failed:', err)
          this.showCopyMessage('Failed to copy URL', 'error')
        } finally {
          document.body.removeChild(textArea)
        }
      }
    } catch (err) {
      console.error('Copy failed:', err)
      this.showCopyMessage('Failed to copy URL', 'error')
    }
  }

  showCopyMessage(message, type = 'success') {
    // Create or update message element
    let messageEl = document.getElementById('copy-message')
    if (!messageEl) {
      messageEl = document.createElement('div')
      messageEl.id = 'copy-message'
      messageEl.className = 'fixed top-4 right-4 px-4 py-2 rounded-md text-sm font-medium z-50 transition-all duration-300'
      document.body.appendChild(messageEl)
    }

    // Set message content and styling
    messageEl.textContent = message
    messageEl.className = `fixed top-4 right-4 px-4 py-2 rounded-md text-sm font-medium z-50 transition-all duration-300 ${
      type === 'success' 
        ? 'bg-green-100 text-green-800 border border-green-200' 
        : 'bg-red-100 text-red-800 border border-red-200'
    }`

    // Show message
    messageEl.classList.remove('opacity-0', 'transform', 'translate-y-2')
    messageEl.classList.add('opacity-100')

    // Hide message after 3 seconds
    setTimeout(() => {
      messageEl.classList.add('opacity-0', 'transform', 'translate-y-2')
      setTimeout(() => {
        if (messageEl.parentNode) {
          messageEl.parentNode.removeChild(messageEl)
        }
      }, 300)
    }, 3000)
  }
}
