import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('click', this.confirmDelete.bind(this))
  }

  confirmDelete(event) {
    if (!confirm('Are you sure you want to delete this item?')) {
      event.preventDefault()
      return false
    }
  }
}
