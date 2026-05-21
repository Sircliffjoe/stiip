import consumer from "channels/consumer"

consumer.subscriptions.create("MarketDataChannel", {
  connected() {
    console.log("Connected to MarketDataChannel");
  },
  received(data) {
    // Example payload: { ticker: 'MTNN', price: '245.50', change: '+1.5' }
    // Update the DOM if elements exist
    const priceElement = document.querySelector(`[data-ticker="${data.ticker}"] .current-price`);
    if (priceElement) {
      priceElement.textContent = `₦${data.price}`;
      priceElement.classList.add('text-green-500'); // Flash green
      setTimeout(() => priceElement.classList.remove('text-green-500'), 1000);
    }
  }
});
