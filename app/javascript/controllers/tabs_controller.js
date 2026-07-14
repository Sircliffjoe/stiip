import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["tab", "panel"]
  connect() { this.showTab(0) }
  switch(event) {
    event.preventDefault()
    this.showTab(this.tabTargets.indexOf(event.currentTarget))
  }
  showTab(index) {
    this.tabTargets.forEach((el, i) => {
      el.classList.toggle("border-navy-500", index === i)
      el.classList.toggle("text-navy-600", index === i)
    })
    this.panelTargets.forEach((el, i) => {
      el.classList.toggle("hidden", index !== i)
    })
  }
}
