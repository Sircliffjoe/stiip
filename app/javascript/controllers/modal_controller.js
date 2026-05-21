import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["container"]
  open() { this.containerTarget.classList.remove("hidden") }
  close() { this.containerTarget.classList.add("hidden") }
}
