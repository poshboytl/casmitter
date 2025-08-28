import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "fileInput",
    "status",
    "hiddenField"
  ]

  static values = {
    maxFileSize: { type: Number, default: 10 * 1024 * 1024 }, // 10MB
    allowedTypes: { type: Array, default: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'] },
    uploadPath: { type: String, default: 'images' },
    fieldName: String,
    uniqueId: String
  }

  connect() {
    console.log('ImageUpload controller connected')
    this.currentFile = null
  }

  disconnect() {
    // Clean up if needed
  }

  selectFile() {
    // Trigger file input click
    this.fileInputTarget.click()
    
    // Add change event listener
    this.fileInputTarget.addEventListener('change', this.handleFileInput.bind(this), { once: true })
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
    this.uploadFile(file)
  }

  validateFile(file) {
    // Check file size
    if (file.size > this.maxFileSizeValue) {
      this.showError(`File size cannot exceed ${this.formatFileSize(this.maxFileSizeValue)}`)
      return false
    }

    // Check file type
    if (!this.allowedTypesValue.includes(file.type)) {
      this.showError(`Unsupported file type: ${file.type}. Please select an image file.`)
      return false
    }

    return true
  }

  async uploadFile(file) {
    try {
      this.showStatus('Uploading...', 'text-blue-600')
      
      // Generate presigned URL for image upload
      const presignedUrl = await this.getPresignedUrl(file)
      
      if (!presignedUrl.success) {
        throw new Error(presignedUrl.error || 'Failed to get upload URL')
      }

      // Upload file to S3
      const response = await this.uploadToS3(file, presignedUrl)
      console.log('Upload response:', response)
      
      this.showSuccess(file, presignedUrl)
      
    } catch (error) {
      console.error('Upload error:', error)
      this.showError(error.message || 'Upload failed')
    }
  }

  async getPresignedUrl(file) {
    const timestamp = Date.now()
    const filename = file.name.replace(/[^a-zA-Z0-9.-]/g, '_') // Sanitize filename
    const key = `${this.uploadPathValue}/${timestamp}_${filename}`
    
    const response = await fetch('/api/presigned_urls', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        key: key,
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

  showSuccess(file, presignedUrl) {
    // Build correct file access URL
    const fileKey = presignedUrl.fields.key
    // Extract base domain and region from presigned URL
    const uploadUrl = presignedUrl.upload_url
    // Remove the bucket name from the end, then add file key
    const baseUrl = uploadUrl.replace(/\/[^\/]+$/, '') // Remove the last path segment (bucket name)
    const fileUrl = `${baseUrl}/${fileKey}`
    
    // Update the hidden field with the uploaded file URL
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = fileUrl
      console.log('Image URL set to form field:', fileUrl)
    }
    
    this.showStatus(`Upload successful! ${file.name}`, 'text-green-600')
    
    // Reset file input
    this.fileInputTarget.value = ''
    this.currentFile = null
    
    console.log('Image uploaded successfully:', fileUrl)
  }

  showError(message) {
    this.showStatus(message, 'text-red-600')
  }

  showStatus(message, colorClass = 'text-gray-600') {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = `text-sm ${colorClass} mt-1`
      this.statusTarget.classList.remove('hidden')
      
      // Hide status after 5 seconds
      setTimeout(() => {
        this.statusTarget.classList.add('hidden')
      }, 5000)
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
