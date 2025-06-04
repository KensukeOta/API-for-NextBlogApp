#!/bin/bash
set -e

# Railsの古いPIDファイルがあれば削除
rm -f /backend/tmp/pids/server.pid

# CMD（rails server）を実行
exec "$@"