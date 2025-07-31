import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox"
export default class extends Controller {
  static targets = ["toggle", "checkbox"]
  connect() {
  }

  toggleAll() {
    this.checkboxTargets.forEach(cb => cb.checked = this.toggleTarget.checked)
  }

  checkboxChanged() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    this.toggleTarget.checked = allChecked
  }
}
