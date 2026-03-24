#!/bin/bash

# Shebang satırı
# '#!' -> kernel'e bu dosyayı çalıştırmak için hangi yorumlayıcıyı kullanacağını söyler
# '/bin/bash' -> bash kabuğunu kullan

# MySQL veri ve runtime dizinlerinin sahipliğini düzeltme
# komut: chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
#  - chown : change owner (sahipliği değiştir)
#  - -R    : recursive, belirtilen dizin ve tüm alt elemanlara uygular
#  - mysql:mysql : 'kullanıcı:grup' formatı (kullanıcı mysql, grup mysql)
#  - /var/lib/mysql  : MariaDB veri dosyalarının bulunduğu dizin
#  - /var/run/mysqld : MariaDB runtime (pid/socket) dizini
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Secrets dosyalarını oku ve environment değişkenlerine aktar
# Her satırda kullanılan parçalar:
#  - [ -f /run/secrets/db_password ] : test ifadesi, dosya mevcut mu? (-f regular file)
#  - &&  : önceki komut başarılıysa sağdaki komutu çalıştır
#  - export VAR=$(cat file) : değişkeni ortam değişkeni olarak ayarla, $(...) komut yerine koyar
#  - || { ...; } : önceki komut başarısızsa alternatif bloğu çalıştır (hata mesajı ve çıkış)
[ -f /run/secrets/db_password ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password) || { echo "HATA: db_password bulunamadı"; exit 1; }
[ -f /run/secrets/db_root_password ] && export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password) || { echo "HATA: db_root_password bulunamadı"; exit 1; }
# Aşağıdaki satırın parçaları:
#  - grep -E "^(MYSQL_USER|MYSQL_DATABASE)=" : credentials dosyasından sadece bu değişken atamalarını seç
#  - <(...) : process substitution, grep çıktısını bir dosya gibi '.' (source) ile okutmak için kullanılır
#  - . <(file) : current shell'e (source) komutları yükler, böylece değişkenler tanımlanır
[ -f /run/secrets/credentials ] && . <(grep -E "^(MYSQL_USER|MYSQL_DATABASE)=" /run/secrets/credentials) || { echo "HATA: credentials bulunamadı"; exit 1; }

# Gerekli environment değişkenlerinin tanımlı olduğunu kontrol et
# for var in A B C; do ... done -> döngü
# ${!var} -> indirection (var değişkeninin içindeki isimden değeri alır)
# [ -z "..." ] -> string boş mu kontrolü
for var in MYSQL_ROOT_PASSWORD MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD; do
    # ${!var} -> değişken adı değişkenden alınıyor (ör: var='MYSQL_USER' -> ${!var} === $MYSQL_USER)
    [ -z "${!var}" ] && echo "HATA: $var tanımlı değil" && exit 1
done

# Eğer belirtilen veritabanı dizini zaten varsa, kurulum adımlarını atla
# [ -d path ] -> path bir dizin mi diye kontrol eder
if [ -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Veritabanı zaten mevcut. Kurulum atlanıyor."
else
    echo "MariaDB ilk kez yapılandırılıyor..."

    # MySQL sistem tabloları yoksa oluştur
    # [ ! -d ... ] -> dizin yoksa
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "MySQL sistem veritabanları oluşturuluyor..."
        # mysql_install_db : veri dizinini ilklendirir (sistem tablolarını oluşturur)
        # --user=mysql : işlemleri mysql kullanıcısı olarak yap
        # --datadir=/var/lib/mysql : veri dizini belirtir
        # > /dev/null : komutun standart çıktısını yok say
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    fi

    echo "Veritabanı ve kullanıcı oluşturuluyor..."

    # mysqld'yi arka planda başlat
    # --user=mysql : mysqld sürecini mysql kullanıcısı altında çalıştır
    # --datadir=... : kullanılacak veri dizini
    # --skip-networking : ağ bağlantılarını kapat (geçici güvenlik, dış bağlantıları engeller)
    # & : komutu arka plana at
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    # $! -> arka planda çalıştırılan son process'in PID'si
    PID=$!

    # mysqld'nin hazır olmasını bekle (1..30 -> brace expansion ile 1'den 30'a)
    # mysqladmin ping --silent -> mysql sunucusuna ping atar, sessiz çıktı (başarılı ise 0 döner)
    # 2>/dev/null -> standart hata çıktısını yok say
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            echo "MySQL hazır!"
            break
        fi
        sleep 1
    done

    # Aşağıdaki blok bir here-document (<< EOF) ile mysql -u root komutuna SQL verisi gönderir
    # mysql -u root : root kullanıcısı ile mysql komut satırı istemcisini çalıştırır
    # << EOF : sonraki EOF satırına kadar olan metni standart giriş olarak mysql'e verir
    # Not: buradaki değişkenler (ör. ${MYSQL_ROOT_PASSWORD}) here-doc içinde genişletilir çünkü EOF tırnaklı değil
    mysql -u root << EOF
FLUSH PRIVILEGES;  -- SQL: önbelleğe alınan yetki tablolarını temizle
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';  -- root parolasını ayarla
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;  -- dönüşte `backtick` ile veritabanı ismi oluşturma (SQL sözdizimi)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';  -- genel erişim için kullanıcı oluşturma
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';  -- yeni kullanıcıya veritabanı izinleri ver
FLUSH PRIVILEGES;  -- yetki değişikliklerini uygula
EOF

    # $? -> son çalıştırılan komutun dönüş kodu (0 ise başarılı)
    if [ $? -eq 0 ]; then
        echo "SQL komutları başarıyla çalıştırıldı!"
    else
        echo "HATA: SQL komutları çalıştırılamadı!"
    fi

    # mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown : root parolası ile sunucuyu kapat
    # 2>/dev/null -> hata çıktısını gizle
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown 2>/dev/null
    # wait $PID -> arka plandaki mysqld işleminin bitmesini bekle
    wait $PID 2>/dev/null

    echo "MariaDB başarıyla yapılandırıldı!"
fi

echo "MariaDB başlatılıyor..."
# exec "$@" : script'e verilen tüm argümanları yeni process olarak çalıştır (kuyu değiştirme)
#  - exec : mevcut shell prosesini yeni prosesle değiştirir (PID değişmez)
#  - "$@" : tüm script argümanları (her biri kendi halinde) -> doğru şekilde korunur
exec "$@"
