# AWS SES
creds = Aws::Credentials.new(
  Rails.application.credentials.aws[:access_key_id],
  Rails.application.credentials.aws[:secret_access_key]
)
Aws::Rails.add_action_mailer_delivery_method(
  :ses,
  credentials: creds,
  region: Rails.application.credentials.dig(:aws, :SES, :region)
)
