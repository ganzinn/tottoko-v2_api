class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(user)
    @user = user
    @encode_token_ins = UserAuth::ActivateToken.encode(@user.id)
    @lifetime_text = period_format(@encode_token_ins.lifetime)
    mail to: @user.email, subject:"【tottoko】アカウント有効化のご案内"
  end


  def password_reset(user)
    @user = user
    @encode_token_ins = UserAuth::PasswordResetToken.encode(@user.id)
    @generate_time_text = I18n.l(@encode_token_ins.generate_time)
    @lifetime_text = period_format(@encode_token_ins.lifetime)
    mail to: @user.email, subject:"【tottoko】パスワード再設定のご案内"
  end

  def email_change(user)
    @user = user
    @encode_token_ins = UserAuth::EmailChangeToken.encode(@user.id, @user.email)
    @generate_time_text = I18n.l(@encode_token_ins.generate_time)
    @lifetime_text = period_format(@encode_token_ins.lifetime)
    mail to: @user.email, subject:"【tottoko】メールアドレス変更のご案内"
  end

  private

  # lifetimeの日本語テキストを返す
  def period_format(period)
    time, period_name = period.inspect.sub(/s\z/, "").split
    time + I18n.t("datetime.periods.#{period_name}", default: "")
  end
end
