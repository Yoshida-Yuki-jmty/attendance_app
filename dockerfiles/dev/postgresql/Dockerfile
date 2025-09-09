FROM postgres:15

# 任意：タイムゾーンなど。必要なければ削除可
ENV TZ=Asia/Tokyo

# 初期化 SQL や設定を使いたい場合はここでコピー
# 例）DB 作成や拡張を自動化するなら:
# COPY ./initdb/*.sql /docker-entrypoint-initdb.d/
# ※ /docker-entrypoint-initdb.d/*.sql は初回起動時のみ実行されます
