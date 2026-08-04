# lib/brevo_delivery.rb
require 'mail'
require 'base64'
require 'erb'
require_relative '../app/services/brevo_service'

class BrevoDelivery
  def initialize(settings = {})
    @settings = settings
    @service  = BrevoService.new
  end

  def deliver!(mail)
    Rails.logger.info "[BrevoDelivery] Sending to: #{Array(mail.to).join(", ")} | Subject: #{mail.subject}"

    html_body = mail.html_part&.body&.decoded || mail.body.encoded
    html_body = html_body.to_s.strip
    html_body = "<p>#{ERB::Util.html_escape(mail.text_part&.body&.decoded || mail.body.decoded)}</p>" if html_body.empty?

    text_body = mail.text_part&.body&.decoded
    text_body = ActionView::Base.full_sanitizer.sanitize(html_body).to_s.strip if text_body.blank?

    recipients = Array(mail.to).map { |e| { 'email' => e.to_s } }
    raise "No email recipients provided" if recipients.empty?

    sender = {
      'email' => (mail[:from]&.addresses&.first || mail.from&.first || ENV["BREVO_SENDER_EMAIL"] || BrevoService::DEFAULT_SENDER_EMAIL),
      'name'  => (mail[:from]&.display_names&.first || ENV["BREVO_SENDER_NAME"] || BrevoService::DEFAULT_SENDER_NAME)
    }

    attachments = mail.attachments.present? ? mail.attachments.map { |a|
      { 'name' => a.filename, 'content' => Base64.strict_encode64(a.body.decoded) }
    } : []

    response = @service.send_email(
      to:           recipients,
      subject:      mail.subject,
      html_content: html_body,
      text_content: text_body,
      sender:       sender,
      attachments:  attachments,
      cc:           Array(mail.cc).map { |e| { 'email' => e.to_s } },
      bcc:          Array(mail.bcc).map { |e| { 'email' => e.to_s } },
      reply_to:     mail.reply_to&.first
    )

    message_id =
      if response.respond_to?(:message_id)
        response.message_id
      elsif response.respond_to?(:[])
        response[:messageId] || response["messageId"] || response[:message_id] || response["message_id"]
      end

    Rails.logger.info "[BrevoDelivery] Email accepted by Brevo#{message_id.present? ? " | message_id: #{message_id}" : ""}"
    true

  rescue => e
    Rails.logger.error "[BrevoDelivery] ERROR: #{e.class} - #{e.message}"
    if e.respond_to?(:response_body) && e.response_body.present?
      Rails.logger.error "[BrevoDelivery] Response Body: #{e.response_body}"
    end
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end
end
