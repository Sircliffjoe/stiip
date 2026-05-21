import consumer from "channels/consumer"

consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    console.log("Connected to NotificationsChannel");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Create a toast notification
    const container = document.getElementById('flash-container');
    if (!container) return;
    
    const toast = document.createElement('div');
    toast.className = 'p-4 rounded-md bg-white border border-sky-200 shadow-lg mb-2 transform transition-all duration-300 translate-y-0 opacity-100';
    toast.innerHTML = `
      <div class="flex items-start">
        <div class="ml-3 w-0 flex-1 pt-0.5">
          <p class="text-sm font-medium text-slate-900">${data.title}</p>
          <p class="mt-1 text-sm text-slate-500">${data.message}</p>
        </div>
      </div>
    `;
    
    container.appendChild(toast);
    
    // Auto dismiss
    setTimeout(() => {
      toast.classList.replace('opacity-100', 'opacity-0');
      setTimeout(() => toast.remove(), 300);
    }, 5000);
  }
});
