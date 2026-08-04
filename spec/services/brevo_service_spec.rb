require 'rails_helper'

RSpec.describe BrevoService do
  let(:mock_api) { instance_double(Brevo::TransactionalEmailsApi) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('BREVO_API_KEY').and_return('fake_key')
  end

  subject { described_class.new }

  before do
    allow(Brevo::TransactionalEmailsApi).to receive(:new).and_return(mock_api)
  end

  it "omits empty cc, bcc, attachment, and reply_to from SendSmtpEmail payload" do
    expect(mock_api).to receive(:send_transac_email) do |email|
      hash = email.to_hash
      expect(hash).not_to have_key(:cc)
      expect(hash).not_to have_key(:bcc)
      expect(hash).not_to have_key(:attachment)
      expect(hash).not_to have_key(:replyTo)
      expect(hash[:to]).to eq([{ email: "user@example.com" }])
      expect(hash[:subject]).to eq("Welcome")
      expect(hash[:htmlContent]).to eq("<p>Hello</p>")
      expect(hash[:textContent]).to eq("Hello")
    end

    subject.send_email(
      to: [{ "email" => "user@example.com" }],
      subject: "Welcome",
      html_content: "<p>Hello</p>",
      text_content: "Hello",
      sender: { "email" => "noreply@noracapital.com.ng", "name" => "NoraCapital" },
      attachments: [],
      cc: [],
      bcc: [],
      reply_to: nil
    )
  end
end
