#!/usr/bin/env bash
set -e

# 初回起動時等に tmp/pids が残っていると Puma が起動しない
rm -f tmp/pids/server.pid || true

# 開発・本番で、フラグで db:prepare を自動実行
if [ "${AUTO_DB_PREPARE}" = "1" ]; then
  bundle exec rails db:prepare
fi

# 本番時のみ：マイグレーション＆アセット
if [ "${RAILS_ENV}" = "production" ]; then
  bundle exec rails db:prepare
  bundle exec rails assets:precompile
fi

# CMD 実行
exec "$@"
