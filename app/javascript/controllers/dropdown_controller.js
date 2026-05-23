import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["menu"]
  toggle(e) {
    e.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide(e) { if (!this.element.contains(e.target)) this.menuTarget.classList.add("hidden") }
  close() { this.menuTarget.classList.add("hidden") }
}
