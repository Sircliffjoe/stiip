require 'fileutils'

components_dir = 'app/components'
javascript_dir = 'app/javascript/controllers'
FileUtils.mkdir_p(components_dir)
FileUtils.mkdir_p(javascript_dir)

# Helper to write component
def write_component(name, rb_content, erb_content)
  dir = "app/components/#{name}"
  FileUtils.mkdir_p(dir)
  File.write("#{dir}/component.rb", rb_content)
  File.write("#{dir}/component.html.erb", erb_content)
  puts "Created ViewComponent: #{name}"
end

# 1. Navbar
write_component('navbar', <<~RUBY, <<~ERB)
  class Navbar::Component < ViewComponent::Base
    def initialize(user: nil)
      @user = user
    end
  end
RUBY
  <nav class="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 fixed w-full z-30 top-0 transition-colors duration-200">
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <div class="flex items-center">
          <a href="/" class="flex items-center gap-2">
            <div class="w-8 h-8 rounded bg-gradient-to-br from-sky-500 to-sky-600 flex items-center justify-center text-white font-bold text-xl">S</div>
            <span class="text-xl font-bold text-slate-900 dark:text-white hidden sm:block tracking-tight">STIIP</span>
          </a>
        </div>
        <div class="flex-1 flex justify-center px-4 sm:px-8">
          <%= render SearchBar::Component.new %>
        </div>
        <div class="flex items-center gap-3">
          <%= render DarkModeToggle::Component.new %>
          <% if @user %>
            <div class="relative" data-controller="dropdown">
              <button data-action="dropdown#toggle" class="flex items-center gap-2 p-1 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 transition">
                <div class="w-8 h-8 rounded-full bg-sky-100 dark:bg-sky-900 text-sky-700 dark:text-sky-300 flex items-center justify-center font-medium">
                  <%= @user.first_name[0] %>
                </div>
              </button>
              <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg py-1 ring-1 ring-black ring-opacity-5 focus:outline-none">
                <a href="/profile" class="block px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700">Your Profile</a>
                <%= button_to "Sign out", "/users/sign_out", method: :delete, class: "block w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-slate-100 dark:hover:bg-slate-700" %>
              </div>
            </div>
          <% else %>
            <a href="/users/sign_in" class="text-sm font-medium text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white">Log in</a>
            <a href="/users/sign_up" class="text-sm font-medium bg-sky-600 text-white px-3 py-2 rounded-md hover:bg-sky-700">Sign up</a>
          <% end %>
        </div>
      </div>
    </div>
  </nav>
ERB

# 2. Sidebar
write_component('sidebar', <<~RUBY, <<~ERB)
  class Sidebar::Component < ViewComponent::Base
    def initialize(active_nav: nil)
      @active_nav = active_nav
    end
  end
RUBY
  <aside class="hidden md:flex flex-col w-64 fixed inset-y-0 pt-16 bg-white dark:bg-slate-800 border-r border-slate-200 dark:border-slate-700 transition-colors duration-200">
    <div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
      <nav class="mt-5 flex-1 px-3 space-y-1">
        <a href="/dashboard" class="flex items-center px-3 py-2 text-sm font-medium rounded-md text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700">
          <svg class="mr-3 flex-shrink-0 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          Dashboard
        </a>
        <a href="/market" class="flex items-center px-3 py-2 text-sm font-medium rounded-md text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700">
          <svg class="mr-3 flex-shrink-0 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
          </svg>
          Market
        </a>
        <a href="/dividends" class="flex items-center px-3 py-2 text-sm font-medium rounded-md text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700">
          <svg class="mr-3 flex-shrink-0 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Dividends
        </a>
      </nav>
    </div>
  </aside>
ERB

# 3. Footer
write_component('footer', <<~RUBY, <<~ERB)
  class Footer::Component < ViewComponent::Base
  end
RUBY
  <footer class="bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 mt-auto">
    <div class="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col md:flex-row justify-between items-center gap-6">
        <div class="flex items-center gap-2">
          <div class="w-6 h-6 rounded bg-sky-500 flex items-center justify-center text-white font-bold text-xs">S</div>
          <span class="text-sm font-semibold text-slate-900 dark:text-white">STIIP</span>
        </div>
        <p class="text-sm text-slate-500 dark:text-slate-400 text-center">
          &copy; <%= Time.current.year %> Nigerian Stock Intelligence Platform. All rights reserved.
        </p>
      </div>
    </div>
  </footer>
ERB

# 4. Card
write_component('card', <<~RUBY, <<~ERB)
  class Card::Component < ViewComponent::Base
    def initialize(title: nil, subtitle: nil, padding: true)
      @title = title
      @subtitle = subtitle
      @padding = padding
    end
  end
RUBY
  <div class="bg-white dark:bg-slate-800 shadow-sm rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden transition-colors duration-200">
    <% if @title %>
      <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
        <h3 class="text-lg font-semibold leading-6 text-slate-900 dark:text-white"><%= @title %></h3>
        <% if @subtitle %><p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= @subtitle %></p><% end %>
      </div>
    <% end %>
    <div class="<%= @padding ? 'p-6' : '' %>">
      <%= content %>
    </div>
  </div>
ERB

# 5. Badge
write_component('badge', <<~RUBY, <<~ERB)
  class Badge::Component < ViewComponent::Base
    def initialize(text:, color: :sky)
      @text = text
      @color = color
    end

    def color_classes
      case @color.to_sym
      when :sky then "bg-sky-100 text-sky-800 dark:bg-sky-900/30 dark:text-sky-300"
      when :green then "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
      when :red then "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
      when :gold then "bg-gold-100 text-gold-800 dark:bg-gold-900/30 dark:text-gold-300"
      else "bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-300"
      end
    end
  end
RUBY
  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium <%= color_classes %>">
    <%= @text %>
  </span>
ERB

# 6. StockTicker
write_component('stock_ticker', <<~RUBY, <<~ERB)
  class StockTicker::Component < ViewComponent::Base
    def initialize(stocks: [])
      @stocks = stocks
    end
  end
RUBY
  <div class="w-full bg-slate-900 text-white overflow-hidden flex whitespace-nowrap py-2 text-sm border-b border-slate-800">
    <div class="flex animate-ticker gap-8 px-4">
      <% @stocks.each do |stock| %>
        <div class="flex items-center gap-2">
          <span class="font-semibold"><%= stock[:ticker] %></span>
          <span>₦<%= stock[:price] %></span>
          <span class="<%= stock[:change] >= 0 ? 'text-green-400' : 'text-red-400' %>">
            <%= stock[:change] >= 0 ? '+' : '' %><%= stock[:change] %>%
          </span>
        </div>
      <% end %>
    </div>
  </div>
ERB

# 7. StatCard
write_component('stat_card', <<~RUBY, <<~ERB)
  class StatCard::Component < ViewComponent::Base
    def initialize(title:, value:, trend: nil, icon: nil)
      @title = title
      @value = value
      @trend = trend
      @icon = icon
    end
  end
RUBY
  <div class="bg-white dark:bg-slate-800 overflow-hidden shadow-sm rounded-xl border border-slate-200 dark:border-slate-700 px-4 py-5 sm:p-6 transition-colors duration-200">
    <dt class="truncate text-sm font-medium text-slate-500 dark:text-slate-400"><%= @title %></dt>
    <dd class="mt-2 flex items-baseline justify-between md:block lg:flex">
      <div class="flex items-baseline text-2xl font-bold text-slate-900 dark:text-white">
        <%= @value %>
      </div>
      <% if @trend %>
        <div class="inline-flex items-baseline px-2.5 py-0.5 rounded-full text-sm font-medium md:mt-2 lg:mt-0 <%= @trend >= 0 ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400' %>">
          <%= @trend >= 0 ? '+' : '' %><%= @trend %>%
        </div>
      <% end %>
    </dd>
  </div>
ERB

# 8. Alert
write_component('alert', <<~RUBY, <<~ERB)
  class Alert::Component < ViewComponent::Base
    def initialize(message:, type: :info)
      @message = message
      @type = type
    end
  end
RUBY
  <div class="p-4 rounded-md bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-800">
    <div class="flex">
      <div class="ml-3">
        <p class="text-sm font-medium text-blue-800 dark:text-blue-300"><%= @message %></p>
      </div>
    </div>
  </div>
ERB

# 9. EmptyState
write_component('empty_state', <<~RUBY, <<~ERB)
  class EmptyState::Component < ViewComponent::Base
    def initialize(title:, description:, icon: nil)
      @title = title
      @description = description
    end
  end
RUBY
  <div class="text-center py-12 px-4 sm:px-6 lg:py-16 lg:px-8 bg-white dark:bg-slate-800 rounded-xl border border-dashed border-slate-300 dark:border-slate-700">
    <svg class="mx-auto h-12 w-12 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
    </svg>
    <h3 class="mt-2 text-sm font-medium text-slate-900 dark:text-white"><%= @title %></h3>
    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= @description %></p>
    <div class="mt-6">
      <%= content %>
    </div>
  </div>
ERB

# 10. DarkModeToggle
write_component('dark_mode_toggle', <<~RUBY, <<~ERB)
  class DarkModeToggle::Component < ViewComponent::Base
  end
RUBY
  <button data-controller="dark-mode" data-action="click->dark-mode#toggle" class="p-2 rounded-full text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-700 transition">
    <svg data-dark-mode-target="moon" class="w-5 h-5 hidden dark:block" fill="currentColor" viewBox="0 0 20 20"><path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path></svg>
    <svg data-dark-mode-target="sun" class="w-5 h-5 block dark:hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
  </button>
ERB

# 11. SearchBar
write_component('search_bar', <<~RUBY, <<~ERB)
  class SearchBar::Component < ViewComponent::Base
  end
RUBY
  <div class="max-w-lg w-full lg:max-w-xs" data-controller="search">
    <label for="search" class="sr-only">Search companies</label>
    <div class="relative">
      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
        <svg class="h-5 w-5 text-slate-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd" />
        </svg>
      </div>
      <input id="search" name="search" class="block w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md leading-5 bg-white dark:bg-slate-700 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:bg-white focus:border-sky-500 focus:ring-sky-500 sm:text-sm transition duration-150 ease-in-out" placeholder="Search companies, ticker..." type="search">
    </div>
  </div>
ERB

# 12. DividendCalendarCard
write_component('dividend_calendar_card', <<~RUBY, <<~ERB)
  class DividendCalendarCard::Component < ViewComponent::Base
    def initialize(dividends: [])
      @dividends = dividends
    end
  end
RUBY
  <div class="bg-white dark:bg-slate-800 shadow rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700">
    <table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700">
      <thead class="bg-slate-50 dark:bg-slate-900/50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Company</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Amount</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Qual. Date</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Pay Date</th>
        </tr>
      </thead>
      <tbody class="bg-white dark:bg-slate-800 divide-y divide-slate-200 dark:divide-slate-700">
        <% @dividends.each do |div| %>
          <tr>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900 dark:text-white"><%= div[:company] %></td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">₦<%= div[:amount] %></td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400"><%= div[:qual_date] %></td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400"><%= div[:pay_date] %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
ERB

# 13. ChartCard
write_component('chart_card', <<~RUBY, <<~ERB)
  class ChartCard::Component < ViewComponent::Base
    def initialize(title:)
      @title = title
    end
  end
RUBY
  <div class="bg-white dark:bg-slate-800 shadow rounded-lg border border-slate-200 dark:border-slate-700 p-6">
    <h3 class="text-lg font-medium leading-6 text-slate-900 dark:text-white mb-4"><%= @title %></h3>
    <div class="h-64 w-full">
      <%= content %>
    </div>
  </div>
ERB

# 14. PriceChange
write_component('price_change', <<~RUBY, <<~ERB)
  class PriceChange::Component < ViewComponent::Base
    def initialize(change:)
      @change = change.to_f
    end
    
    def positive?
      @change >= 0
    end
  end
RUBY
  <span class="inline-flex items-center text-sm font-semibold <%= positive? ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400' %>">
    <% if positive? %>
      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path></svg>
    <% else %>
      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path></svg>
    <% end %>
    <%= @change.abs %>%
  </span>
ERB

# Now create Stimulus Controllers
stimulus_controllers = {
  'dropdown_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      static targets = ["menu"]
      toggle() { this.menuTarget.classList.toggle("hidden") }
      hide(e) { if (!this.element.contains(e.target)) this.menuTarget.classList.add("hidden") }
    }
  JS
  'tabs_controller.js' => <<~JS,
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
          el.classList.toggle("border-sky-500", index === i)
          el.classList.toggle("text-sky-600", index === i)
        })
        this.panelTargets.forEach((el, i) => {
          el.classList.toggle("hidden", index !== i)
        })
      }
    }
  JS
  'modal_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      static targets = ["container"]
      open() { this.containerTarget.classList.remove("hidden") }
      close() { this.containerTarget.classList.add("hidden") }
    }
  JS
  'dark_mode_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      connect() {
        if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
          document.documentElement.classList.add('dark')
        } else {
          document.documentElement.classList.remove('dark')
        }
      }
      toggle() {
        if (document.documentElement.classList.contains('dark')) {
          document.documentElement.classList.remove('dark')
          localStorage.theme = 'light'
        } else {
          document.documentElement.classList.add('dark')
          localStorage.theme = 'dark'
        }
      }
    }
  JS
  'search_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      // Basic stub for search debounce
    }
  JS
  'notification_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      // Notification bell toggle
    }
  JS
  'flash_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      connect() {
        setTimeout(() => this.dismiss(), 5000)
      }
      dismiss() {
        this.element.style.transition = "opacity 0.5s ease"
        this.element.style.opacity = "0"
        setTimeout(() => this.element.remove(), 500)
      }
    }
  JS
  'sidebar_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      static targets = ["menu"]
      toggle() { this.menuTarget.classList.toggle("-translate-x-full") }
    }
  JS
  'clipboard_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      static targets = ["source"]
      copy() { navigator.clipboard.writeText(this.sourceTarget.value) }
    }
  JS
  'filter_controller.js' => <<~JS,
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      submit() { this.element.requestSubmit() }
    }
  JS
  'chart_controller.js' => <<~JS
    import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
      // Stub for specific chart js interactions if needed beyond chartkick
    }
  JS
}

stimulus_controllers.each do |filename, content|
  File.write(File.join(javascript_dir, filename), content)
  puts "Created Stimulus controller: \#{filename}"
end

# Update application_controller.js to auto-load controllers
File.write('app/javascript/controllers/index.js', <<~JS)
  import { application } from "./application"
  import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
  eagerLoadControllersFrom("controllers", application)
JS
