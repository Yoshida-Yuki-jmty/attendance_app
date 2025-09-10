#!/usr/bin/env bash
set -e

# 本番は dev/test を除外（ビルド時と揃える）
if [ "${RAILS_ENV}" = "production" ]; then
  bundle config set path "/usr/local/bundle"
  bundle config set without "development:test"
else
  # 開発は全部入れる（不足時のみインストール）
  bundle config set path "/usr/local/bundle"
  bundle config set without ""
  bundle check || bundle install --jobs 4 --retry 3
fi


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
