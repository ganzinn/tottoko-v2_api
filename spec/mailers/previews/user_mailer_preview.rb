# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3001/rails/mailers/user_mailer/account_activation
  def account_activation
    user = User.last
    lifetime = 1.hours
    token = user.encode_access_token({lifetime: lifetime, obj: :account_activation}).token
    UserMailer.account_activation(user, lifetime, token)
  end

end
