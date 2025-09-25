import { Controller } from "@hotwired/stimulus"
import Choices from "choices.js"

// Connects to data-controller="choices"
export default class extends Controller {
  connect() {
    const select = this.element.querySelector("select");
    // Defaults
    var options = { };

    if (select.classList.contains('additive-choices')) {
      options.addChoices = true;
    }

    this.choices = new Choices(select, options)
  }

  disconnect() {
    this.choices.destroy();
  }

  getOptionLabel() {
    return this.choices.getValue().label
  }
}
