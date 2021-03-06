class User < ApplicationRecord
  include Rails.application.routes.url_helpers

  serialize :refresh_jti, Hash

  has_many :families, dependent: :destroy
  has_many :creators, through: :families
  has_many :comments
  has_many :likes
  has_one_attached :avatar

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

  def remember_jti!(encode_refresh_token_ins)
    new_refresh_jti = encode_refresh_token_ins.payload[:jti]
    exp = encode_refresh_token_ins.payload[:exp]
    now = DateTime.now.to_i
    filter_refresh_jti = self.refresh_jti.filter{|_, value| value > now }
    filter_refresh_jti.store(new_refresh_jti, exp)
    self.update!(refresh_jti: filter_refresh_jti)
  end

  def forget
    self.update(refresh_jti: nil)
  end

  def activate
    self.update(activated: true) 
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def send_email_change_email
    UserMailer.email_change(self).deliver_now
  end

  def original_avatar_url
    return nil unless avatar.attached?
    url_for(avatar)
  end

  def avatar_url
    return nil unless avatar.attached?
    url_for(avatar.variant(resize:'100x100').processed)
  end

  private

  def downcase_email
    self.email.downcase! if self.email
  end

end
