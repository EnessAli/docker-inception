#!/bin/bash
# ============================================================================
# WORDPRESS BAŞLATMA VE KURULUM SCRİPTİ
# WordPress indirme, yapılandırma ve PHP-FPM başlatma
# ============================================================================
#
# 📌 BU SCRİPT NE YAPAR?
# 1. MariaDB hazır olmasını bekle (10 saniye)
# 2. Dosya izinlerini ayarla (www-data)
# 3. Secrets dosyalarını oku (şifreler, kullanıcı bilgileri)
# 4. WordPress indir (WP-CLI)
# 5. wp-config.php oluştur (DB bağlantı ayarları)
# 6. WordPress kur (admin oluştur)
# 7. Kullanıcı ekle (author role)
# 8. PHP-FPM başlat
#
# ☕ RESTORAN AÇILIŞI ANALOJİSİ:
# 1. Depo hazır mı? (MariaDB)
# 2. Mutfak izinlerini ayarla
# 3. Yönetici bilgilerini al
# 4. Malzemeleri getir (WordPress dosyaları)
# 5. Tarifi hazırla (wp-config.php)
# 6. Restoran aç (WordPress install)
# 7. Personel ekle (user create)
# 8. Mutfağı başlat (PHP-FPM)
# ============================================================================

# ============================================================================
# SLEEP 10 - MARIADB BEKLEYİŞİ
# ============================================================================
# sleep 10: 10 saniye bekle
#
# 🤔 NEDEN?
# docker-compose.yml:
#   depends_on:
#     - mariadb
# "depends_on" sadece container başlamasını bekler,
# MariaDB'nin hazır olmasını BEKLEMEZ!
#
# MariaDB başlatma süreci:
# 1. Container start (0s)
# 2. mysqld başlat (2s)
# 3. Database oluştur (5s)
# 4. User oluştur (7s)
# 5. HAZIR! (10s)
#
# WordPress hemen bağlanmaya çalışırsa → Connection refused!
# 10 saniye bekleme → MariaDB hazır ✅
#
# ☕ Analoji:
# Mutfak ve depo:
# - Depo kapısı açıldı (container start)
# - Ama içeride düzenleme yapılıyor (DB setup)
# - 10 dakika bekle → Depo kullanıma hazır!
#
# 🔧 DAHA İYİ ÇÖZÜM:
# Health check veya wait-for-it.sh script'i:
#   until mysqladmin ping -h mariadb; do sleep 1; done
# Ama basit projede sleep yeterli!
# ============================================================================
sleep 10

# ============================================================================
# DOSYA İZİNLERİ - www-data SAHİPLİĞİ
# ============================================================================
# chown -R www-data: /var/www/*
#   -R: Recursive (alt klasörler dahil)
#   www-data:: Kullanıcı:Grup (grup belirtilmezse kullanıcıyla aynı)
#   /var/www/*: Tüm dosyalar
#
# PHP-FPM www-data olarak çalışır (www.conf → user = www-data)
# Dosyalar www-data'ya ait olmalı (okuma/yazma için)
#
# chmod -R 755 /var/www/*:
#   755: rwxr-xr-x
#   - Owner (www-data): Read + Write + Execute
#   - Group: Read + Execute
#   - Others: Read + Execute
#
# 🤔 NEDEN 755?
# - 777: Herkes yazabilir → Güvenlik riski! ❌
# - 755: Sadece owner yazabilir → Güvenli ✅
#
# ☕ Analoji:
# Mutfak dolabı izinleri:
# - Aşçı (www-data): Açabilir, yemek koyabilir (rwx)
# - Garson: Açabilir, bakabilir (r-x)
# - Müşteri: Açabilir, bakabilir (r-x)
#
# mkdir -p /run/php/: PHP-FPM runtime klasörü
# /run/php/php7.4-fpm.pid: PHP-FPM process ID burada
#
# chown -R www-data:www-data /var/www/html/: WordPress klasörü özel ayar
# ============================================================================
chown -R www-data: /var/www/*
chmod -R 755 /var/www/*
mkdir -p /run/php/
chown -R www-data:www-data /var/www/html/

# ============================================================================
# SECRETS OKUMA - GÜVENLİ ŞIFRE YÖNETİMİ
# ============================================================================
# [ -f /run/secrets/credentials ] && . <(grep -E "^(...)=" /run/secrets/credentials)
#
# PARÇALARA AYIR:
# 1. [ -f /run/secrets/credentials ]: Dosya var mı kontrol et
# 2. &&: Varsa şunu yap (AND operatörü)
# 3. . <(...): Process substitution (dosya gibi çalıştır)
# 4. grep -E "^(...)=": Regex ile satırları filtrele
#
# grep -E "^(MYSQL_DATABASE|MYSQL_USER|WP_.*|MAIL_EXTENTION)=":
#   ^: Satır başı
#   MYSQL_DATABASE|MYSQL_USER: Bu kelimelerle başlayan
#   WP_.*: WP_ ile başlayan herhangi bir şey (WP_ADMIN_LOGIN, WP_USER_EMAIL, vb.)
#   =: Eşittir işareti
#
# ÖRNEK credentials DOSYASI:
#   MYSQL_DATABASE=wordpress_db
#   MYSQL_USER=wp_user
#   WP_ADMIN_LOGIN=admin
#   WP_ADMIN_PASSWORD=Admin123!
#   WP_ADMIN_EMAIL=admin@egermen.42.fr
#   WP_USER_LOGIN=author
#   WP_USER_PASSWORD=Author123!
#   WP_USER_EMAIL=author@egermen.42.fr
#   MAIL_EXTENTION=@egermen.42.fr
#
# . <(grep...): Bu satırları source et (environment variable yap)
# export MYSQL_DATABASE=wordpress_db (otomatik!)
#
# [ -f /run/secrets/db_password ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
#   cat: Dosya içeriğini oku
#   $(cat ...): Command substitution (çıktıyı al)
#   export: Environment variable yap
#
# 🤔 NEDEN /run/secrets/?
# Docker secrets mount point:
# docker-compose.yml:
#   secrets:
#     - credentials
# Container içinde → /run/secrets/credentials
#
# ☕ Analoji:
# Kasada saklanan bilgiler:
# - credentials: Kullanıcı adları, email'ler (hassas ama şifre değil)
# - db_password: Şifre (ÇOK hassas!)
# - Script kasayı açar, bilgileri alır, hafızasına yükler (export)
#
# 🔧 GÜVENLİK:
# Şifreler script içinde hardcoded değil! ✅
# Git'te görünmez (secrets/ klasörü .gitignore'da)
# Her ortam farklı secrets kullanabilir (dev, prod)
# ============================================================================
[ -f /run/secrets/credentials ] && . <(grep -E "^(MYSQL_DATABASE|MYSQL_USER|WP_.*|MAIL_EXTENTION)=" /run/secrets/credentials)
[ -f /run/secrets/db_password ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# ============================================================================
# DEĞİŞKEN KONTROLÜ - EKSİK BİLGİ VARSA DUR!
# ============================================================================
# for var in ...: Listedeki her değişken için döngü
#
# [ -z "${!var}" ]: Değişken boş mu?
#   -z: Zero length (boş string)
#   ${!var}: Indirect expansion (değişkenin adını kullan)
#
# ÖRNEK:
#   var=MYSQL_DATABASE
#   ${!var} → $MYSQL_DATABASE → wordpress_db
#
# [ -z "${!var}" ] && echo "..." && exit 1:
#   Değişken boş → Hata mesajı → Script'i durdur (exit 1)
#
# 🤔 NEDEN?
# Eksik bilgi ile devam edilirse:
# - WordPress kurulamaz (DB bilgisi yok)
# - wp-config.php hatalı
# - Container başlar ama çalışmaz!
#
# Erken hata yakalama → Debug kolay!
#
# ☕ Analoji:
# Restoran açılışı kontrol listesi:
# - Depo adresi var mı? (MYSQL_DATABASE)
# - Depo anahtarı var mı? (MYSQL_PASSWORD)
# - Yönetici ismi var mı? (WP_ADMIN_LOGIN)
# - Eksik varsa → Restoran açma! (exit 1)
#
# KONTROL EDİLEN DEĞİŞKENLER:
# 1. MYSQL_DATABASE: Veritabanı adı
# 2. MYSQL_USER: DB kullanıcısı
# 3. MYSQL_PASSWORD: DB şifresi
# 4. WP_ADMIN_LOGIN: WordPress admin kullanıcı adı
# 5. WP_ADMIN_PASSWORD: Admin şifresi
# 6. WP_ADMIN_EMAIL: Admin email
# 7. WP_USER_LOGIN: Normal kullanıcı adı
# 8. WP_USER_PASSWORD: Normal kullanıcı şifresi
# 9. WP_USER_EMAIL: Normal kullanıcı email
# 10. MAIL_EXTENTION: Email uzantısı (@egermen.42.fr)
# ============================================================================
for var in MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD WP_ADMIN_LOGIN WP_ADMIN_PASSWORD WP_ADMIN_EMAIL WP_USER_LOGIN WP_USER_PASSWORD WP_USER_EMAIL MAIL_EXTENTION; do
    [ -z "${!var}" ] && echo "HATA: $var değişkeni tanımlı değil" && exit 1
done

# ============================================================================
# DEBUG ÇIKTILARI - BİLGİ KONTROLÜ
# ============================================================================
# echo: Değişkenleri ekrana yazdır (docker logs wordpress)
#
# 🤔 NEDEN?
# Debug amaçlı → Secrets doğru okundu mu kontrol et
# Production'da kaldırılabilir (şifre loglarda görünür!)
#
# ☕ Analoji:
# Restoran açılış toplantısı:
# - "Depo adresi: wordpress_db"
# - "Depo kullanıcısı: wp_user"
# - "Yönetici: admin"
# Herkes bilgiyi doğrular!
#
# 🔧 GÜVENLİK NOTU:
# MYSQL_PASSWORD loglanıyor → Production'da ÇOK TEHLİKELİ!
# Gerçek projede bu satırı kaldır!
# ============================================================================
echo "MYSQL_USER: [$MYSQL_USER]"
echo "MYSQL_DATABASE: [$MYSQL_DATABASE]" 
echo "WP_ADMIN_LOGIN: [$WP_ADMIN_LOGIN]"
echo "WP_ADMIN_EMAIL: [$WP_ADMIN_EMAIL]"
echo "MYSQL_PASSWORD: [$MYSQL_PASSWORD]"
echo "WP_USER_LOGIN: [$WP_USER_LOGIN]"
echo "WP_USER_PASSWORD: [$WP_USER_PASSWORD]"
echo "WP_USER_EMAIL: [$WP_USER_EMAIL]"
echo "MAIL_EXTENTION: [$MAIL_EXTENTION]"

# ============================================================================
# İDEMPOTENT KURULUM KONTROLÜ
# ============================================================================
# if [ ! -f /var/www/html/wp-config.php ]; then:
#   wp-config.php yoksa → WordPress kurulmamış → Kur!
#   wp-config.php varsa → Zaten kurulu → Atla!
#
# 🤔 NEDEN İDEMPOTENT?
# Container restart → Script tekrar çalışır
# Zaten kurulu WordPress'i tekrar kurma! (veri kaybı)
# wp-config.php varlığı → Kurulum göstergesi
#
# ☕ Analoji:
# Restoran açılış kontrolü:
# - Menü var mı? (wp-config.php)
# - Yoksa → Menü hazırla, restoran aç!
# - Varsa → Zaten açık, sadece mutfağı başlat!
# ============================================================================
if [ ! -f /var/www/html/wp-config.php ]; then
    # ========================================================================
    # RETRY FONKSİYONU - HATA DAYANIKLILIK
    # ========================================================================
    # retry() { ... }: Fonksiyon tanımla (tekrar deneme mantığı)
    #
    # until "$@"; do:
    #   "$@": Fonksiyona verilen komutları çalıştır
    #   until: Başarılı olana kadar döngü
    #
    # [ $attempt -ge $max_attempts ] && echo "..." && exit 1:
    #   10 deneme başarısız → Script durdur
    #
    # ((attempt++)): Sayacı artır (attempt = attempt + 1)
    # sleep 2: 2 saniye bekle, tekrar dene
    #
    # 🤔 NEDEN RETRY?
    # Network hataları, geçici sorunlar:
    # - MariaDB bağlantısı kesildi → Tekrar dene
    # - WordPress indirme hatası → Tekrar dene
    # - wp-cli timeout → Tekrar dene
    #
    # 10 deneme × 2 saniye = 20 saniye max bekleme
    #
    # ☕ Analoji:
    # Telefon araması:
    # - Meşgul → 2 saniye bekle, tekrar ara
    # - 10 deneme başarısız → "Ulaşılamıyor" (exit 1)
    # ========================================================================
    retry() {
        local max_attempts=10
        local attempt=1
        until "$@"; do
            [ $attempt -ge $max_attempts ] && echo "$max_attempts deneme sonrası başarısız oldu" && exit 1
            echo "Yeniden deneniyor... ($attempt/$max_attempts)"
            ((attempt++))
            sleep 2
        done
    }

    # ========================================================================
    # WORDPRESS DOSYALARINI İNDİR
    # ========================================================================
    # if [ ! -f /var/www/html/wp-includes/version.php ]; then:
    #   WordPress dosyaları yok → İndir!
    #   WordPress dosyaları var → Atla (tekrar indirme)
    #
    # retry wp-cli core download --allow-root:
    #   wp-cli: WordPress Command Line Interface
    #   core download: WordPress core dosyalarını indir
    #   --allow-root: Root olarak çalıştırmaya izin ver (container'da gerekli)
    #
    # İndirilen dosyalar:
    #   - wp-admin/ (yönetim paneli)
    #   - wp-includes/ (core PHP dosyaları)
    #   - wp-content/ (temalar, pluginler)
    #   - index.php, wp-login.php, vb.
    #
    # 🤔 NEREDEN İNDİRİR?
    # https://wordpress.org/latest.tar.gz
    # Güncel stable sürüm (örneğin WordPress 6.4)
    #
    # ☕ Analoji:
    # Restoran malzemeleri:
    # - Mutfak ekipmanı var mı? (wp-includes/version.php)
    # - Yoksa → Tedarikçiden sipariş et (download)
    # - Varsa → Zaten var, tekrar alma!
    # ========================================================================
    if [ ! -f /var/www/html/wp-includes/version.php ]; then
        echo "WordPress indiriliyor..."
        retry wp-cli core download --allow-root
    else
        echo "WordPress dosyaları zaten mevcut."
    fi

    # ========================================================================
    # WP-CONFIG.PHP OLUŞTUR - VERİTABANI BAĞLANTISI
    # ========================================================================
    # retry wp-cli config create:
    #   wp-cli config create: wp-config.php oluştur
    #   --allow-root: Root izni
    #   --dbname=$MYSQL_DATABASE: Veritabanı adı (wordpress_db)
    #   --dbuser=$MYSQL_USER: DB kullanıcısı (wp_user)
    #   --dbpass=$MYSQL_PASSWORD: DB şifresi (secrets'tan)
    #   --dbhost=mariadb: DB sunucusu (Docker DNS!)
    #
    # OLUŞTURULAN wp-config.php:
    #   define('DB_NAME', 'wordpress_db');
    #   define('DB_USER', 'wp_user');
    #   define('DB_PASSWORD', 'secret123');
    #   define('DB_HOST', 'mariadb');
    #
    # 🤔 NEDEN mariadb?
    # docker-compose.yml:
    #   services:
    #     mariadb:
    #       container_name: mariadb
    # Docker DNS: "mariadb" → Container IP'si
    #
    # ☕ Analoji:
    # Depo bağlantı bilgileri:
    # - Depo adresi: mariadb binası
    # - Depo ismi: wordpress_db
    # - Anahtar: wp_user / secret123
    # - Tarif defterine yaz! (wp-config.php)
    # ========================================================================
    retry wp-cli config create --allow-root --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER --dbpass=$MYSQL_PASSWORD --dbhost=mariadb
    
    # ========================================================================
    # WORDPRESS KURULUMU - SİTE OLUŞTUR
    # ========================================================================
    # retry wp-cli core install:
    #   wp-cli core install: WordPress'i kur (DB tablolarını oluştur)
    #   --allow-root: Root izni
    #   --url=$DOMAIN_NAME: Site URL'i (egermen.42.fr)
    #   --title="wordpress": Site başlığı
    #   --admin_user=$WP_ADMIN_LOGIN: Admin kullanıcı adı
    #   --admin_password=$WP_ADMIN_PASSWORD: Admin şifresi
    #   --admin_email=$WP_ADMIN_EMAIL: Admin email
    #
    # YAPILAN İŞLEMLER:
    # 1. MariaDB'ye bağlan
    # 2. wp_users, wp_posts, wp_options tablolarını oluştur
    # 3. Admin kullanıcısı ekle (wp_users)
    # 4. Site ayarlarını kaydet (wp_options)
    # 5. Varsayılan içerik oluştur (Hello World post)
    #
    # 🤔 $DOMAIN_NAME NEDİR?
    # docker-compose.yml environment veya .env:
    #   DOMAIN_NAME=egermen.42.fr
    # WordPress bu URL'de çalışacak
    #
    # ☕ Analoji:
    # Restoran açılışı:
    # - Tabela as (Site title: "wordpress")
    # - Adres kaydet (URL: egermen.42.fr)
    # - Yönetici ata (Admin: $WP_ADMIN_LOGIN)
    # - Ruhsat al (DB tabloları)
    # ========================================================================
    retry wp-cli core install --allow-root --url=$DOMAIN_NAME --title="wordpress" --admin_user=$WP_ADMIN_LOGIN --admin_password=$WP_ADMIN_PASSWORD --admin_email=$WP_ADMIN_EMAIL
    
    # ========================================================================
    # KULLANICI OLUŞTUR - AUTHOR ROLE
    # ========================================================================
    # retry wp-cli user create:
    #   wp-cli user create: Kullanıcı ekle
    #   --allow-root: Root izni
    #   $WP_USER_LOGIN: Kullanıcı adı (author)
    #   $MAIL_EXTENTION: Email (@egermen.42.fr)
    #   --user_pass=$WP_USER_PASSWORD: Şifre
    #   --role=author: Yetki seviyesi
    #
    # WORDPRESS ROLLERİ:
    # - administrator: Tam yetki (admin)
    # - editor: İçerik düzenleme
    # - author: Kendi yazılarını yönet ✅ (BİZ BUNU KULLANIYORUZ)
    # - contributor: Yazı yaz (yayınlayamaz)
    # - subscriber: Sadece oku
    #
    # ☕ Analoji:
    # Restoran personeli:
    # - administrator: Restoran sahibi (her şeyi yapabilir)
    # - author: Aşçı (kendi yemeklerini hazırlar) ✅
    # - subscriber: Müşteri (sadece yemek yer)
    #
    # 🔧 TEKNİK DETAY:
    # wp_users tablosuna kayıt eklenir:
    #   INSERT INTO wp_users (user_login, user_email, user_pass, ...)
    #   VALUES ('author', 'author@egermen.42.fr', hash($WP_USER_PASSWORD), ...)
    # ========================================================================
    retry wp-cli user create --allow-root $WP_USER_LOGIN $MAIL_EXTENTION --user_pass=$WP_USER_PASSWORD --role=author

    # ========================================================================
    # KULLANICI LİSTESİ - DEBUG
    # ========================================================================
    # wp-cli user list --allow-root: Tüm kullanıcıları listele
    # Çıktı:
    #   ID  user_login  display_name  user_email               roles
    #   1   admin       admin         admin@egermen.42.fr      administrator
    #   2   author      author        author@egermen.42.fr     author
    #
    # 🤔 NEDEN?
    # Debug: Kullanıcılar başarıyla oluşturuldu mu kontrol et!
    # ========================================================================
    wp-cli user list --allow-root
    echo "WordPress kurulumu başarıyla tamamlandı."
else 
    # ========================================================================
    # WORDPRESS ZATEN KURULU
    # ========================================================================
    # wp-config.php var → Kurulum atlandı
    # Container restart durumunda burası çalışır
    # İdempotent davranış → Aynı işi tekrar yapma!
    #
    # ☕ Analoji:
    # Restoran zaten açık:
    # - Menü var (wp-config.php)
    # - Personel kayıtlı (wp_users)
    # - Sadece mutfağı başlat! (PHP-FPM)
    # ========================================================================
    echo "WordPress zaten kurulu."
fi

# ============================================================================
# EXEC "$@" - PHP-FPM BAŞLAT
# ============================================================================
# exec "$@": CMD komutunu çalıştır (Dockerfile'dan)
#
# Dockerfile:
#   CMD ["/usr/sbin/php-fpm7.4", "--nodaemonize"]
#
# exec ile:
#   PID 1: wordpress-start.sh → php-fpm7.4
#   Signal handling doğru çalışır (docker stop)
#
# PHP-FPM başlar:
#   - www.conf okunur
#   - Port 9000 dinlenir
#   - Worker'lar oluşturulur (pm.start_servers = 2)
#   - Nginx istekleri kabul edilir!
#
# ☕ Analoji:
# Açılış hazırlıkları bitti:
# - Mutfağı aç (PHP-FPM start)
# - Siparişleri kabul et (port 9000 listen)
# - Aşçılar hazır (worker processes)
# - Restoran hizmete açık! ✅
# ============================================================================
exec "$@"

# ============================================================================
# ÖZET - WORDPRESS-START.SH'TAN ÖĞRENDİKLERİMİZ
# ============================================================================
#
# 1. sleep 10: MariaDB hazır olmasını bekle
# 2. chown/chmod: Dosya izinleri (www-data)
# 3. Secrets okuma: Güvenli şifre yönetimi
# 4. Değişken kontrolü: Eksik bilgi → Dur!
# 5. İdempotent kontrol: wp-config.php var mı?
# 6. retry(): Hata dayanıklılığı (10 deneme)
# 7. wp-cli core download: WordPress indir
# 8. wp-cli config create: DB bağlantı ayarları
# 9. wp-cli core install: Site kur (admin oluştur)
# 10. wp-cli user create: Kullanıcı ekle (author)
# 11. exec "$@": PHP-FPM başlat
#
# KURULUM AKIŞI (İlk Çalıştırma):
# Container start →
#   sleep 10 (MariaDB bekleniyor...) →
#   İzinler ayarlandı (www-data) →
#   Secrets okundu (şifreler yüklendi) →
#   Değişkenler kontrol edildi (hepsi var ✅) →
#   wp-config.php yok → Kurulum başlasın! →
#   WordPress dosyaları indiriliyor... (wp-cli core download) →
#   wp-config.php oluşturuluyor... (DB: mariadb) →
#   WordPress kuruluyor... (admin oluşturuluyor) →
#   Kullanıcı ekleniyor... (author role) →
#   Kullanıcılar listelendi (admin, author) →
#   WordPress kurulumu başarıyla tamamlandı! →
#   PHP-FPM başlatılıyor... (exec "$@") →
#   Port 9000 dinleniyor →
#   Nginx istekleri kabul ediliyor! ✅
#
# RESTART AKIŞI (Container restart):
# Container start →
#   sleep 10 →
#   İzinler ayarlandı →
#   Secrets okundu →
#   Değişkenler kontrol edildi →
#   wp-config.php VAR → Kurulum atla! →
#   "WordPress zaten kurulu." →
#   PHP-FPM başlatılıyor... →
#   Port 9000 dinleniyor ✅
#
# DİĞER DOSYALARLA İLİŞKİ:
# - Dockerfile ENTRYPOINT: Bu script'i çalıştırır
# - Dockerfile CMD: PHP-FPM komutu (exec "$@" ile çalışır)
# - www.conf: PHP-FPM ayarları (port 9000, dynamic workers)
# - docker-compose.yml: Secrets mount, depends_on mariadb
# - MariaDB setup-mysql.sh: wordpress_db oluşturdu (bu script bağlanır)
# - nginx.conf: fastcgi_pass wordpress:9000 (bu script'in başlattığı port)
#
# WP-CLI KOMUTLARI:
# - core download: WordPress dosyalarını indir
# - config create: wp-config.php oluştur (DB ayarları)
# - core install: WordPress kur (DB tabloları + admin)
# - user create: Kullanıcı ekle
# - user list: Kullanıcıları listele
#
# GÜVENLİK:
# - Secrets kullanımı (/run/secrets/) ✅
# - Şifre hardcode yok ✅
# - www-data kullanıcısı (root değil) ✅
# - Dosya izinleri 755 (düzgün) ✅
# - ❌ MYSQL_PASSWORD loglarda (production'da kaldır!)
#
# HATA YÖNETİMİ:
# - retry() fonksiyonu (10 deneme)
# - Değişken kontrolü (eksik bilgi → exit 1)
# - İdempotent (tekrar çalıştırılabilir)
# - sleep 10 (race condition önleme)
# ============================================================================
