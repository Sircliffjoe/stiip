require 'fileutils'

directories = [
  'app/channels/application_cable',
  'app/services/notifications',
  'app/javascript/channels'
]
directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# ApplicationCable
files['app/channels/application_cable/connection.rb'] = <<~RUBY
  module ApplicationCable
    class Connection < ActionCable::Connection::Base
      identified_by :current_user

      def connect
        self.current_user = find_verified_user
      end

      private

      def find_verified_user
        if verified_user = env['warden'].user
          verified_user
        else
          reject_unauthorized_connection
        end
      end
    end
  end
RUBY

files['app/channels/application_cable/channel.rb'] = <<~RUBY
  module ApplicationCable
    class Channel < ActionCable::Channel::Base
    end
  end
RUBY

# Specific Channels
files['app/channels/notifications_channel.rb'] = <<~RUBY
  class NotificationsChannel < ApplicationCable::Channel
    def subscribed
      stream_for current_user
    end

    def unsubscribed
      # Any cleanup needed when channel is unsubscribed
    end
    
    def mark_as_read(data)
      notification = current_user.notifications.find_by(id: data['id'])
      notification&.mark_as_read!
    end
  end
RUBY

files['app/channels/market_data_channel.rb'] = <<~RUBY
  class MarketDataChannel < ApplicationCable::Channel
    def subscribed
      stream_from "market_data_updates"
    end
  end
RUBY

# Notification Service
files['app/services/notifications/create.rb'] = <<~RUBY
  module Notifications
    class Create
      def initialize(user:, title:, message:, type: 'info', url: nil)
        @user = user
        @title = title
        @message = message
        @type = type
        @url = url
      end

      def call
        notification = @user.notifications.create!(
          title: @title,
          message: @message,
          notification_type: @type,
          action_url: @url
        )

        broadcast(notification)
        notification
      end

      private

      def broadcast(notification)
        NotificationsChannel.broadcast_to(
          @user,
          {
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.notification_type,
            url: notification.action_url,
            created_at: notification.created_at.strftime('%l:%M %p')
          }
        )
      end
    end
  end
RUBY

# JavaScript Client Setup
files['app/javascript/channels/index.js'] = <<~JS
  // Import all the channels to be used by Action Cable
  import "channels/notifications_channel"
  import "channels/market_data_channel"
JS

files['app/javascript/channels/consumer.js'] = <<~JS
  import { createConsumer } from "@hotwired/turbo-rails"
  export default createConsumer()
JS

files['app/javascript/channels/notifications_channel.js'] = <<~JS
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
JS

files['app/javascript/channels/market_data_channel.js'] = <<~JS
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
JS

files.each do |filename, content|
  File.write(filename, content)
  puts "Created #{filename}"
end
