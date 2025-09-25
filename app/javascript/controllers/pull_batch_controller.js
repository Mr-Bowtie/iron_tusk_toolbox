import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pull-batch"
export default class extends Controller {
  static targets = [
    "batchInput",
    "csvInput",
    "csvPullSubmit"
  ]

  connect() {
    this.validateCsvForm()
  }

  validateCsvForm() {
    const choicesDiv = this.element.querySelector("[data-controller~='choices']")
    if (!choicesDiv) return;

    const choicesController = this.application.getControllerForElementAndIdentifier(choicesDiv, 'choices')
    if (!choicesController) return;

    const fileSelected = this.csvInputTarget.files.length > 0
    const inputValue = choicesController.getOptionLabel()
    const batchValueSelected = inputValue.length > 0
    const valueIsInteger = inputValue.length > 0 && Number.isInteger(Number(inputValue))
    const integerError = this.element.querySelector(".integer-error")
    if(valueIsInteger) {
      integerError.classList.remove("is-hidden")
    } else {
      integerError.classList.remove("is-hidden")
      integerError.classList.add("is-hidden")
    }

    const isValid = fileSelected && batchValueSelected && !valueIsInteger

    this.csvPullSubmitTarget.disabled = !isValid
  }
}
