class ApplicationController < ActionController::API
  include ActionController::Cookies
  include UserAuth::UserAuthenticate

  private

    def response_401(msg = "認証情報が不正です。")
      render status: 401, json: { success: false, error: msg }
    end

    def response_500(msg = "サーバー内でエラーが発生しました。")
      render status: 500, json: { success: false, error: msg }
    end

end
