#!/usr/bin/env bash
set -e

# 初回起動時等に tmp/pids が残っていると Puma が起動しない
rm -f tmp/pids/server.pid || true

# 本番時のみ：マイグレーション＆アセット
if [ "${RAILS_ENV}" = "production" ]; then
  bundle exec rails db:migrate
  bundle exec rails assets:precompile
fi

# CMD 実行
exec "$@"
