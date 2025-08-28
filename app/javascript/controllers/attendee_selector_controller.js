import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="attendee-selector"
export default class extends Controller {
  static targets = [
    "availableHosts", "selectedHosts", "emptyHostsMessage",
    "availableGuests", "selectedGuests", "emptyGuestsMessage",
    "availableHost", "selectedHost", 
    "availableGuest", "selectedGuest",
    "guestIdsHidden", "hostIdsHidden"
  ]

  connect() {
    // Hide items that are already selected from available lists
    this.hideAlreadySelected()
    this.updateEmptyMessages()
    
    // Add form submit handler to manage hidden fields
    this.setupFormSubmitHandler()
  }
  
  setupFormSubmitHandler() {
    const form = this.element.closest('form')
    if (form) {
      form.addEventListener('submit', (event) => {
        this.handleFormSubmit(event)
      })
    }
  }
  
  handleFormSubmit(event) {
    // Manage hidden fields to ensure proper submission
    this.manageHiddenFields()
  }
  
  manageHiddenFields() {
    const selectedHosts = this.selectedHostsTarget.querySelectorAll('input[name="episode[host_ids][]"]')
    const selectedGuests = this.selectedGuestsTarget.querySelectorAll('input[name="episode[guest_ids][]"]')
    
    // If no hosts are selected, ensure the hidden field is active
    if (selectedHosts.length === 0) {
      this.hostIdsHiddenTarget.disabled = false
    } else {
      // If hosts are selected, disable the hidden field to avoid empty value
      this.hostIdsHiddenTarget.disabled = true
    }
    
    // If no guests are selected, ensure the hidden field is active
    if (selectedGuests.length === 0) {
      this.guestIdsHiddenTarget.disabled = false
    } else {
      // If guests are selected, disable the hidden field to avoid empty value
      this.guestIdsHiddenTarget.disabled = true
    }
  }

  selectAttendee(event) {
    event.preventDefault()
    const attendeeElement = event.currentTarget
    const attendeeId = attendeeElement.dataset.attendeeId
    const attendeeName = attendeeElement.dataset.attendeeName
    const attendeeType = attendeeElement.dataset.attendeeType
    
    // Check if already selected
    if (this.isAlreadySelected(attendeeId, attendeeType)) {
      return
    }

    // Hide from available list
    attendeeElement.style.display = 'none'
    
    // Add to selected list
    this.addToSelectedList(attendeeElement, attendeeType)
    
    // Update empty messages
    this.updateEmptyMessages()
    
    // Update hidden fields
    this.manageHiddenFields()
  }

  removeAttendee(event) {
    event.preventDefault()
    const selectedElement = event.currentTarget.closest('[data-attendee-selector-target*="selected"]')
    const attendeeId = selectedElement.dataset.attendeeId
    const attendeeType = selectedElement.dataset.attendeeType
    
    // Remove from selected list
    selectedElement.remove()
    
    // Show in available list
    this.showInAvailableList(attendeeId, attendeeType)
    
    // Update empty messages
    this.updateEmptyMessages()
    
    // Update hidden fields
    this.manageHiddenFields()
  }

  isAlreadySelected(attendeeId, attendeeType) {
    const selectedContainer = attendeeType === 'host' ? this.selectedHostsTarget : this.selectedGuestsTarget
    const existingSelected = selectedContainer.querySelector(`[data-attendee-id="${attendeeId}"]`)
    return existingSelected !== null
  }

  addToSelectedList(attendeeElement, attendeeType) {
    const attendeeId = attendeeElement.dataset.attendeeId
    const attendeeName = attendeeElement.dataset.attendeeName
    const avatarImg = attendeeElement.querySelector('img')
    const bioText = attendeeElement.querySelector('.text-xs.text-gray-500')
    
    const selectedContainer = attendeeType === 'host' ? this.selectedHostsTarget : this.selectedGuestsTarget
    const borderColor = attendeeType === 'host' ? 'border-blue-200' : 'border-green-200'
    const inputName = attendeeType === 'host' ? 'episode[host_ids][]' : 'episode[guest_ids][]'
    
    const selectedHTML = `
      <div class="flex items-center justify-between p-2 bg-white ${borderColor} rounded-md"
           data-attendee-selector-target="selected${attendeeType.charAt(0).toUpperCase() + attendeeType.slice(1)}"
           data-attendee-id="${attendeeId}"
           data-attendee-name="${attendeeName}"
           data-attendee-type="${attendeeType}">
        <div class="flex items-center">
          <img src="${avatarImg.src}" alt="${attendeeName}" class="w-8 h-8 rounded-full mr-3">
          <div>
            <div class="text-sm font-medium text-gray-900">${attendeeName}</div>
            ${bioText ? `<div class="text-xs text-gray-500">${bioText.textContent}</div>` : ''}
          </div>
        </div>
        <button type="button" class="text-red-600 hover:text-red-700" data-action="click->attendee-selector#removeAttendee">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
        <input type="hidden" name="${inputName}" value="${attendeeId}">
      </div>
    `
    
    // Remove empty message if it exists
    const emptyMessage = selectedContainer.querySelector('[data-attendee-selector-target*="empty"]')
    if (emptyMessage) {
      emptyMessage.remove()
    }
    
    selectedContainer.insertAdjacentHTML('beforeend', selectedHTML)
  }

  showInAvailableList(attendeeId, attendeeType) {
    const availableContainer = attendeeType === 'host' ? this.availableHostsTarget : this.availableGuestsTarget
    const hiddenElement = availableContainer.querySelector(`[data-attendee-id="${attendeeId}"]`)
    
    if (hiddenElement) {
      hiddenElement.style.display = 'flex'
    }
  }

  hideAlreadySelected() {
    // Hide hosts that are already selected
    if (this.hasSelectedHostsTarget) {
      const selectedHostIds = Array.from(this.selectedHostsTarget.querySelectorAll('[data-attendee-id]'))
        .map(el => el.dataset.attendeeId)
      
      selectedHostIds.forEach(id => {
        const availableElement = this.availableHostsTarget?.querySelector(`[data-attendee-id="${id}"]`)
        if (availableElement) {
          availableElement.style.display = 'none'
        }
      })
    }

    // Hide guests that are already selected
    if (this.hasSelectedGuestsTarget) {
      const selectedGuestIds = Array.from(this.selectedGuestsTarget.querySelectorAll('[data-attendee-id]'))
        .map(el => el.dataset.attendeeId)
      
      selectedGuestIds.forEach(id => {
        const availableElement = this.availableGuestsTarget?.querySelector(`[data-attendee-id="${id}"]`)
        if (availableElement) {
          availableElement.style.display = 'none'
        }
      })
    }
  }

  updateEmptyMessages() {
    // Update hosts empty message
    this.updateEmptyMessage('host')
    
    // Update guests empty message  
    this.updateEmptyMessage('guest')
  }

  updateEmptyMessage(type) {
    const selectedContainer = type === 'host' ? this.selectedHostsTarget : this.selectedGuestsTarget
    const emptyMessageTarget = type === 'host' ? 'emptyHostsMessage' : 'emptyGuestsMessage'
    
    const selectedItems = selectedContainer.querySelectorAll(`[data-attendee-selector-target*="selected${type.charAt(0).toUpperCase() + type.slice(1)}"]`)
    const emptyMessage = selectedContainer.querySelector(`[data-attendee-selector-target="${emptyMessageTarget}"]`)
    
    if (selectedItems.length === 0 && !emptyMessage) {
      // Add empty message
      const message = type === 'host' ? 
        'No hosts selected. Click on available hosts below to add them.' :
        'No guests selected. Click on available guests below to add them.'
      
      const emptyHTML = `
        <div class="text-sm text-gray-500 text-center py-8" data-attendee-selector-target="${emptyMessageTarget}">
          ${message}
        </div>
      `
      selectedContainer.insertAdjacentHTML('beforeend', emptyHTML)
    } else if (selectedItems.length > 0 && emptyMessage) {
      // Remove empty message
      emptyMessage.remove()
    }
  }
}
