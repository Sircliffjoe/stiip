class BrevoService
  DEFAULT_SENDER_EMAIL = "noreply@noracapital.com.ng"
  DEFAULT_SENDER_NAME = "NoraCapital"

  def initialize(api_client: Brevo::ApiClient.default)
    raise "BREVO_API_KEY is required to send email through Brevo" if ENV["BREVO_API_KEY"].blank?

    @api = Brevo::TransactionalEmailsApi.new(api_client)
  end

  def send_email(to:, subject:, html_content:, text_content:, sender:, attachments: [], cc: [], bcc: [], reply_to: nil)
    email = Brevo::SendSmtpEmail.new(
      sender: build_sender(sender),
      to: build_recipients(to),
      cc: build_recipients(cc),
      bcc: build_recipients(bcc),
      reply_to: build_reply_to(reply_to),
      subject: subject.to_s,
      html_content: html_content.to_s,
      text_content: text_content.to_s,
      attachment: build_attachments(attachments)
    )

    @api.send_transac_email(email)
  end

  private

  def build_sender(sender)
    sender ||= {}

    Brevo::SendSmtpEmailSender.new(
      email: sender[:email] || sender["email"] || ENV.fetch("BREVO_SENDER_EMAIL", DEFAULT_SENDER_EMAIL),
      name: sender[:name] || sender["name"] || ENV.fetch("BREVO_SENDER_NAME", DEFAULT_SENDER_NAME)
    )
  end

  def build_recipients(recipients)
    Array(recipients).filter_map do |recipient|
      email = value_from(recipient, :email)
      email ||= recipient.to_s
      next if email.blank?

      Brevo::SendSmtpEmailTo.new(email: email, name: value_from(recipient, :name))
    end
  end

  def build_reply_to(reply_to)
    return nil if reply_to.blank?

    email = value_from(reply_to, :email)
    email ||= reply_to.to_s
    name = value_from(reply_to, :name)

    Brevo::SendSmtpEmailReplyTo.new(email: email, name: name)
  end

  def build_attachments(attachments)
    Array(attachments).map do |attachment|
      Brevo::SendSmtpEmailAttachment.new(
        name: attachment[:name] || attachment["name"],
        content: attachment[:content] || attachment["content"]
      )
    end
  end

  def value_from(record, key)
    return unless record.respond_to?(:[])

    record[key] || record[key.to_s]
  rescue TypeError, IndexError
    nil
  end
end
