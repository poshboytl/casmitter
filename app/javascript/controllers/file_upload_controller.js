import { Controller } from "@hotwired/stimulus"
import { Howl } from 'howler'

export default class extends Controller {
  static targets = [
    "dropZone", 
    "default", 
    "dragOver", 
    "uploading", 
    "success", 
    "error",
    "progressBar",
    "status",
    "fileInfo",
    "errorMessage",
    "fileInput",
    "ready",
    "uploadButton",
    "readyInfo"
  ]

  static values = {
    uploadUrl: String,
    maxFileSize: { type: Number, default: 100 * 1024 * 1024 }, // 100MB
    allowedTypes: { type: Array, default: ['audio/mpeg', 'audio/wav', 'audio/m4a', 'audio/aac'] }
  }

  connect() {
    console.log('FileUpload controller connected')
    console.log('Targets found:', {
      default: this.hasDefaultTarget,
      error: this.hasErrorTarget,
      uploading: this.hasUploadingTarget,
      success: this.hasSuccessTarget,
      dragOver: this.hasDragOverTarget
    })
    
    this.setupEventListeners()
    this.currentFile = null
    
    // Ensure default state is shown initially
    this.hideAllStates()
    this.defaultTarget.classList.remove('hidden')
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.classList.add('hidden')
    }
    
    console.log('Initial state set to default')
    console.log('Default target hidden class:', this.defaultTarget.classList.contains('hidden'))
    console.log('Error target hidden class:', this.errorTarget.classList.contains('hidden'))
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    this.dropZoneTarget.addEventListener('dragover', this.handleDragOver.bind(this))
    this.dropZoneTarget.addEventListener('dragleave', this.handleDragLeave.bind(this))
    this.dropZoneTarget.addEventListener('drop', this.handleDrop.bind(this))
    
    // Add change event listener for file input
    if (this.hasFileInputTarget) {
      this.fileInputTarget.addEventListener('change', this.handleFileInput.bind(this))
    }

    // Upload button click
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.addEventListener('click', this.uploadCurrentFile.bind(this))
    }
  }

  removeEventListeners() {
    this.dropZoneTarget.removeEventListener('dragover', this.handleDragOver.bind(this))
    this.dropZoneTarget.removeEventListener('dragleave', this.handleDragLeave.bind(this))
    this.dropZoneTarget.removeEventListener('drop', this.handleDrop.bind(this))
    
    // Remove change event listener for file input
    if (this.hasFileInputTarget) {
      this.fileInputTarget.removeEventListener('change', this.handleFileInput.bind(this))
    }

    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.removeEventListener('click', this.uploadCurrentFile.bind(this))
    }
  }

  handleDragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    this.showDragOverState()
  }

  handleDragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    // Only hide drag over state if we're actually leaving the drop zone
    if (!this.dropZoneTarget.contains(event.relatedTarget)) {
      this.hideDragOverState()
    }
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.hideDragOverState()
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.handleFile(files[0])
    }
  }



  handleFileInput(event) {
    const file = event.target.files[0]
    if (file) {
      this.handleFile(file)
    }
  }

  handleFile(file) {
    // Validate file
    if (!this.validateFile(file)) {
      return
    }

    this.currentFile = file
    this.showReadyState(file)
  }

  validateFile(file) {
    // Check file size
    if (file.size > this.maxFileSizeValue) {
      this.showError(`File size cannot exceed ${this.formatFileSize(this.maxFileSizeValue)}`)
      return false
    }

    // Check file type
    if (!this.allowedTypesValue.includes(file.type)) {
      this.showError(`Unsupported file type: ${file.type}`)
      return false
    }

    // get the file size in bytes and fill the file_size field
    const fileSizeInBytes = file.size
    console.log('File size in bytes:', fileSizeInBytes)
    const lengthField = document.querySelector('input[name="episode[length]"]')
    if (lengthField) {
      lengthField.value = fileSizeInBytes
    }

    // get the file duration in seconds
    const url = URL.createObjectURL(file)
    const sound = new Howl({
      src: [url],
      format: (file.name.toLowerCase().match(/\.([a-z0-9]+)$/) || [])[1],
      html5: true,
      preload: true,
      onload: () => {
        const durationSec = sound.duration()
        console.log('File duration in seconds:', durationSec)
        const durationField = document.querySelector('input[name="episode[duration]"]')
        if (durationField && Number.isFinite(durationSec)) durationField.value = Math.round(durationSec)
        URL.revokeObjectURL(url)
        sound.unload()
      },
      onloaderror: (_id, err) => {
        console.warn('Failed to load audio for duration:', err)
        URL.revokeObjectURL(url)
        sound.unload()
      }
    })

    return true
  }

  async uploadFile(file) {
    try {
      // Generate presigned URL
      const presignedUrl = await this.getPresignedUrl(file)
      
      if (!presignedUrl.success) {
        throw new Error(presignedUrl.error || 'Failed to get upload URL')
      }

      // Upload file to S3
      const response = await this.uploadToS3(file, presignedUrl)
      console.log('Upload response:', response)
      
      this.showSuccessState(file, presignedUrl)
      
    } catch (error) {
      console.error('Upload error:', error)
              this.showError(error.message || 'Upload failed')
    }
  }

  uploadCurrentFile() {
    if (!this.currentFile) {
      this.showError('No file selected')
      return
    }
    this.showUploadingState()
    this.uploadFile(this.currentFile)
  }

  async getPresignedUrl(file) {
    const response = await fetch('/api/presigned_urls', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        key: `episodes/${Date.now()}_${file.name}`,
        content_type: file.type,
        expires_in: '1h'
      })
    })

    if (!response.ok) {
              throw new Error(`Failed to get upload URL: ${response.status}`)
    }

    return await response.json()
  }

  async uploadToS3(file, presignedUrl) {
    try {
      // Create FormData object
      const formData = new FormData()
      
      // Add all required fields
      Object.keys(presignedUrl.fields).forEach(key => {
        formData.append(key, presignedUrl.fields[key])
      })
      
      // Add file (must be the last field)
      formData.append('file', file)
      
      console.log('Uploading to:', presignedUrl.upload_url)
      console.log('Fields:', presignedUrl.fields)
      console.log('File:', file.name, file.type, file.size)
      
      const response = await fetch(presignedUrl.upload_url, {
        method: 'POST',
        body: formData,
        // Important: Set credentials to omit to avoid CORS issues
        credentials: 'omit'
      })
      
      if (!response.ok) {
        throw new Error(`Upload failed: ${response.status} - ${response.statusText}`)
      }
      
      console.log('Upload response:', response)
      return response
      
    } catch (error) {
      console.error('Upload error:', error)
      if (error.response) {
        // Server responded with error status code
        throw new Error(`Upload failed: ${error.response.status} - ${error.response.statusText}`)
      } else if (error.request) {
        // Request was sent but no response received
        throw new Error('Network error: No server response received')
      } else {
        // Other errors
        throw new Error(`Upload failed: ${error.message}`)
      }
    }
  }

  updateProgress(percent) {
    this.progressBarTarget.style.width = `${percent}%`
          this.statusTarget.textContent = `Uploading... ${Math.round(percent)}%`
  }

  showDragOverState() {
    this.hideAllStates()
    this.dragOverTarget.classList.remove('hidden')
    this.dropZoneTarget.classList.add('border-blue-400', 'bg-blue-50')
  }

  hideDragOverState() {
    this.dragOverTarget.classList.add('hidden')
    this.dropZoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
  }

  showUploadingState() {
    this.hideAllStates()
    this.uploadingTarget.classList.remove('hidden')
    this.progressBarTarget.style.width = '0%'
          this.statusTarget.textContent = 'Preparing upload...'
  }

  showReadyState(file) {
    this.hideAllStates()
    if (this.hasReadyTarget) {
      this.readyTarget.classList.remove('hidden')
    }
    if (this.hasReadyInfoTarget && file) {
      this.readyInfoTarget.textContent = `${file.name} (${this.formatFileSize(file.size)})`
    }
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.classList.remove('hidden')
    }
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = 'Ready to upload'
    }
  }

  showSuccessState(file, presignedUrl) {
    this.hideAllStates()
    this.successTarget.classList.remove('hidden')
    this.fileInfoTarget.textContent = `${file.name} (${this.formatFileSize(file.size)})`
    
    // Build correct file access URL
    const fileKey = presignedUrl.fields.key
    // Extract base domain and region from presigned URL
    const uploadUrl = presignedUrl.upload_url
    // Remove the bucket name from the end, then add file key
    const baseUrl = uploadUrl.replace(/\/[^\/]+$/, '') // Remove the last path segment (bucket name)
    const fileUrl = `${baseUrl}/${fileKey}`
    
    // Update the file_uri field with the uploaded file URL
    const fileUriField = document.querySelector('input[name="episode[file_uri]"]')
    if (fileUriField) {
      fileUriField.value = fileUrl
    }
    
    console.log('File uploaded successfully:', fileUrl)
    console.log('Debug - upload_url:', uploadUrl)
    console.log('Debug - baseUrl:', baseUrl)
    console.log('Debug - fileKey:', fileKey)
  }

  showError(message) {
    console.log('Showing error:', message)
    this.hideAllStates()
    this.errorTarget.classList.remove('hidden')
    this.errorMessageTarget.textContent = message
    console.log('Error state shown')
  }

  hideAllStates() {
    console.log('Hiding all states')
    this.defaultTarget.classList.add('hidden')
    this.dragOverTarget.classList.add('hidden')
    this.uploadingTarget.classList.add('hidden')
    this.successTarget.classList.add('hidden')
    this.errorTarget.classList.add('hidden')
    console.log('All states hidden')
  }

  reset() {
    this.hideAllStates()
    this.defaultTarget.classList.remove('hidden')
    this.currentFile = null
    
    // Reset file input
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ''
    }
    
    // Reset progress bar
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = '0%'
    }

    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.classList.add('hidden')
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
}
