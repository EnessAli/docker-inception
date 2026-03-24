#!/bin/bash

# Shebang: bu script bash ile çalıştırılır
# set -e : herhangi bir komut hata dönerse script hemen sonlanır (fail-fast)
set -e

echo "NGINX başlatılıyor..."

# exec "$@" : script'e verilen argümanları exec ile çalıştır
# - exec mevcut shell processini yeni process ile değiştirir (PID 1 korunur)
# - "$@" -> verilen tüm argümanları ayrı ayrı koruyarak geçirir
exec "$@"
