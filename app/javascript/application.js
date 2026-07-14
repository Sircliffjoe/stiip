import "@hotwired/turbo-rails"
import "controllers"
import "channels"

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js").catch((error) => {
      console.warn("Service worker registration failed:", error)
    })
  })
}
