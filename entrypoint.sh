#!/bin/sh
set -e
rm -f /app/tmp/pids/server.pid

# 本番DB初期化用(初回のみ)
# RAILS_ENV=production bin/rails db:create
# RAILS_ENV=production bin/rails db:migrate

exec "$@"
