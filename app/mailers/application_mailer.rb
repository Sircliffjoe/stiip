class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{ENV.fetch("BREVO_SENDER_NAME", "NoraCapital")} <#{ENV.fetch("BREVO_SENDER_EMAIL", "noreply@noracapital.com.ng")}>" }
  layout "mailer"
end
