#!/bin/bash
# ============================================================================
# NGİNX BAŞLATMA SCRİPTİ
# Nginx'i güvenli şekilde başlatır
# ============================================================================
#
# 📌 BU DOSYA NE YAPAR?
# Script hatalarını yakalar ve Nginx'i başlatır.
#
# 🤔 NEDEN?
# - set -e: Hata varsa dur (güvenlik)
# - exec "$@": CMD komutunu çalıştır
#
# ============================================================================

# ============================================================================
# SET -E: HATA YAKALA
# ============================================================================
# set -e: Herhangi bir hata olursa script'i durdur
# Exit on error (güvenlik önlemi)
#
# ☕ Analoji:
# Restoran açılışı:
# - "Herhangi bir sorun varsa açılışı iptal et!"
# - Elektrik yok → Açma ❌
# - Mutfak hazır değil → Açma ❌
# - Her şey tamam → Aç ✅
# ============================================================================
set -e

# ============================================================================
# BAŞLATMA MESAJI
# ============================================================================
# echo: Ekrana mesaj yaz
# "NGINX başlatılıyor...": Kullanıcıya bilgi ver
#
# Container loglarında görünür:
# docker logs nginx → "NGINX başlatılıyor..."
# ============================================================================
echo "NGINX başlatılıyor..."

# ============================================================================
# EXEC "$@": CMD KOMUTUNU ÇALIŞTIR
# ============================================================================
# exec: Mevcut process'i değiştir (PID korunur)
# "$@": Dockerfile CMD'den gelen argümanlar
#
# Dockerfile'da:
#   CMD ["nginx", "-g", "daemon off;"]
# Bu script çalışınca:
#   exec nginx -g "daemon off;"
#
# EXEC NEDİR?
# Normal çalıştırma:
#   PID 1: nginx_start.sh
#     └─ PID 7: nginx (child process)
#
# exec ile:
#   PID 1: nginx (script yerine geçti!)
#
# ☕ Analoji:
# - Normal: Müdür yardımcısı müdürü çağırır (2 kişi)
# - exec: Yardımcı işi devreder, gider (1 kişi)
# PID 1 önemli çünkü Docker signals (SIGTERM) buraya gider!
#
# 🔧 TEKNİK DETAY:
# exec sayesinde:
# - docker stop nginx → SIGTERM direkt nginx process'ine gider
# - Graceful shutdown mümkün olur
# - Zombie process oluşmaz
#
# DİĞER DOSYALARLA İLİŞKİ:
# - Dockerfile ENTRYPOINT: ./nginx_start.sh
# - Dockerfile CMD: ["nginx", "-g", "daemon off;"]
# - nginx.conf: Ayarları okur
# - SSL sertifikaları: /etc/ssl/certs/ ve /etc/ssl/private/
# ============================================================================
exec "$@"

# ============================================================================
# ÖZET - NGINX_START.SH'TAN ÖĞRENDİKLERİMİZ
# ============================================================================
#
# 1. #!/bin/bash: Bash script
# 2. set -e: Hata varsa dur (güvenlik)
# 3. echo: Başlatma mesajı
# 4. exec "$@": CMD komutunu PID 1 olarak çalıştır
#
# ENTRYPOINT vs CMD:
# - ENTRYPOINT: nginx_start.sh (hazırlık script'i)
# - CMD: nginx -g "daemon off;" (asıl program)
# - exec: CMD'yi PID 1 yap (signal handling için)
#
# İŞ AKIŞI:
# 1. Container başlar
# 2. ENTRYPOINT çalışır (nginx_start.sh)
# 3. set -e → Hata kontrolü aktif
# 4. echo → "NGINX başlatılıyor..." (log)
# 5. exec "$@" → nginx -g "daemon off;" (PID 1)
# 6. Nginx port 443'te dinler
# 7. İstekleri işler
# 8. docker stop → SIGTERM → Nginx graceful shutdown
#
# GÜVENLİK:
# - set -e: Script hataları yakalar
# - exec: Signal handling doğru çalışır
# - Zombie process önlenir
# ============================================================================
