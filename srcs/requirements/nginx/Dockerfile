# ============================================================================
# NGİNX DOCKERFILE - Web Sunucu + HTTPS + Reverse Proxy
# ============================================================================
#
# 📌 BU DOSYA NE YAPAR?
# Nginx web sunucusu + SSL sertifikası içeren Docker image'ı oluşturur.
# HTTPS ile güvenli bağlantı sağlar ve PHP isteklerini WordPress'e yönlendirir.
#
# 🤔 NGİNX NEDİR?
# Yüksek performanslı web sunucu:
#   - Static dosyaları serve eder (CSS, JS, resim)
#   - Reverse proxy (PHP isteklerini WordPress'e yönlendirir)
#   - Load balancer (birden fazla backend)
#   - SSL/TLS termination (HTTPS)
#
# NEDEN APACHE DEĞİL?
#   Apache: Eski, ağır, process-based
#   Nginx: Modern, hafif, event-driven ← Daha hızlı!
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoranın garson şefi:
# - Müşteri (browser) gelir
# - Garson şefi (nginx) karşılar
# - Basit istek (su, ekmek) → Direkt verir (static dosya)
# - Karmaşık istek (yemek) → Mutfağa iletir (WordPress PHP-FPM)
# - Yemeği alır, müşteriye servis eder
#
# 🔧 ÇALIŞMA PRENSİBİ:
# 1. Container başlar
# 2. Nginx SSL sertifikası oluşturulur (build zamanında)
# 3. nginx_start.sh çalışır
# 4. Nginx daemon başlar
# 5. Port 443 (HTTPS) dinler
# 6. Static dosyaları direkt serve eder
# 7. PHP dosyalarını wordpress:9000'e yönlendirir
#
# ============================================================================

# ============================================================================
# BASE IMAGE: debian:bullseye
# ============================================================================
# MariaDB ile aynı base image → Layer paylaşımı!
# ============================================================================
FROM debian:bullseye

# ============================================================================
# PAKET KURULUMU: nginx + openssl
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Nginx web sunucusu ve OpenSSL araçlarını kurar.
#
# 🤔 NEDEN BU PAKETLER?
#
# nginx:
#   - Web sunucu daemon
#   - Konfigürasyon dosyaları
#   - Module'ler (SSL, gzip, proxy vs.)
#
# openssl:
#   - SSL/TLS sertifika oluşturma
#   - Şifreleme araçları
#   - Self-signed certificate için gerekli
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoran kuruyorsun:
# - nginx = Restoran binası ve ekipmanı
# - openssl = Güvenlik sistemi (kamera, kilit)
#
# 🔧 TEKNİK DETAY:
# apt-get install -y:
#   -y: "yes" (onay isteme)
#   nginx: /etc/nginx/ altına kurulur
#   openssl: /usr/bin/openssl
#
# 💡 NEDEN OPENSSL?
# HTTPS için SSL sertifikası gerekli!
# openssl req → Sertifika oluşturma aracı
# Sonraki RUN komutunda kullanılacak.
#
# ⚠️ ALTERNATİF:
# certbot paketini kullanabilirdin (Let's Encrypt):
#   apt-get install certbot
# Ama self-signed sertifika daha basit (test ortamı için).
# ============================================================================
RUN apt-get update && apt-get install -y nginx openssl

# ============================================================================
# SSL SERTİFİKASI OLUŞTURMA
# ============================================================================
#
# 📌 BU KOMUT NE YAPAR?
# Self-signed (kendi imzalı) SSL sertifikası oluşturur.
# HTTPS bağlantısı için gerekli.
#
# 🤔 SSL/TLS/HTTPS NEDİR?
#
# HTTP: HyperText Transfer Protocol
#   - Port 80
#   - Şifresiz (plain text)
#   - Herkes okuyabilir (ortadaki adam saldırısı riski)
#
# HTTPS: HTTP Secure
#   - Port 443
#   - SSL/TLS ile şifrelenmiş
#   - Sadece browser ve sunucu okuyabilir
#
# SSL: Secure Sockets Layer (eski isim)
# TLS: Transport Layer Security (yeni isim)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Mektup gönderme:
# - HTTP = Açık kartpostal (herkes okur)
# - HTTPS = Kapalı zarf + mühür (sadece alıcı okur)
#
# 🔧 OPENSSL REQ KOMUTU:
#
# openssl req:
#   - Certificate signing request tool
#   - Sertifika oluşturma/imzalama
#
# -x509:
#   - X.509 formatında sertifika oluştur
#   - Self-signed (kendi kendine imzalı)
#   - CA (Certificate Authority) gerekmez
#
# -nodes:
#   - "no DES" (şifreleme yok)
#   - Private key şifresiz
#   - Nginx başlarken şifre sormasın
#
# -days 365:
#   - Sertifika 365 gün geçerli (1 yıl)
#   - Sonra yenilenmeli
#   - Production'da daha uzun (Let's Encrypt 90 gün)
#
# -newkey rsa:2048:
#   - Yeni RSA private key oluştur
#   - 2048 bit (güvenli uzunluk)
#   - 1024 bit zayıf, 4096 bit yavaş
#
# -keyout /etc/ssl/private/nginx-selfsigned.key:
#   - Private key'i buraya kaydet
#   - GİZLİ! Kimseyle paylaşma!
#   - Nginx HTTPS için kullanır
#
# -out /etc/ssl/certs/nginx-selfsigned.crt:
#   - Certificate (public key) buraya kaydet
#   - Herkesle paylaşılabilir
#   - Browser bu dosyayı doğrular
#
# -subj "/C=TR/ST=Kocaeli/L=Kocaeli/O=42/OU=42/CN=egermen.42.fr":
#   - Subject (sertifika bilgileri)
#   - C: Country (Ülke) → TR (Türkiye)
#   - ST: State (Eyalet/İl) → Kocaeli
#   - L: Locality (Şehir) → Kocaeli
#   - O: Organization (Kurum) → 42
#   - OU: Organizational Unit (Birim) → 42
#   - CN: Common Name (Domain) → egermen.42.fr ← ÇOK ÖNEMLİ!
#
# ☕ COMMON NAME (CN):
# Browser'ın kontrol ettiği alan adı!
#
# Kullanıcı: https://egermen.42.fr
# Sertifika CN: egermen.42.fr
# → Eşleşme var! ✅
#
# Eğer CN farklı olsaydı:
# Kullanıcı: https://egermen.42.fr
# Sertifika CN: example.com
# → Eşleşme yok! ❌ Browser uyarı verir!
#
# 💡 SELF-SIGNED vs REAL CERTIFICATE:
#
# Self-Signed (Bizimki):
#   ✅ Ücretsiz
#   ✅ Kolay oluşturulur
#   ✅ Test ortamı için ideal
#   ❌ Browser uyarı verir ("güvenilir değil")
#   ❌ CA tarafından imzalanmamış
#
# Real Certificate (Let's Encrypt):
#   ✅ Browser kabul eder
#   ✅ Ücretsiz (Let's Encrypt)
#   ✅ Production için gerekli
#   ❌ Domain doğrulama gerekir
#   ❌ 90 günde bir yenilenmeli (otomatik yapılabilir)
#
# 🔗 NGİNX İLE İLİŞKİ:
# nginx.conf'ta kullanılır:
#   ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
#   ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
#
# 🎯 HTTPS EL SIKIŞMASI (HANDSHAKE):
# 1. Browser: "Merhaba, HTTPS istiyorum"
# 2. Nginx: "İşte sertifikam (nginx-selfsigned.crt)"
# 3. Browser: "Kontrol ediyorum... Self-signed, uyarı vereceğim"
# 4. Kullanıcı: "Devam et" der
# 5. Browser + Nginx: Şifreleme anahtarını belirler
# 6. Şifreli iletişim başlar!
#
# ⚠️ GÜVENLİK NOTLARI:
# Private key (.key) ÇOK ÖNEMLİ!
# - Kimseyle paylaşma
# - GitHub'a pushlama
# - İzinleri 600 olmalı (sadece root okur)
#
# Dockerfile'da sorun yok çünkü:
# - Container izole
# - Dışarıdan erişim yok
# - Volume mount edilmiyor
# ============================================================================
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=TR/ST=Kocaeli/L=Kocaeli/O=42/OU=42/CN=egermen.42.fr"

# ============================================================================
# NGİNX YAPILANDIRMA DOSYASI KOPYALAMA
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Kendi nginx ayar dosyamızı container'a kopyalar.
#
# 🤔 NEDEN CUSTOM CONFIG?
# Default nginx.conf:
#   - HTTP only (port 80)
#   - HTTPS yok
#   - PHP desteği yok
#   - Static dosya server olarak çalışır
#
# Bizim nginx.conf:
#   - HTTPS (port 443)
#   - SSL ayarları
#   - PHP-FPM integration (fastcgi_pass)
#   - WordPress için optimize edilmiş
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoran menüsü:
# - Default menu = Standart yemekler
# - Custom menu = Özel tarifler, ek hizmetler
#
# 🔧 DOSYA YERLEŞİMİ:
# Kaynak: ./conf/nginx.conf (build context)
# Hedef: /etc/nginx/nginx.conf (container)
#
# /etc/nginx/:
#   - nginx.conf ← Ana config dosyası
#   - sites-available/ ← Mevcut siteler
#   - sites-enabled/ ← Aktif siteler
#   - conf.d/ ← Ek config dosyaları
#
# 💡 NEDEN /etc/nginx/nginx.conf?
# nginx daemon bu dosyayı otomatik okur.
# Başka yerde olsa --conf parametresi gerekir.
#
# 🔗 İÇİNDE NELER VAR?
# - listen 443 ssl (HTTPS portu)
# - ssl_certificate (sertifika yolu)
# - server_name egermen.42.fr (domain)
# - root /var/www/html (WordPress dosyaları)
# - location ~ \.php$ (PHP yönlendirmesi)
# - fastcgi_pass wordpress:9000 (PHP-FPM bağlantısı)
#
# ⚠️ OVERRIDE UYARISI:
# /etc/nginx/nginx.conf üzerine yazıyoruz!
# Default ayarlar kaybolur.
# Sorun değil, bizim ayarlar daha iyi. 😊
# ============================================================================
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

# ============================================================================
# BAŞLATMA SCRİPTİ KOPYALAMA
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# nginx_start.sh scriptini container'a kopyalar.
#
# 🤔 BU SCRIPT NE YAPAR?
# Açıkçası çok az şey! 😊
# Sadece "Nginx başlatılıyor" yazdırıp exec "$@" çağırır.
#
# NEDEN VAR O ZAMAN?
# - Gelecekte ek kurulum adımları eklenebilir
# - Log kontrolü yapılabilir
# - Healthcheck eklenebilir
# - Tutarlılık (MariaDB ve WordPress'te de var)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Açılış prosedürü:
# - MariaDB: Karmaşık (DB kurulumu, kullanıcı oluşturma)
# - WordPress: Orta (WP kurulumu, config oluşturma)
# - Nginx: Basit (zaten hazır, direkt başlat)
#
# 🔧 SCRIPT İÇERİĞİ:
# #!/bin/bash
# set -e
# echo "NGINX başlatılıyor..."
# exec "$@"
#
# set -e: Hata olursa dur
# exec "$@": CMD'yi çalıştır
#
# 💡 MİNİMAL AMA TUTARLI:
# Üç servis de aynı pattern:
#   ENTRYPOINT ["/xxx-start.sh"]
#   CMD ["daemon"]
# Kod okunabilirliği için iyi!
# ============================================================================
COPY ./tools/nginx_start.sh /

# ============================================================================
# SCRIPT İZNİ VERME
# ============================================================================
# Çalıştırılabilir yap.
# ============================================================================
RUN chmod +x /nginx_start.sh

# ============================================================================
# PORT EXPOSE: 443 (HTTPS)
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Container'ın 443 portunun kullanıldığını belirtir.
# Dokümantasyon amaçlı.
#
# 🤔 NEDEN 443?
# HTTPS'in standart portu.
# HTTP = 80, HTTPS = 443
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Bina kat numarası:
# - 1. kat = Muhasebe (HTTP, port 80)
# - 4. kat = Güvenli toplantı odası (HTTPS, port 443)
#
# 🔧 docker-compose.yml İLE İLİŞKİ:
# expose: - 443 → Dokümantasyon
# ports: "443:443" → Gerçek mapping
#
# Host → 443 → Container 443
# Browser https://egermen.42.fr → Host:443 → Nginx
#
# 💡 EXPOSE ZORUNLU DEĞİL!
# Teknik olarak expose olmasa da ports çalışır.
# Ama best practice: Dokümante et!
#
# ⚠️ DIŞ DÜNYAYA AÇIK:
# Sadece Nginx'in portu dış dünyaya açık!
# MariaDB: expose only (internal)
# WordPress: expose only (internal)
# Nginx: ports (external) ← Tek giriş noktası!
#
# Güvenlik katmanı:
# Dış dünya → Nginx → WordPress → MariaDB
# ============================================================================
EXPOSE 443

# ============================================================================
# ENTRYPOINT: Başlatma Script'i
# ============================================================================
# Container başladığında nginx_start.sh çalışır.
# ============================================================================
ENTRYPOINT ["/nginx_start.sh"]

# ============================================================================
# CMD: Nginx Daemon
# ============================================================================
#
# 📌 BU KOMUT NE YAPAR?
# Nginx daemon'ını foreground modda başlatır.
#
# 🤔 PARAMETRELER:
#
# nginx:
#   - Nginx daemon
#   - /etc/nginx/nginx.conf dosyasını okur
#   - Port 443'ü dinler
#
# -g:
#   - Global directive (komut satırından ayar)
#   - Config dosyasını override eder
#
# "daemon off;":
#   - Daemon modunu kapat
#   - Foreground'da çalış
#   - Container açık kalsın
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Gece bekçisi:
# - daemon on = Bekçi gece devriyesi yapar, ofise dönmez
# - daemon off = Bekçi ofiste oturur, görev başında kalır
#
# 🔧 NEDEN "daemon off"?
#
# Default nginx davranışı:
#   nginx → Master process (PID 1)
#     ├─ Worker processes (arka planda)
#   Master process hemen çıkar!
#   Container: "Ana process bitti" → Kapanır!
#
# "daemon off" ile:
#   nginx → Master process (PID 1, foreground)
#     ├─ Worker processes
#   Master process çalışmaya devam eder
#   Container açık kalır!
#
# 💡 ALTERNATİF KULLANIM:
# nginx.conf'ta:
#   daemon off;
# CMD:
#   CMD ["nginx"]
#
# Ama command line daha açık:
#   CMD ["nginx", "-g", "daemon off;"]
#
# 🔗 DOCKER SİNYALLERİ:
# docker stop:
#   SIGTERM → nginx master process
#   → Graceful shutdown:
#     1. Yeni bağlantıları reddet
#     2. Mevcut istekleri bitir
#     3. Worker'ları kapat
#     4. Master'ı kapat
#   10 saniye timeout yeter!
#
# ⚠️ FOREGROUND ZORUNLU!
# Docker container'lar foreground process gerektirir.
# Daemon mode → Container hemen kapanır!
# ============================================================================
CMD ["nginx", "-g", "daemon off;"]

# ============================================================================
# ÖZET - NGİNX DOCKERFILE'DAN ÖĞRENDİKLERİMİZ
# ============================================================================
#
# 1. BASE IMAGE: debian:bullseye (MariaDB ile aynı)
# 2. PAKET KURULUMU: nginx + openssl
# 3. SSL SERTİFİKASI: openssl req -x509 (self-signed)
# 4. CONFIG KOPYALAMA: nginx.conf
# 5. SCRIPT KOPYALAMA: nginx_start.sh
# 6. İZİN VERME: chmod +x
# 7. PORT: 443 (HTTPS)
# 8. ENTRYPOINT: Başlatma scripti
# 9. CMD: nginx -g "daemon off;" (foreground)
#
# BUILD SÜRECİ:
# 1. Debian indir
# 2. Nginx + OpenSSL kur
# 3. SSL sertifikası oluştur
# 4. Config dosyasını kopyala
# 5. Script kopyala
# 6. İzinleri ayarla
# 7. Image hazır!
#
# ÇALIŞMA SÜRECİ:
# 1. Container başlar
# 2. ENTRYPOINT: nginx_start.sh
# 3. exec "$@" → CMD
# 4. nginx -g "daemon off;"
# 5. Port 443 dinlemeye başlar
# 6. HTTPS isteklerini kabul eder
# 7. Static dosyalar → Direkt serve
# 8. PHP dosyalar → wordpress:9000'e yönlendir
#
# GÜVENLİK:
# - HTTPS only (HTTP yok)
# - SSL/TLS şifreleme
# - Self-signed sertifika (test için)
# - Tek dış giriş noktası (reverse proxy)
#
# PERFORMANS:
# - Static dosya caching
# - Event-driven architecture
# - Async I/O
# - Hafif ve hızlı!
#
# ============================================================================
