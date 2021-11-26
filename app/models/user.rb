class User < ApplicationRecord

  # バリデーション前処理
  before_validation :downcase_email

  # gem bcryptメソッド
  has_secure_password

  # validates
  validates :name,
    presence: true,     # nil、空文字、空白文字のチェック
    length: {           # 文字数
      maximum: 30,      # 最大文字数
      allow_blank: true # nil、空文字、空白文字の場合スキップ
                        # 空白文字30文字超えの場合を考慮（presenceとの重複回避のため）
    }
  
  validates :email,
    presence: true,
    email: {            # カスタムバリデーション呼び出し
      allow_blank: true
    }

  VALID_PASSWORD_REGEX = Regexp.new( '\A[a-zA-Z0-9_-]*\z' )
  validates :password,
    presence: true,               # bcryptによるnilチェックと重複するため、本指定では空白のチェックを考慮。
    length: { 
      minimum: 8,                 # 最小文字数
      allow_blank: true           # 空白文字8文字未満の場合を考慮（presenceとの重複回避のため）
    },
    format: {                     # 書式チェック
      with: VALID_PASSWORD_REGEX, # 0文字以上のa-zA-Z0-9_-の文字
      message: :format_invalid,
      allow_blank: true           # 空白文字の場合を考慮（presenceとの重複回避のため）
    },
    allow_nil: true               # bcryptによるnilチェックの重複エラーメッセージの回避と、更新時のための考慮。
                                  # ただし、本設定に関係なくpassword_confirmationは新規登録時でもnilを許容するため、
                                  # フロント側では必須入力とする。
                                  # ※ APIとしてはpassword_confirmationはnil許容でも問題ないという考え。
  
  # methods -------------------------------------------------------------------
  class << self
    def find_by_activated(email)
      find_by(email: email, activated: true)
    end
  end

  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    User.where(email: email, activated: true).where.not(id: self.id).take.present?
  end

  def remember_jti!(refresh_jti)
    self.update!(refresh_jti: refresh_jti)
  end

  def forget
    self.update_attribute(:refresh_jti, nil)
  end

  # 共通のJSONレスポンス
  def response_json(payload = {})
    self.as_json(only: [:name, :email]).merge(payload).with_indifferent_access
  end

  # アカウントアクティベイト用トークン生成＆メール送付
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def activate
    self.update(activated: true) 
  end

  private

  def downcase_email
    self.email.downcase! if self.email
  end

end
