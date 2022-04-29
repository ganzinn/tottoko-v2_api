#!/bin/sh
set -e

# DBリセット／セットアップ
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rails db:drop # DB初期化
rails db:create
rails db:migrate

exec "$@"
