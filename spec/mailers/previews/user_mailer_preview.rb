# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3001/rails/mailers/user_mailer/account_activation
  def account_activation
    user = User.last
    UserMailer.account_activation(user)
  end

  # Preview this email at http://localhost:3001/rails/mailers/user_mailer/password_reset_activation
  def password_reset
    user = User.last
    UserMailer.password_reset(user)
  end

end
