class ApplicationController < ActionController::API
  include ActionController::Cookies

  private

  def access_token_validate
    access_token = request.headers["Authorization"]&.split&.last
    @access_token_ins = UserAuth::AccessToken.new(access_token, method(:response_4XX))
    @access_token_ins.decode_token_validate
  end

  def authorize_user
    @access_token_ins.token_user
  end

  def response_4XX(status, code: nil, messages: nil )
    render(status: status, json: { success: false, code: code, messages: messages })
  end

  def response_500(code: :internal_server_error, messages: {base: ["サーバー内部エラー"]} )
    render(status: 500, json: { success: false, code: code, messages: messages })
  end
end
