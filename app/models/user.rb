class User < ApplicationRecord
  # gem bcryptメソッド
  has_secure_password

  # validates
  validates :name,  presence: true,     # 必須入力（nil, 空白文字のチェック）
                    length: {           # 文字数
                      maximum: 30,      # 最大文字数
                      allow_blank: true # nil, 空白文字の場合スキップ（presenceとの重複回避のため）
                    }
  
  VALID_PASSWORD_REGEX = /\A[\w\-]*\z/.freeze
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
  
end
