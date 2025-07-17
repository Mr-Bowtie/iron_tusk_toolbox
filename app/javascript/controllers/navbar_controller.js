import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  connect() {
  }

  toggleMenu() {
    const burger = this.element.querySelector(".navbar-burger")
    const menu = this.element.querySelector(".navbar-menu")

    burger.classList.toggle("is-active")
    menu.classList.toggle("is-active")
  }

  toggleDropdown(event) {
    event.target.parentNode.classList.toggle("is-active")
  }
}
