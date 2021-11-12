class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(user, lifetime, token)
    @user = user
    @token = token
    @lifetime_text = lifetime_text(lifetime)
    mail to: @user.email, subject:"tottokoアカウントの有効化"
  end

  private

    # lifetimeの日本語テキストを返す
    def lifetime_text(lifetime)
      time, period = lifetime.inspect.sub(/s\z/, "").split
      time + I18n.t("datetime.periods.#{period}", default: "")
    end

end
