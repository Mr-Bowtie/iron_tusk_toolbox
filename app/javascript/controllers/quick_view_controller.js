import { Controller } from "@hotwired/stimulus"


// Connects to data-controller="quick-view"
export default class extends Controller {
  static targets = ["modal"];


  connect() {
  }

 showCardModal(){
    // card ids are in the form "inventory_card_1234", we want to grab the number at the end of the string
    const cardId = this.element.id.split("_").at(-1) ;
    const modalElement = document.querySelector(`[data-card-quick-view-id="${cardId}"]`);
    const htmlElement = document.querySelector('html')

    if (modalElement) {
      modalElement.classList.add('is-active');
      htmlElement.classList.add('is-clipped');
    }
  }


  close(){
    this.element.classList.remove("is-active");
    document.querySelector('html').classList.remove('is-clipped');
  }

  unClip(){
    document.querySelector('html').classList.remove('is-clipped');
  }
}
