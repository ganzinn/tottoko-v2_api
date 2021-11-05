class User < ApplicationRecord
  # Token生成モジュール
  include UserAuth::TokenGenerate

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
    # emailからアクティブなユーザーを返す(= ログインユーザー)
    def find_by_activated(email)
      find_by(email: email, activated: true)
    end
  end

  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    User.where(email: email, activated: true).where.not(id: id).take.present?
  end
  
  # フレッシュトークンのJWT IDを登録する
  def remember(jti)
    # 【TODO】書き換えでなく、別端末からのログインも許容できるよう、ログイン単位のjtiを記憶できるようにする。
    update!(refresh_jti: jti)
  end

  # フレッシュトークンのJWT IDを削除する
  def forget
    update!(refresh_jti: nil)
  end

  # 共通のJSONレスポンス
  def response_json(payload = {})
    as_json(only: [:id, :name]).merge(payload).with_indifferent_access
  end

  private

    # email小文字化
    def downcase_email
      self.email.downcase! if email
    end

end
