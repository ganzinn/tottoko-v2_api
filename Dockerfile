FROM ruby:2.7.4-alpine3.14

# 環境変数を定義（Imageから参照可）
# ここで設定する環境変数は環境に依存しない固定値のみ
# Rails ENV["TZ"] => Asia/Tokyo
ENV HOME=/app \ 
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo \
    # credentials編集時に使用
    EDITOR=vim

# Dockerfile内で指定した命令を実行する ...RUN, COPY, ADD, ENTORYPOINT, CMD
# 作業ディレクトリを定義
WORKDIR ${HOME}

# ホスト側(PC)のファイルをコンテナにコピー
# COPY コピー元（ホスト） コピー先（コンテナ）
# コピー元（ホスト） ...Dockerfileがあるディレクトリ以下を指定(api) ../ NG
# コピー先（コンテナ） ...絶対パス or 相対パス
COPY Gemfile* ./

# 以下コマンドはベースのdockerから引き継いだバージョンから変更となるため実施しない
#     # apk update : パッケージの最新リストを取得
# RUN apk update && \
#     # apk upgrade : インストールパッケージを最新のものに
#     apk upgrade

    # apk add : パッケージのインストールを実行
    # --no-cache : パッケージをキャッシュしない（Dockerイメージを軽量化）
RUN apk add --no-cache \
            tzdata \
            mysql-dev \
            mysql-client \
            # pryで使用
            less \
            # credentials編集時に使用
            vim \
            # 画像サイズ変更で使用
            imagemagick \
            && \
    #  --virtual 名前（任意） : 削除用パッケージの名前付け
    apk add --virtual build-dependencies --no-cache \
            alpine-sdk \
            && \
    # bundlerによるGemのインストールコマンド
    # --jobs=4 : 並列インストールによるGemインストールの高速化
    # --retry=3 : ネットワークエラーによるリトライ回数
    bundle install --jobs=4  --retry=3 && \
    # Gemのインストールにのみ必要なパッケージを削除（Dockerイメージを軽量化）
    apk del build-dependencies

# . ...Dockerfileがあるディレクトリ全てのファイル（サブディレクトリも含む）
COPY . .
# 起動用シェルに実行権限付与
COPY entrypoint.sh entrypoint_setup.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/entrypoint_setup.sh
# コンテナ内で実行したいコマンドを定義
# ...ENTRYPOINT ["entrypoint.sh"] 本コマンド実行前に実施したい事前処理をシェルに記載
ENTRYPOINT ["entrypoint.sh"]
# -b ...バインド。プロセスを指定したip(0.0.0.0)アドレスに紐付け（バインド）する
# 本番環境ではproductionモードでの起動に上書き
CMD ["rails", "server", "-b", "0.0.0.0"]
