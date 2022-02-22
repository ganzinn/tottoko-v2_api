#!/bin/sh
set -e

# DBセットアップ
SQL="
  create user '$MYSQL_USER'@'%' identified by '$MYSQL_PASSWORD';
  grant select, insert, update, delete, create, drop, references, index, alter, trigger on *.* to '$MYSQL_USER'@'%';
"
echo "$SQL" | mysql -u $MYSQL_ROOT -p$MYSQL_ROOT_PASSWORD -h db
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rails db:drop # DB初期化
rails db:create
rails db:migrate

exec "$@"
