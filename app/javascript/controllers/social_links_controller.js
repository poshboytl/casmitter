import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "hiddenField"]

  connect() {
    console.log('Social links controller connected')
    console.log('Element:', this.element)
    console.log('Has container target:', this.hasContainerTarget)
    console.log('Has template target:', this.hasTemplateTarget)
    console.log('Has hidden field target:', this.hasHiddenFieldTarget)
    
    if (!this.hasContainerTarget) {
      console.error('Container target not found!')
      return
    }
    
    if (!this.hasTemplateTarget) {
      console.error('Template target not found!')
      return
    }
    
    if (!this.hasHiddenFieldTarget) {
      console.error('Hidden field target not found!')
      return
    }
    
    // Initialize with existing data if any
    this.initializeExistingLinks()
    
    // Add form submit listener
    this.setupFormSubmitListener()
  }

  disconnect() {
    this.removeFormSubmitListener()
  }

  setupFormSubmitListener() {
    const form = this.element.closest('form')
    if (form) {
      this.formSubmitHandler = this.updateHiddenField.bind(this)
      form.addEventListener('submit', this.formSubmitHandler)
    }
  }

  removeFormSubmitListener() {
    const form = this.element.closest('form')
    if (form && this.formSubmitHandler) {
      form.removeEventListener('submit', this.formSubmitHandler)
    }
  }

  initializeExistingLinks() {
    console.log('Initializing existing links...')
    console.log('Container target:', this.containerTarget)
    console.log('Template target:', this.templateTarget)
    
    // Check if there's existing social_links data from the server
    const existingData = this.element.dataset.existingLinks
    console.log('Existing data from server:', existingData)
    
    if (existingData && existingData !== '{}') {
      try {
        const links = JSON.parse(existingData)
        console.log('Parsed existing links:', links)
        Object.entries(links).forEach(([platform, url]) => {
          console.log('Adding existing link:', platform, url)
          this.addLinkField(platform, url)
        })
      } catch (error) {
        console.error('Failed to parse existing social links:', error)
      }
    }
    
    // If no existing links, add one empty field
    if (this.containerTarget.children.length === 0) {
      console.log('No existing fields, adding empty field')
      this.addLinkField()
    }
    
    console.log('Initialization complete. Container children:', this.containerTarget.children.length)
  }

  addLink() {
    this.addLinkField()
  }

  addLinkField(platform = '', url = '') {
    const template = this.templateTarget.content.cloneNode(true)
    const linkDiv = template.querySelector('.social-link-item')
    
    // Set unique IDs and values
    const timestamp = Date.now()
    const platformInput = linkDiv.querySelector('.platform-input')
    const urlInput = linkDiv.querySelector('.url-input')
    
    platformInput.id = `social_link_platform_${timestamp}`
    urlInput.id = `social_link_url_${timestamp}`
    
    platformInput.value = platform
    urlInput.value = url
    
    // Add input event listeners to update hidden field on change
    platformInput.addEventListener('input', this.updateHiddenField.bind(this))
    urlInput.addEventListener('input', this.updateHiddenField.bind(this))
    
    this.containerTarget.appendChild(template)
    
    // Update hidden field after adding new field
    this.updateHiddenField()
  }

  removeLink(event) {
    const linkItem = event.target.closest('.social-link-item')
    if (linkItem) {
      linkItem.remove()
      
      // Ensure at least one field remains
      if (this.containerTarget.children.length === 0) {
        this.addLinkField()
      }
      
      // Update hidden field after removing field
      this.updateHiddenField()
    }
  }

  // Method to collect all social links data before form submission
  collectSocialLinksData() {
    const socialLinks = {}
    const linkItems = this.containerTarget.querySelectorAll('.social-link-item')
    
    console.log('Collecting social links data...')
    console.log('Found link items:', linkItems.length)
    
    linkItems.forEach((item, index) => {
      const platformInput = item.querySelector('.platform-input')
      const urlInput = item.querySelector('.url-input')
      
      console.log(`Item ${index}:`, {
        platformInput: platformInput,
        urlInput: urlInput,
        platformValue: platformInput?.value,
        urlValue: urlInput?.value
      })
      
      if (platformInput && urlInput) {
        const platform = platformInput.value.trim()
        const url = urlInput.value.trim()
        
        console.log(`Processing item ${index}: platform="${platform}", url="${url}"`)
        
        if (platform && url) {
          socialLinks[platform] = url
          console.log(`Added to socialLinks: ${platform} -> ${url}`)
        }
      }
    })
    
    console.log('Final socialLinks object:', socialLinks)
    return socialLinks
  }

  // Called before form submission to populate hidden field
  updateHiddenField() {
    const socialLinksData = this.collectSocialLinksData()
    
    console.log('Updating hidden field with data:', socialLinksData)
    console.log('Hidden field target:', this.hiddenFieldTarget)
    
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = JSON.stringify(socialLinksData)
      console.log('Hidden field updated:', this.hiddenFieldTarget.value)
      console.log('Hidden field name:', this.hiddenFieldTarget.name)
    } else {
      console.error('Hidden field target not found!')
    }
  }

  // Debug method - call this manually from console to test
  debug() {
    console.log('=== DEBUG INFO ===')
    console.log('Controller element:', this.element)
    console.log('Container target:', this.containerTarget)
    console.log('Template target:', this.templateTarget)
    console.log('Container children count:', this.containerTarget?.children?.length)
    console.log('Existing data:', this.element.dataset.existingLinks)
    
    // Try to collect current data
    const currentData = this.collectSocialLinksData()
    console.log('Current collected data:', currentData)
    
    // Check hidden field target
    console.log('Hidden field target:', this.hiddenFieldTarget)
    console.log('Has hidden field target:', this.hasHiddenFieldTarget)
    
    if (this.hasHiddenFieldTarget) {
      console.log('Hidden field current value:', this.hiddenFieldTarget.value)
      console.log('Hidden field name:', this.hiddenFieldTarget.name)
    }
    
    console.log('=== END DEBUG ===')
  }
}
