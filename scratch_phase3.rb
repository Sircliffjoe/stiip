require 'fileutils'

# Directories to create
directories = [
  'config/initializers',
  'config/locales',
  'app/views/devise/sessions',
  'app/views/devise/registrations',
  'app/views/devise/passwords',
  'app/views/devise/shared',
  'app/policies',
  'app/controllers/concerns'
]

directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# 1. Devise Initializer
files['config/initializers/devise.rb'] = <<~RUBY
  Devise.setup do |config|
    config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
    require 'devise/orm/active_record'
    config.case_insensitive_keys = [:email]
    config.strip_whitespace_keys = [:email]
    config.skip_session_storage = [:http_auth]
    config.stretches = Rails.env.test? ? 1 : 12
    config.reconfirmable = true
    config.expire_all_remember_me_on_sign_out = true
    config.password_length = 6..128
    config.email_regexp = /\\A[^@\\s]+@[^@\\s]+\\z/
    config.reset_password_within = 6.hours
    config.sign_out_via = :delete
    config.responder.error_status = :unprocessable_entity
    config.responder.redirect_status = :see_other
  end
RUBY

# 2. Pundit Policies
files['app/policies/application_policy.rb'] = <<~RUBY
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index?
      false
    end

    def show?
      false
    end

    def create?
      false
    end

    def new?
      create?
    end

    def update?
      false
    end

    def edit?
      update?
    end

    def destroy?
      false
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        raise NotImplementedError, "You must define #resolve in \#{self.class}"
      end

      private

      attr_reader :user, :scope
    end
  end
RUBY

files['app/policies/admin_policy.rb'] = <<~RUBY
  class AdminPolicy < Struct.new(:user, :admin)
    def index?
      user&.admin? || user&.analyst?
    end

    def manage?
      user&.admin?
    end
  end
RUBY

files['app/policies/company_policy.rb'] = <<~RUBY
  class CompanyPolicy < ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    def create?
      user&.admin? || user&.analyst?
    end

    def update?
      user&.admin? || user&.analyst?
    end

    def destroy?
      user&.admin?
    end
  end
RUBY

files['app/policies/news_article_policy.rb'] = <<~RUBY
  class NewsArticlePolicy < ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    def create?
      user&.admin? || user&.analyst?
    end

    def update?
      user&.admin? || user&.analyst?
    end

    def destroy?
      user&.admin?
    end
  end
RUBY

files['app/policies/watchlist_policy.rb'] = <<~RUBY
  class WatchlistPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present? && record.user_id == user.id
    end

    def create?
      user.present?
    end

    def update?
      user.present? && record.user_id == user.id
    end

    def destroy?
      user.present? && record.user_id == user.id
    end
  end
RUBY

# 3. Authenticatable Concern
files['app/controllers/concerns/authenticatable.rb'] = <<~RUBY
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      include Pundit::Authorization

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      # Add helper method to check premium status
      helper_method :premium_user?
    end

    private

    def require_admin!
      authenticate_user!
      unless current_user.admin? || current_user.analyst?
        flash[:alert] = "Access denied."
        redirect_to root_path
      end
    end

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end

    def premium_user?
      user_signed_in? && (current_user.premium? || current_user.admin?)
    end
    
    def after_sign_in_path_for(resource)
      if resource.admin? || resource.analyst?
        # TODO: Implement admin dashboard path
        root_path
      else
        # TODO: Implement user dashboard path
        root_path
      end
    end
  end
RUBY

# 4. Update Application Controller
files['app/controllers/application_controller.rb'] = <<~RUBY
  class ApplicationController < ActionController::Base
    # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
    allow_browser versions: :modern
    
    include Authenticatable
  end
RUBY

# 5. Devise Views (Tailwind Styled)
files['app/views/devise/shared/_links.html.erb'] = <<~ERB
  <div class="mt-6 flex flex-col space-y-2 text-sm text-center">
    <%- if controller_name != 'sessions' %>
      <%= link_to "Log in", new_session_path(resource_name), class: "font-medium text-sky-600 hover:text-sky-500" %><br />
    <% end %>

    <%- if devise_mapping.registerable? && controller_name != 'registrations' %>
      <%= link_to "Sign up", new_registration_path(resource_name), class: "font-medium text-sky-600 hover:text-sky-500" %><br />
    <% end %>

    <%- if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations' %>
      <%= link_to "Forgot your password?", new_password_path(resource_name), class: "font-medium text-sky-600 hover:text-sky-500" %><br />
    <% end %>
  </div>
ERB

files['app/views/devise/sessions/new.html.erb'] = <<~ERB
  <div class="min-h-[80vh] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8 bg-white dark:bg-slate-800 p-8 rounded-xl shadow-lg border border-slate-100 dark:border-slate-700">
      <div>
        <h2 class="mt-2 text-center text-3xl font-extrabold text-slate-900 dark:text-white">
          Welcome back
        </h2>
        <p class="mt-2 text-center text-sm text-slate-600 dark:text-slate-400">
          Sign in to your STIIP account
        </p>
      </div>
      
      <%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { class: "mt-8 space-y-6" }) do |f| %>
        <div class="rounded-md shadow-sm space-y-4">
          <div>
            <%= f.label :email, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
            <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 focus:z-10 sm:text-sm" %>
          </div>

          <div>
            <%= f.label :password, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
            <%= f.password_field :password, autocomplete: "current-password", class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 focus:z-10 sm:text-sm" %>
          </div>
        </div>

        <% if devise_mapping.rememberable? %>
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <%= f.check_box :remember_me, class: "h-4 w-4 text-sky-600 focus:ring-sky-500 border-slate-300 rounded" %>
              <%= f.label :remember_me, class: "ml-2 block text-sm text-slate-900 dark:text-slate-300" %>
            </div>
          </div>
        <% end %>

        <div>
          <%= f.submit "Log in", class: "group relative w-full flex justify-center py-2.5 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-sky-600 hover:bg-sky-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-sky-500 transition-colors shadow-md" %>
        </div>
      <% end %>

      <%= render "devise/shared/links" %>
    </div>
  </div>
ERB

files['app/views/devise/registrations/new.html.erb'] = <<~ERB
  <div class="min-h-[80vh] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8 bg-white dark:bg-slate-800 p-8 rounded-xl shadow-lg border border-slate-100 dark:border-slate-700">
      <div>
        <h2 class="mt-2 text-center text-3xl font-extrabold text-slate-900 dark:text-white">
          Create an account
        </h2>
        <p class="mt-2 text-center text-sm text-slate-600 dark:text-slate-400">
          Join the Nigerian Stock Intelligence Platform
        </p>
      </div>

      <%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { class: "mt-8 space-y-6" }) do |f| %>
        <%= render "devise/shared/error_messages", resource: resource %>

        <div class="rounded-md shadow-sm space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <%= f.label :first_name, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
              <%= f.text_field :first_name, autofocus: true, class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 sm:text-sm" %>
            </div>
            <div>
              <%= f.label :last_name, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
              <%= f.text_field :last_name, class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 sm:text-sm" %>
            </div>
          </div>

          <div>
            <%= f.label :email, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
            <%= f.email_field :email, autocomplete: "email", class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 sm:text-sm" %>
          </div>

          <div>
            <%= f.label :password, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
            <% if @minimum_password_length %>
              <span class="text-xs text-slate-500">(<%= @minimum_password_length %> characters minimum)</span>
            <% end %>
            <%= f.password_field :password, autocomplete: "new-password", class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 sm:text-sm" %>
          </div>

          <div>
            <%= f.label :password_confirmation, class: "block text-sm font-medium text-slate-700 dark:text-slate-300" %>
            <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-slate-300 dark:border-slate-600 placeholder-slate-500 text-slate-900 dark:text-white dark:bg-slate-700 rounded-md focus:outline-none focus:ring-sky-500 focus:border-sky-500 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= f.submit "Sign up", class: "group relative w-full flex justify-center py-2.5 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-gold-500 hover:bg-gold-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gold-500 transition-colors shadow-md text-slate-900" %>
        </div>
      <% end %>

      <%= render "devise/shared/links" %>
    </div>
  </div>
ERB

files['app/views/devise/shared/_error_messages.html.erb'] = <<~ERB
  <% if resource.errors.any? %>
    <div id="error_explanation" class="bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-300 px-4 py-3 rounded relative mb-4">
      <h2 class="font-semibold text-sm mb-2">
        <%= I18n.t("errors.messages.not_saved",
                   count: resource.errors.count,
                   resource: resource.class.model_name.human.downcase)
         %>
      </h2>
      <ul class="list-disc pl-5 text-sm space-y-1">
        <% resource.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>
ERB

files.each do |filename, content|
  File.write(filename, content)
  puts "Created \#{filename}"
end
