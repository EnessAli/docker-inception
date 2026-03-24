#!/bin/bash

# Başlatma scripti: WordPress container'ı için gerekli ön hazırlıkları yapar
# Shebang: bash ile çalıştırılacak

# Kısmi bekleme: veri servislerinin (mariadb gibi) ayağa kalkması için kısa gecikme
sleep 10

# Dosya izinleri ayarlama
# chown -R www-data: /var/www/* -> owner'ı www-data olarak ayarlar (grup belirtilmemiş, sistem varsayılan grup atanır)
# chmod -R 755 /var/www/* -> dizinler için read/execute, dosyalar için read izinleri ve owner için yazma
chown -R www-data: /var/www/*
chmod -R 755 /var/www/*

# PHP-FPM runtime dizini
mkdir -p /run/php/
# /var/www/html içeriğinin sahibi ve grubu www-data olsun (web sunucusu/ PHP-FPM için)
chown -R www-data:www-data /var/www/html/

# Secrets dosyalarını yükle (varsa)
# - credentials dosyasından MYSQL_DATABASE, MYSQL_USER ve WP_ ile başlayan değişkenleri al
[ -f /run/secrets/credentials ] && . <(grep -E "^(MYSQL_DATABASE|MYSQL_USER|WP_.*|MAIL_EXTENTION)=" /run/secrets/credentials)
# - db_password dosyasından şifreyi al
[ -f /run/secrets/db_password ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Gerekli environment değişkenlerinin tanımlı olduğunu kontrol et
for var in MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD WP_ADMIN_LOGIN WP_ADMIN_PASSWORD WP_ADMIN_EMAIL WP_USER_LOGIN WP_USER_PASSWORD WP_USER_EMAIL MAIL_EXTENTION; do
    # ${!var} -> değişkenin adından değerini al (indirection)
    [ -z "${!var}" ] && echo "HATA: $var değişkeni tanımlı değil" && exit 1
done

# Bilgi amaçlı değişkenleri yazdır
echo "MYSQL_USER: [$MYSQL_USER]"
echo "MYSQL_DATABASE: [$MYSQL_DATABASE]" 
echo "WP_ADMIN_LOGIN: [$WP_ADMIN_LOGIN]"
echo "WP_ADMIN_EMAIL: [$WP_ADMIN_EMAIL]"
echo "MYSQL_PASSWORD: [$MYSQL_PASSWORD]"
echo "WP_USER_LOGIN: [$WP_USER_LOGIN]"
echo "WP_USER_PASSWORD: [$WP_USER_PASSWORD]"
echo "WP_USER_EMAIL: [$WP_USER_EMAIL]"
echo "MAIL_EXTENTION: [$MAIL_EXTENTION]"

# Eğer wp-config.php yoksa WordPress'i indirip yapılandır
if [ ! -f /var/www/html/wp-config.php ]; then
    # retry fonksiyonu: başarısız komutları belirli sayıda yeniden denemek için
    retry() {
        local max_attempts=10
        local attempt=1
        # until "$@" ; do -> "$@" ile verilen komutu çalıştır, başarılı olana dek döngü
        until "$@"; do
            [ $attempt -ge $max_attempts ] && echo "$max_attempts deneme sonrası başarısız oldu" && exit 1
            echo "Yeniden deneniyor... ($attempt/$max_attempts)"
            ((attempt++))
            sleep 2
        done
    }

    # WordPress dosyaları yoksa indir
    if [ ! -f /var/www/html/wp-includes/version.php ]; then
        echo "WordPress indiriliyor..."
        # wp-cli ile indirme, --allow-root root olarak çalıştırmaya izin verir
        retry wp-cli core download --allow-root
    else
        echo "WordPress dosyaları zaten mevcut."
    fi

    # wp-config.php oluştur
    retry wp-cli config create --allow-root --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER --dbpass=$MYSQL_PASSWORD --dbhost=mariadb
    
    # WordPress kurulumu (site ayarları, admin kullanıcı vb.)
    retry wp-cli core install --allow-root --url=$DOMAIN_NAME --title="wordpress" --admin_user=$WP_ADMIN_LOGIN --admin_password=$WP_ADMIN_PASSWORD --admin_email=$WP_ADMIN_EMAIL
    
    # Ek kullanıcı oluştur (örnek: yazar)
    retry wp-cli user create --allow-root $WP_USER_LOGIN $MAIL_EXTENTION --user_pass=$WP_USER_PASSWORD --role=author

    # Kurulum sonrası kullanıcı listesini göster
    wp-cli user list --allow-root
    echo "WordPress kurulumu başarıyla tamamlandı."
else 
    echo "WordPress zaten kurulu."
fi

# Son olarak exec "$@" ile verilen komutu çalıştır (genelde CMD içindeki php-fpm)
exec "$@"
