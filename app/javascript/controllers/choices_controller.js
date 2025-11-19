import { Controller } from "@hotwired/stimulus"
import Choices from "choices.js"

// Connects to data-controller="choices"
export default class extends Controller {
  connect() {
    const select = this.element.querySelector("select")
    this.choices = new Choices(select)
  }

  disconnect() {
    this.choices.destroy();
  }
}
