class BrevoService
  DEFAULT_SENDER_EMAIL = "noreply@noracapital.com.ng"
  DEFAULT_SENDER_NAME = "NoraCapital"

  def initialize(api_client: Brevo::ApiClient.default)
    raise "BREVO_API_KEY is required to send email through Brevo" if ENV["BREVO_API_KEY"].blank?

    @api = Brevo::TransactionalEmailsApi.new(api_client)
  end

  def send_email(to:, subject:, html_content:, text_content:, sender:, attachments: [], cc: [], bcc: [], reply_to: nil)
    email_params = {
      sender: build_sender(sender),
      to: build_recipients(to),
      subject: subject.to_s,
      html_content: html_content.to_s,
      text_content: text_content.to_s
    }

    cc_list = build_recipients(cc)
    email_params[:cc] = cc_list if cc_list.present?

    bcc_list = build_recipients(bcc)
    email_params[:bcc] = bcc_list if bcc_list.present?

    reply_to_obj = build_reply_to(reply_to)
    email_params[:reply_to] = reply_to_obj if reply_to_obj.present?

    att_list = build_attachments(attachments)
    email_params[:attachment] = att_list if att_list.present?

    email = Brevo::SendSmtpEmail.new(**email_params)

    @api.send_transac_email(email)
  end

  private

  def build_sender(sender)
    sender ||= {}

    email = sender[:email].presence || sender["email"].presence || ENV["BREVO_SENDER_EMAIL"].presence || DEFAULT_SENDER_EMAIL
    name  = sender[:name].presence || sender["name"].presence || ENV["BREVO_SENDER_NAME"].presence || DEFAULT_SENDER_NAME

    Brevo::SendSmtpEmailSender.new(email: email, name: name)
  end

  def build_recipients(recipients)
    list = Array(recipients).filter_map do |recipient|
      next if recipient.blank?

      email = value_from(recipient, :email)
      email ||= recipient.to_s
      next if email.blank?

      name = value_from(recipient, :name)
      opts = { email: email }
      opts[:name] = name if name.present?

      Brevo::SendSmtpEmailTo.new(**opts)
    end

    list.presence
  end

  def build_reply_to(reply_to)
    return nil if reply_to.blank?

    email = value_from(reply_to, :email)
    email ||= reply_to.to_s
    return nil if email.blank?

    name = value_from(reply_to, :name)
    opts = { email: email }
    opts[:name] = name if name.present?

    Brevo::SendSmtpEmailReplyTo.new(**opts)
  end

  def build_attachments(attachments)
    list = Array(attachments).filter_map do |attachment|
      next if attachment.blank?

      name = attachment[:name] || attachment["name"]
      content = attachment[:content] || attachment["content"]
      next if name.blank? || content.blank?

      Brevo::SendSmtpEmailAttachment.new(name: name, content: content)
    end

    list.presence
  end

  def value_from(record, key)
    return unless record.respond_to?(:[])

    record[key] || record[key.to_s]
  rescue TypeError, IndexError
    nil
  end
end
