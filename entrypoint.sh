#!/bin/bash
set -e

# Railsの古いPIDファイルがあれば削除
rm -f /myapp/tmp/pids/server.pid

# CMD（rails server）を実行
exec "$@"