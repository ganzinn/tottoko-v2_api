class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(user)
    @user = user
    @activate_token_ins = UserAuth::ActivateToken.encode(@user.id)
    mail to: @user.email, subject:"tottokoアカウントの有効化"
  end
end
