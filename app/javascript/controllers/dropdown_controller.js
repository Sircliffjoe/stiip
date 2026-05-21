import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["menu"]
  toggle() { this.menuTarget.classList.toggle("hidden") }
  hide(e) { if (!this.element.contains(e.target)) this.menuTarget.classList.add("hidden") }
}
