require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.

    # Railsアプリのタイムゾーン（default 'UTC'）
    config.time_zone = ENV.fetch("TZ") { 'Asia/Tokyo' }

    # データベースの読み書きに使用するタイムゾーン
    # AWS RDS(MySQLのデフォルトタイムゾーンが:utcのため合わせる)
    config.active_record.default_timezone = :utc

    # i18nで使用するデフォルトのロケールファイルの指定（default :en）
    config.i18n.default_locale = :ja

    # $LOAD_PATHにautoload pathを追加しない（Zeitwerk有効時false推奨（以下））
    # https://guides.rubyonrails.org/v6.1/configuring.html#rails-general-configuration
    config.add_autoload_paths_to_load_path = false

    # Coolies処理のmiddleware追加
    config.middleware.use ActionDispatch::Cookies

    # Cookiesのsame-site属性(Cookieの送信を制御する属性)の設定（Rails6.1〜）
    # Heroku等のeffective TLDなドメインへのデプロイ時は「none」(小文字での指定)に設定する必要あり。
    config.action_dispatch.cookies_same_site_protection = ENV["COOKIES_SAME_SITE"].to_sym

    # テストフレームワークをRSpecに変更し、自動生成されるファイルを制御
    config.generators do |g|
      g.test_framework :rspec, 
            view_specs: false, 
            helper_specs: false, 
            controller_specs: false, 
            routing_specs: false
    end

    config.api_only = true

    # image url 出力用設定
    Rails.application.routes.default_url_options = { host: ENV['API_URL']}

  end
end
