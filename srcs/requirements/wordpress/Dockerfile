# ============================================================================
# WORDPRESS DOCKERFILE
# PHP-FPM + WordPress + WP-CLI Container İmajı
# ============================================================================
#
# 📌 BU CONTAINER NE İŞE YARAR?
# - PHP-FPM çalıştırır (WordPress için)
# - WordPress dosyalarını barındırır
# - WP-CLI ile WordPress kurulumunu yapar
#
# ☕ RESTORAN ANALOJİSİ:
# - nginx: Garson (static servis eder, PHP siparişlerini iletir)
# - wordpress (PHP-FPM): Mutfak (PHP kod çalıştırır)
# - mariadb: Depo (veriyi saklar)
#
# Müşteri → Garson → "Yemek yap" → Mutfak → "Malzeme ver" → Depo
# Browser → Nginx → "PHP çalıştır" → WordPress → "Veri ver" → MariaDB
# ============================================================================

# Base image: Debian Bullseye (11)
# Diğer container'larla aynı base (tutarlılık)
FROM debian:bullseye

# ============================================================================
# PHP-FPM + GEREKLİ PAKETLER
# ============================================================================
# php-fpm: PHP FastCGI Process Manager
#   - Nginx ile iletişim kurar (FastCGI protokolü)
#   - PHP kodlarını çalıştırır
#   - Port 9000'de dinler
#
# php-mysql: MySQL/MariaDB extension
#   - PHP'den veritabanına bağlanmak için
#   - mysqli, PDO fonksiyonları
#
# wget: Dosya indirme aracı
#   - WP-CLI indirecek
#   - WordPress core dosyalarını indirecek (wp-cli kullanarak)
#
# 🤔 NEDEN APT-GET CLEAN YOK?
# MariaDB ve Nginx'de vardı, burada yok!
# Tutarlılık için eklenebilir ama küçük fark (birkaç MB)
# ============================================================================
RUN apt-get update && apt-get install -y php-fpm php-mysql wget 

# ============================================================================
# SAHTE SENDMAIL OLUŞTUR
# ============================================================================
# echo "#!/bin/sh\nexit 0" > /usr/sbin/sendmail:
#   Dummy sendmail script'i oluştur (hiçbir şey yapmaz)
#
# chmod +x: Çalıştırılabilir yap
#
# 🤔 NEDEN?
# WordPress email göndermek ister (kullanıcı kaydı, şifre sıfırlama)
# Sendmail yoksa → HATA!
# Sahte sendmail → WordPress mutlu (email gönderilmez ama hata vermez)
#
# ☕ Analoji:
# Restoran posta kutusu:
# - Gerçek posta servisi yok
# - Sahte kutu koy → Mektup atarlar ama kaybolur
# - Önemli: Restoran "posta kutusu yok" diye şikayet etmez!
#
# 🔧 PRODUCTION NOT:
# Gerçek projede SMTP ayarla (Gmail, SendGrid, vb.)
# ============================================================================
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/sendmail && chmod +x /usr/sbin/sendmail

# ============================================================================
# WP-CLI KURULUMU
# ============================================================================
# WP-CLI NEDİR?
# WordPress Command Line Interface
# Terminal'den WordPress yönetimi:
#   - wp-cli core download → WordPress indir
#   - wp-cli config create → wp-config.php oluştur
#   - wp-cli core install → WordPress kur
#   - wp-cli user create → Kullanıcı oluştur
#   - wp-cli plugin install → Plugin kur
#
# wget: GitHub'dan WP-CLI indir (phar dosyası)
#   https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
#
# chmod +x: Çalıştırılabilir yap
#
# mv: /usr/local/bin/wp-cli → Her yerden erişilebilir (PATH'te)
#
# ☕ Analoji:
# Restoran yönetim paneli:
# - Grafik arayüz yerine komut satırı
# - "wp-cli user create chef" → Yeni şef ekle
# - "wp-cli plugin install security" → Güvenlik sistemi kur
# - Script'lerle otomasyona uygundur!
#
# 🔧 WP-CLI KULLANIM ÖRNEKLERİ:
# wp-cli core download → /var/www/html'e WordPress indir
# wp-cli config create --dbname=wordpress_db --dbuser=wp_user
# wp-cli core install --url=egermen.42.fr --title="Blog"
# wp-cli user create john john@example.com --role=author
# ============================================================================
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli

# ============================================================================
# WORDPRESS DİZİNİ OLUŞTUR
# ============================================================================
# mkdir -p /var/www/html: WordPress dosyalarının yeri
# -p: Parent dizinleri de oluştur (/var, /var/www)
#
# DİĞER DOSYALARLA İLİŞKİ:
# - nginx.conf → root /var/www/html;
# - docker-compose.yml → wordpress_volume:/var/www/html
# - nginx container da /var/www/html görür (shared volume!)
#
# ☕ Analoji:
# İki kişi aynı dolabı kullanır:
# - Mutfak (wordpress): Yemek hazırlar, dolaba koyar
# - Garson (nginx): Dolabı açar, yemeği alır, servis eder
# Volume = Paylaşılan dolap!
# ============================================================================
RUN mkdir -p /var/www/html

# ============================================================================
# PHP-FPM KONFIG KOPYALA
# ============================================================================
# COPY ./conf/www.conf: PHP-FPM pool ayarları
# /etc/php/7.4/fpm/pool.d/: PHP-FPM pool klasörü
#
# www.conf AYARLARI:
# - listen = 0.0.0.0:9000 → Tüm IP'lerden dinle
# - pm = dynamic → Process yönetimi dinamik
# - pm.max_children = 10 → Maksimum 10 worker
#
# 🤔 NEDEN KOPYALIYORUZ?
# Varsayılan ayarlar yetersiz:
# - listen = /run/php/php7.4-fpm.sock → Unix socket (network değil!)
# - Docker network için TCP gerekli (0.0.0.0:9000)
#
# ☕ Analoji:
# Mutfak telefonu:
# - Varsayılan: İç hat (sadece binada)
# - Bizim ayar: Dış hat (diğer binalardan aranabilir)
# Nginx farklı container → Network gerekli!
# ============================================================================
COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/

# ============================================================================
# BAŞLATMA SCRİPTİNİ KOPYALA
# ============================================================================
# COPY ./tools/wordpress-start.sh /: Script'i root dizine kopyala
#
# wordpress-start.sh NE YAPAR?
# 1. Dosya izinlerini ayarla (www-data)
# 2. Secrets'ları oku (DB şifresi, WP admin bilgileri)
# 3. WordPress indir (wp-cli core download)
# 4. wp-config.php oluştur (wp-cli config create)
# 5. WordPress kur (wp-cli core install)
# 6. Kullanıcı oluştur (wp-cli user create)
# 7. PHP-FPM başlat (exec "$@")
# ============================================================================
COPY ./tools/wordpress-start.sh /

# ============================================================================
# SCRİPT İZİNLERİ
# ============================================================================
# chmod +x: Çalıştırılabilir yap
# /wordpress-start.sh: ENTRYPOINT bu script'i çalıştıracak
# ============================================================================
RUN chmod +x /wordpress-start.sh

# ============================================================================
# ÇALIŞMA DİZİNİ
# ============================================================================
# WORKDIR /var/www/html: Varsayılan klasör
# Script'ler bu dizinde çalışır
# wp-cli core download → Bu dizine indirir
# ============================================================================
WORKDIR /var/www/html

# ============================================================================
# ENTRYPOINT: BAŞLATMA SCRİPTİ
# ============================================================================
# ENTRYPOINT ["/wordpress-start.sh"]: İlk çalışan script
#
# ENTRYPOINT vs CMD:
# - ENTRYPOINT: Sabit (değişmez)
# - CMD: Varsayılan argüman (override edilebilir)
#
# Container başlarken:
# 1. ENTRYPOINT çalışır → wordpress-start.sh
# 2. wordpress-start.sh hazırlık yapar
# 3. exec "$@" → CMD'yi çalıştırır
# 4. CMD çalışır → /usr/sbin/php-fpm7.4 --nodaemonize
#
# ☕ Analoji:
# - ENTRYPOINT: Açılış rutini (ışıkları aç, kapıyı aç, temizlik)
# - CMD: Asıl iş (müşteri karşılama)
# ============================================================================
ENTRYPOINT [ "/wordpress-start.sh" ]

# ============================================================================
# CMD: PHP-FPM BAŞLAT
# ============================================================================
# /usr/sbin/php-fpm7.4: PHP-FPM binary
# --nodaemonize: Foreground modda çalış (daemon olma!)
#
# 🤔 NEDEN --nodaemonize?
# Docker container'lar foreground process bekler:
# - Daemon mod → Arka plana geçer → Container kapanır ❌
# - Foreground mod → Container açık kalır ✅
#
# Nginx'te: nginx -g "daemon off;"
# PHP-FPM'de: php-fpm7.4 --nodaemonize
# MariaDB'de: mysqld (zaten foreground)
#
# ☕ Analoji:
# Mutfak şefi işbaşında:
# - Daemon: "Yemekleri hazırladım, eve gidiyorum" ❌
# - Foreground: "Buradayım, sürekli yemek yapıyorum" ✅
#
# 🔧 TEKNİK DETAY:
# PHP-FPM çalışınca:
# - Port 9000 dinlenir
# - Worker process'ler oluşturulur (www.conf'a göre)
# - Nginx'ten FastCGI istekleri kabul edilir
# - PHP kodları çalıştırılır
# - Response döndürülür
# ============================================================================
CMD ["/usr/sbin/php-fpm7.4", "--nodaemonize"]

# ============================================================================
# ÖZET - WORDPRESS DOCKERFILE'DAN ÖĞRENDİKLERİMİZ
# ============================================================================
#
# 1. FROM debian:bullseye: Base image (diğer container'larla aynı)
# 2. PHP-FPM + php-mysql + wget: Gerekli paketler
# 3. Sahte sendmail: Email hatası önleme
# 4. WP-CLI: WordPress komut satırı aracı
# 5. /var/www/html: WordPress dizini (shared volume!)
# 6. www.conf: PHP-FPM ayarları (0.0.0.0:9000)
# 7. wordpress-start.sh: Kurulum script'i
# 8. WORKDIR: Varsayılan dizin
# 9. ENTRYPOINT: Başlatma script'i (hazırlık)
# 10. CMD: PHP-FPM başlat (foreground mod)
#
# CONTAINER BAŞLATMA AKIŞI:
# docker-compose up →
#   1. Image build (bu Dockerfile)
#   2. Container create
#   3. ENTRYPOINT çalış → /wordpress-start.sh
#   4. wordpress-start.sh:
#      - İzinleri ayarla
#      - Secrets oku
#      - WordPress indir (WP-CLI)
#      - wp-config.php oluştur
#      - WordPress kur
#      - Kullanıcı oluştur
#      - exec "$@"
#   5. CMD çalış → php-fpm7.4 --nodaemonize
#   6. Port 9000 dinle
#   7. Nginx istekleri kabul et
#
# DİĞER CONTAINER'LARLA İLİŞKİ:
# - nginx: FastCGI istekleri gönderir (9000)
# - mariadb: WordPress DB bağlantısı (3306)
# - Shared volume: /var/www/html (nginx ile ortak)
#
# GÜVENLİK:
# - www-data kullanıcısı (root değil)
# - Secrets kullanımı (şifreler dosyada değil)
# - Network izolasyonu (sadece "net" network'ü)
# ============================================================================
