import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    // Wait for EasyMDE to be available, then initialize
    this.waitForEasyMDE()
  }

  disconnect() {
    if (this.easyMDE) {
      this.easyMDE.toTextArea()
      this.easyMDE = null
    }
    if (this.syncInterval) {
      clearInterval(this.syncInterval)
    }
    if (this.waitInterval) {
      clearInterval(this.waitInterval)
    }
  }

  waitForEasyMDE() {
    console.log('Waiting for EasyMDE...', 'window.EasyMDE:', typeof window.EasyMDE)
    
    // Check if EasyMDE is already available
    if (window.EasyMDE) {
      console.log('EasyMDE found immediately, initializing...')
      this.initializeEasyMDE()
      return
    }

    // Wait for EasyMDE to load with a timeout
    let attempts = 0
    const maxAttempts = 30 // 3 seconds maximum wait time
    
    this.waitInterval = setInterval(() => {
      attempts++
      
      if (window.EasyMDE) {
        console.log('EasyMDE found after waiting, initializing...')
        clearInterval(this.waitInterval)
        this.initializeEasyMDE()
      } else if (attempts >= maxAttempts) {
        clearInterval(this.waitInterval)
        console.warn('EasyMDE not available after timeout, falling back to regular textarea')
        console.log('All window properties:', Object.keys(window).slice(0, 20), '... (truncated)')
      }
    }, 100) // Check every 100ms
  }

  initializeEasyMDE() {
    try {
      // Use EasyMDE loaded globally via script tag
      const EasyMDE = window.EasyMDE
      
      const options = {
        element: this.textareaTarget,
        placeholder: "Detailed description of the episode content...",
        spellChecker: false,
        toolbar: [
          "bold", "italic", "heading", "|",
          "quote", "unordered-list", "ordered-list", "|",
          "link", "image", "|",
          "preview", "side-by-side", "fullscreen", "|",
          "guide"
        ],
        status: ["autosave", "lines", "words", "cursor"],
        autosave: {
          enabled: false
        },
        hideIcons: ["guide"],
        showIcons: ["code", "table"],
        styleSelectedText: false,
        tabSize: 2,
        minHeight: "200px",
        maxHeight: "400px"
      }

      if (!EasyMDE) {
        console.warn('EasyMDE not available, falling back to regular textarea')
        return
      }

      this.easyMDE = new EasyMDE(options)
    } catch (error) {
      console.error('Failed to load EasyMDE:', error)
      // Fallback to regular textarea if EasyMDE fails to load
      return
    }

    // Ensure the textarea value is synced when the form is submitted
    this.element.closest('form')?.addEventListener('submit', () => {
      if (this.easyMDE) {
        this.textareaTarget.value = this.easyMDE.value()
      }
    })

    // Auto-sync content periodically
    this.syncInterval = setInterval(() => {
      if (this.easyMDE) {
        this.textareaTarget.value = this.easyMDE.value()
      }
    }, 1000)
  }

  // Method to get current content
  getValue() {
    return this.easyMDE ? this.easyMDE.value() : this.textareaTarget.value
  }

  // Method to set content
  setValue(value) {
    if (this.easyMDE) {
      this.easyMDE.value(value)
    } else {
      this.textareaTarget.value = value
    }
  }
}
