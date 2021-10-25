class User < ApplicationRecord
  # バリデーション前処理
  before_validation :downcase_email

  # gem bcryptメソッド
  has_secure_password

  # validates
  validates :name,  presence: true,     # 必須入力（nil, 空白文字のチェック）
                    length: {           # 文字数
                      maximum: 30,      # 最大文字数
                      allow_blank: true # nil, 空白文字の場合スキップ（presenceとの重複回避のため）
                    }
  
  validates :email, presence: true,
                    email: {            # カスタムバリデーション呼び出し
                      allow_blank: true
                    }

  VALID_PASSWORD_REGEX = Regexp.new( '\A[a-zA-Z0-9\-_]*\z' )
  validates :password,  presence: true,               # 空白文字を許容しない（allow_nillによりnilは許容される）
                        length: { 
                          minimum: 8,                 # 最小文字数
                          allow_blank: true
                        },    
                        format: {                     # 書式チェック
                          with: VALID_PASSWORD_REGEX, # 0文字以上のa-zA-Z0-9_-の文字
                          message: :format_invalid
                        },
                        allow_nil: true               # nilを許容（新規登録時はbcryptの必須入力が有効となるため、更新時のための設定）
  
  # methods -------------------------------------------------------------------
  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    User.where(email: email, activated: true).where.not(id: id).take.present?
  end
  
  private

    # email小文字化
    def downcase_email
      self.email.downcase! if email
    end

end
