# ============================================================================
# MARİADB KURULUM SCRİPTİ - setup-mysql.sh
# ============================================================================
#
# 📌 BU SCRIPT NE YAPAR?
# MariaDB'nin ilk kurulumunu gerçekleştirir:
# 1. İzinleri düzeltir
# 2. Şifreleri okur (secrets/)
# 3. Sistem veritabanlarını oluşturur
# 4. WordPress veritabanını oluşturur
# 5. WordPress kullanıcısını oluşturur
# 6. MariaDB daemon'ını başlatır
#
# 🤔 NEDEN BASH SCRIPT?
# Birden fazla komutu sırayla çalıştırmak için.
# Dockerfile'da RUN ile yapmak karmaşık olurdu.
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kütüphane açılış prosedürü:
# 1. Anahtarları al (şifreleri oku)
# 2. Rafları kontrol et (sistem DB'leri var mı?)
# 3. Katalog sistemini başlat
# 4. Kütüphaneci kartını oluştur (kullanıcı)
# 5. Kapıları aç (daemon başlat)
#
# 🔧 ÇALIŞMA SIRASI:
# Container başlar → ENTRYPOINT ["/setup-mysql.sh"] → Bu script çalışır
# → exec "$@" → CMD ["mariadbd", "--user=mysql"] çalışır
#
# ============================================================================

# ============================================================================
# SATIR: #!/bin/bash
# ============================================================================
#
# 📌 SHEBANG NEDİR?
# "Hashbang" veya "shebang" - Script'in hangi yorumlayıcıyla çalışacağını belirtir.
#
# #! → Shebang işareti
# /bin/bash → Bash yorumlayıcısının yolu
#
# 🤔 NEDEN GEREKLİ?
# Linux birden fazla shell destekler:
#   - /bin/bash → Bash (en yaygın)
#   - /bin/sh → Bourne Shell (minimal)
#   - /bin/zsh → Z Shell (gelişmiş)
#
# Shebang olmadan:
#   ./setup-mysql.sh → Hangi shell kullanılacak? Belirsiz!
#
# Shebang ile:
#   ./setup-mysql.sh → /bin/bash kullan!
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Mektup zarfında "Türkçe oku" yazmak gibi.
# Postacı mektubu Türkçe bilen birine verir.
#
# 🔧 ALTERNATİFLER:
# #!/bin/sh → Daha portable ama az özellik
# #!/bin/bash → Çok özellik, yaygın ← Bizim tercih
# #!/usr/bin/env bash → Bash'i PATH'te ara (en portable)
#
# ⚠️ ÖNEMLİ:
# İlk satır olmak ZORUNDA!
# Boş satır bile olamaz başta.
# ============================================================================
#!/bin/bash

# ============================================================================
# İZİN DÜZELTMELERİ
# ============================================================================
#
# 📌 BU KOMUT NE YAPAR?
# MariaDB'nin kullanacağı klasörlerin sahipliğini "mysql" kullanıcısına verir.
#
# 🤔 NEDEN GEREKLİ?
# Container build sırasında root olarak dosyalar kopyalandı.
# MariaDB "mysql" kullanıcısı olarak çalışır.
# Dosya sahibi root ise → mysql kullanıcısı yazamaz → HATA!
#
# chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
#   - chown: Change owner (sahipliği değiştir)
#   - -R: Recursive (klasör ve alt klasörler)
#   - mysql:mysql: Kullanıcı:Grup
#   - /var/lib/mysql: Veri klasörü
#   - /var/run/mysqld: Runtime klasörü (PID, socket)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Yeni eve taşınıyorsun:
# - Evin sahibi sen olmadan eşyalarına dokunamazsın
# - chown = Evin tapusunu adına geçir
# - Artık her şeyi değiştirebilirsin
#
# 🔧 TEKNİK DETAY:
# Volume mount edildiğinde sahibi root olabilir.
# mysql kullanıcısı (UID 999) yazamaz.
# chown ile düzeltiyoruz.
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# Dockerfile: RUN chown ... (build zamanı)
# Bu script: chown ... (runtime zamanı)
# İkisi de gerekli! Volume mount sonrası izinler değişebilir.
#
# ⚠️ GÜVENLİK:
# Root olarak çalışıyor olmalıyız (script başlangıcında).
# Sonra mysql kullanıcısına geçeceğiz.
# ============================================================================
# MySQL dizinlerinin izinlerini düzelt
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# ============================================================================
# SECRETS OKUMA - db_password
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# db_password secret dosyasını okur ve MYSQL_PASSWORD değişkenine atar.
# Dosya yoksa hata mesajı ver ve çık.
#
# 🤔 SYNTAX AÇIKLAMASI:
# [ -f /run/secrets/db_password ] → Dosya var mı kontrol et
#   && → Varsa devam et
#   export MYSQL_PASSWORD=$(cat /run/secrets/db_password) → Oku ve değişkene ata
#   || → Yoksa alternatif çalıştır
#   { echo "HATA..."; exit 1; } → Hata mesajı ve çık
#
# -f: File exists (dosya var mı?)
# $(cat ...): Dosyayı oku, içeriğini al
# export: Environment variable olarak dışa aktar
# exit 1: Hata kodu 1 ile çık (başarısız)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kasayı açmak için şifre gerekli:
# - Kasada şifre kağıdı var mı bak
# - Varsa oku ve akılda tut
# - Yoksa "Şifre bulunamadı!" diye bağır ve vazgeç
#
# 🔧 SECRETS NEREDE?
# docker-compose.yml:
#   secrets:
#     db_password:
#       file: ../secrets/db_password.txt
#
# Container içinde:
#   /run/secrets/db_password → tmpfs (RAM'de)
#
# İçeriği:
#   DBdata1. (sadece şifre, tek satır)
#
# 🔗 NEDEN SECRETS?
# Environment variable ile fark:
#   ❌ ENV: docker inspect ile görülebilir (güvensiz)
#   ❌ ENV: Log'lara düşebilir
#   ✅ SECRETS: tmpfs'te (disk'te değil)
#   ✅ SECRETS: Container silinince kaybolur
#   ✅ SECRETS: docker inspect'te görünmez
#
# ⚠️ ÖNEMLİ:
# exit 1 → Script durur, container başlamaz!
# Güvenlik: Şifre yoksa çalışma!
# ============================================================================
# Secrets'ları oku
[ -f /run/secrets/db_password ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password) || { echo "HATA: db_password bulunamadı"; exit 1; }

# ============================================================================
# SECRETS OKUMA - db_root_password
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Root kullanıcısının şifresini okur.
#
# 🤔 ROOT vs USER ŞİFRESİ?
# MYSQL_ROOT_PASSWORD:
#   - root@localhost kullanıcısı
#   - Tüm yetkilere sahip (superuser)
#   - Kurulum için gerekli
#   - WordPress KULLANMAZ!
#
# MYSQL_PASSWORD:
#   - wp_user@'%' kullanıcısı
#   - Sadece wordpress_db veritabanına erişim
#   - WordPress BUNU KULLANIR
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Bina yönetimi:
# - Root = Site yöneticisi (her daireye girebilir)
# - User = Kiracı (sadece kendi dairesine girebilir)
#
# 🔧 GÜVENLİK:
# WordPress root şifresini BİLMEMELİ!
# Sadece kendi veritabanı şifresi yeterli.
# Hack olsa bile root şifresi güvende.
# ============================================================================
[ -f /run/secrets/db_root_password ] && export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password) || { echo "HATA: db_root_password bulunamadı"; exit 1; }

# ============================================================================
# SECRETS OKUMA - credentials
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# credentials dosyasından MYSQL_USER ve MYSQL_DATABASE değişkenlerini okur.
#
# 🤔 SYNTAX AÇIKLAMASI:
# . <(grep -E "^(MYSQL_USER|MYSQL_DATABASE)=" /run/secrets/credentials)
#
# grep -E "^(MYSQL_USER|MYSQL_DATABASE)=" → Regex ile satır filtrele
#   ^: Satır başı
#   (A|B): A veya B
#   =: Eşittir işareti
# Sonuç: MYSQL_USER=... ve MYSQL_DATABASE=... satırları
#
# <(...): Process substitution (komutu dosya gibi kullan)
# .: Source komutu (dosyayı çalıştır ve değişkenleri içe aktar)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Talimat kitabından sadece önemli sayfaları fotokopile:
# - grep = Sadece veritabanı bilgilerini filtrele
# - source (.) = O bilgileri not al (akla yaz)
#
# 🔧 CREDENTIALS DOSYASI:
# /run/secrets/credentials içeriği:
#   MYSQL_DATABASE=wordpress_db
#   MYSQL_USER=wp_user
#   WP_ADMIN_LOGIN=eagermen
#   ... (diğer WordPress bilgileri)
#
# Bu komut sadece şunları alır:
#   MYSQL_DATABASE=wordpress_db
#   MYSQL_USER=wp_user
#
# 💡 NEDEN GREPLİYORUZ?
# credentials'da WordPress bilgileri de var.
# MariaDB sadece veritabanı bilgileri kullanır.
# Gereksiz değişkenler environment'ı kirletmesin.
#
# 🔗 ALTERNATİF:
# source /run/secrets/credentials → Tüm değişkenleri al
# grep ile filtreleme daha temiz ve güvenli.
# ============================================================================
[ -f /run/secrets/credentials ] && . <(grep -E "^(MYSQL_USER|MYSQL_DATABASE)=" /run/secrets/credentials) || { echo "HATA: credentials bulunamadı"; exit 1; }

# ============================================================================
# DEĞİŞKEN KONTROLÜ
# ============================================================================
#
# 📌 BU DÖNGÜ NE YAPAR?
# Kritik değişkenlerin tanımlı olduğundan emin olur.
# Herhangi biri eksikse hata ver ve çık.
#
# 🤔 SYNTAX AÇIKLAMASI:
# for var in A B C D; do ... done → Döngü
# [ -z "${!var}" ] → Değişken boş mu?
#   -z: Zero length (uzunluk sıfır mı?)
#   ${!var}: Indirect expansion (değişkenin değeri)
#     var=MYSQL_USER
#     ${!var} = ${MYSQL_USER} = wp_user
#
# && echo && exit 1 → Boşsa hata ver ve çık
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Uçuştan önce kontrol listesi:
# - Pasaport var mı? ✓
# - Bilet var mı? ✓
# - Bavul var mı? ✓
# - Para var mı? ✓
# Biri yoksa → Uçağa binme!
#
# 🔧 KONTROL EDİLEN DEĞİŞKENLER:
# 1. MYSQL_ROOT_PASSWORD → Root şifresi (kurulum için)
# 2. MYSQL_DATABASE → Veritabanı adı (wordpress_db)
# 3. MYSQL_USER → Kullanıcı adı (wp_user)
# 4. MYSQL_PASSWORD → Kullanıcı şifresi
#
# 💡 NEDEN ${!var}?
# Normal ${var}:
#   var="MYSQL_USER"
#   ${var} = "MYSQL_USER" (string literal)
#
# Indirect ${!var}:
#   var="MYSQL_USER"
#   ${!var} = ${MYSQL_USER} = "wp_user" (değişkenin değeri)
#
# 🔗 GÜVENLİK:
# Container başlamadan önce doğrula!
# Eksik varsa erken hata ver.
# Yarım kurulum olmasın.
# ============================================================================
# Değişkenleri kontrol et
for var in MYSQL_ROOT_PASSWORD MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD; do
    [ -z "${!var}" ] && echo "HATA: $var tanımlı değil" && exit 1
done

# ============================================================================
# VERİTABANI DURUMU KONTROLÜ
# ============================================================================
#
# 📌 BU BLOK NE YAPAR?
# Veritabanı daha önce kurulmuş mu kontrol eder.
# Kurulmuşsa tekrar kurulum yapmaz (idempotent).
#
# 🤔 IDEMPOTENT NEDİR?
# Aynı işlemi birden fazla kere yapınca sonuç değişmez.
#
# Örnek:
#   1. İlk çalışma: Veritabanı kur
#   2. Container restart: Veritabanı zaten var, kurma
#   3. 10. restart: Hala aynı veritabanı
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kahvaltı hazırlığı:
# - Mutfağa git
# - Kahvaltı hazır mı bak
# - Hazırsa yeniden yapma! (zaman kaybı)
# - Hazır değilse yap
#
# 🔧 KONTROL MANTIGI:
# if [ -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
#   -d: Directory exists (klasör var mı?)
#   /var/lib/mysql/wordpress_db → Veritabanı klasörü
#
# Klasör varsa:
#   → Veritabanı daha önce oluşturulmuş
#   → Kurulumu atla
#   → Direkt MariaDB'yi başlat
#
# Klasör yoksa:
#   → İlk kurulum
#   → Sistem DB'lerini oluştur
#   → WordPress DB'sini oluştur
#   → Kullanıcıyı oluştur
#
# 💡 NEDEN ÖNEMLİ?
# Container her restart'ta bu script çalışır!
# Her seferinde DB oluşturmaya çalışsaydık:
#   ❌ "Database already exists" hatası
#   ❌ Mevcut veriler silinebilir!
#
# Bu kontrol ile:
#   ✅ İlk kurulum: DB oluştur
#   ✅ Restart: DB var, atla
#   ✅ Veriler korunur
#
# 🔗 VOLUME İLE İLİŞKİ:
# ${HOME}/data/mariadb/wordpress_db klasörü volume'de saklanır.
# Container silinse bile klasör kalır.
# Yeni container başlar → Klasör var → Kurulum atlanır
#
# ⚠️ VOLUME SİLERSEN:
# rm -rf ${HOME}/data/mariadb
# → Klasör gider
# → Container restart → Klasör yok
# → Yeniden kurulum yapılır
# → Tüm veriler sıfırlanır!
# ============================================================================
# Veritabanının oluşturulup oluşturulmadığını kontrol et
if [ -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Veritabanı zaten mevcut. Kurulum atlanıyor."
else
    echo "MariaDB ilk kez yapılandırılıyor..."
    
    # ==========================================================================
    # SİSTEM VERİTABANLARI OLUŞTURMA
    # ==========================================================================
    #
    # 📌 BU BLOK NE YAPAR?
    # MySQL/MariaDB sistem veritabanlarını oluşturur.
    #
    # 🤔 SİSTEM VERİTABANLARI NEDİR?
    # MySQL kendi çalışması için bazı veritabanları kullanır:
    #   - mysql: Kullanıcılar, yetkiler, ayarlar
    #   - performance_schema: Performans metrikleri
    #   - information_schema: Meta veriler
    #
    # İlk kurulumda bu veritabanları YOKTUR!
    # mysql_install_db komutu bunları oluşturur.
    #
    # ☕ GÜNLÜK HAYAT ÖRNEĞİ:
    # Kütüphane açıyorsun:
    # - Raflar boş (kullanıcı veritabanları)
    # - Katalog sistemi yok (sistem veritabanları)
    # - mysql_install_db = Katalog sistemini kur
    # - Sonra kitapları ekleyebilirsin
    #
    # 🔧 KOMUT DETAYI:
    # mysql_install_db:
    #   --user=mysql → mysql kullanıcısı olarak çalıştır
    #   --datadir=/var/lib/mysql → Verileri buraya kur
    #   > /dev/null → Çıktıyı gösterme (sessiz)
    #
    # Oluşturulan yapı:
    # /var/lib/mysql/
    #   ├── mysql/ ← Sistem veritabanı
    #   ├── performance_schema/
    #   └── (diğer sistem dosyaları)
    #
    # 💡 NE ZAMAN ÇALIŞIR?
    # Sadece /var/lib/mysql/mysql yoksa!
    # Volume mount edildiğinde:
    #   - İlk kez: Klasör boş → mysql_install_db çalışır
    #   - Restart: Klasör dolu → Atlanır
    #
    # 🔗 VOLUME PERSİSTENCE:
    # ${HOME}/data/mariadb/mysql klasörü saklanır.
    # Container restart → mysql/ var → install_db atlanır
    #
    # ⚠️ ÖNEMLİ:
    # mysql_install_db UZUN SÜREBİLİR! (5-10 saniye)
    # İlk başlatma yavaştır, normal.
    # ==========================================================================
    # MySQL sistem veritabanları yoksa oluştur
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "MySQL sistem veritabanları oluşturuluyor..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    fi
    
    echo "Veritabanı ve kullanıcı oluşturuluyor..."
    
    # ==========================================================================
    # GEÇİCİ MYSQLD BAŞLATMA
    # ==========================================================================
    #
    # 📌 BU KOMUT NE YAPAR?
    # MariaDB'yi geçici olarak arka planda başlatır.
    # SQL komutlarını çalıştırmak için gerekli.
    #
    # 🤔 NEDEN GEREKLİ?
    # SQL komutları çalıştırmak için MariaDB çalışmalı!
    # CREATE DATABASE, CREATE USER vs. → MariaDB'ye gönderilir
    #
    # Ama sorun: MariaDB foreground'da başlarsa script bloke olur!
    # Çözüm: Arka planda başlat (&), SQL'leri çalıştır, sonra kapat.
    #
    # ☕ GÜNLÜK HAYAT ÖRNEĞİ:
    # Fabrika ayarları:
    # - Fabrikayı geçici aç (test modu)
    # - Ayarları yap
    # - Fabrikayı kapat
    # - Gerçek modda aç
    #
    # 🔧 KOMUT DETAYI:
    # mysqld:
    #   --user=mysql → mysql kullanıcısı olarak çalış
    #   --datadir=/var/lib/mysql → Veri klasörü
    #   --skip-networking → Network'ü devre dışı bırak (güvenlik!)
    #     * Port 3306 dinlemez
    #     * Sadece socket ile erişim
    #     * Dışarıdan bağlanılamaz
    #   & → Arka planda çalıştır (background)
    #
    # PID=$! → Arka plan process ID'sini sakla
    #   $! → Son arka plan process'in PID'si
    #   Örnek: PID=42
    #   Sonra kapatmak için kullanacağız: kill $PID
    #
    # 💡 --skip-networking NEDEN?
    # Güvenlik! Kurulum sırasında:
    #   - Root şifresi henüz yok
    #   - Network açık olsa herkes bağlanabilir!
    #   - Sadece socket → Sadece lokal erişim
    #
    # 🔗 SOCKET BAĞLANTI:
    # mysql -u root → Otomatik /run/mysqld/mysqld.sock kullanır
    # Network kapalı ama socket çalışıyor!
    #
    # ⚠️ ARKA PLAN ÇALIŞMA:
    # & operatörü: Script devam eder, mysqld arka planda çalışır
    # wait $PID → İstersen bekleyebilirsin
    # ==========================================================================
    # Geçici olarak mysqld'yi background'da başlat
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    PID=$!
    
    # ==========================================================================
    # MYSQL HAZIR OLANA KADAR BEKLE
    # ==========================================================================
    #
    # 📌 BU DÖNGÜ NE YAPAR?
    # mysqld tamamen başlayana kadar bekler.
    #
    # 🤔 NEDEN BEKLEMEK GEREKİYOR?
    # mysqld & → Arka planda başlar ama HEMEN HAZIR DEĞİL!
    # Başlatma süreci:
    #   1. Process başlar (PID alır)
    #   2. Config dosyasını okur
    #   3. Veritabanlarını yükler
    #   4. Socket oluşturur
    #   5. Bağlantı kabul etmeye HAZIR ← Buraya kadar beklemeliyiz!
    #
    # Beklemesen ne olur?
    #   mysql -u root → "Can't connect to MySQL server" ← HATA!
    #
    # ☕ GÜNLÜK HAYAT ÖRNEĞİ:
    # Bilgisayar açmak:
    # - Power tuşuna bas → Process başlar
    # - Ekran gelir ama işletim sistemi henüz hazır değil
    # - Windows yükleniyor...
    # - Giriş ekranı geldi → HAZIR! ← Buraya kadar bekle
    # - Şimdi programları açabilirsin
    #
    # 🔧 KOMUT DETAYI:
    # for i in {1..30}; do
    #   {1..30} → 1'den 30'a kadar sayı dizisi
    #   30 deneme = 30 saniye timeout
    #
    # mysqladmin ping --silent 2>/dev/null
    #   mysqladmin: MySQL yönetim aracı
    #   ping: MariaDB'ye "hazır mısın?" diye sor
    #   --silent: Sessiz (çıktı gösterme)
    #   2>/dev/null: Hata mesajlarını gösterme
    #
    # if mysqladmin ping; then
    #   Hazırsa "pong" döner → Başarılı!
    #   break → Döngüden çık
    #
    # sleep 1
    #   1 saniye bekle
    #   Tekrar dene
    #
    # 💡 TIMEOUT SENARYOSU:
    # 30 deneme başarısız olursa?
    # → Döngü biter
    # → Script devam eder (SQL komutları çalıştırılır)
    # → SQL komutları BAŞARISIZ OLUR!
    # → Container çöker
    #
    # Gerçekte:
    # MariaDB 2-3 saniyede hazır olur.
    # 30 saniye çok fazla buffer.
    #
    # 🔗 ALTERNATİF KONTROLLER:
    # mysqladmin ping → En yaygın
    # mysql -e "SELECT 1" → SQL sorgusu çalıştır
    # [ -S /run/mysqld/mysqld.sock ] → Socket dosyası var mı?
    # ==========================================================================
    # MySQL'in tamamen başlamasını bekle
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            echo "MySQL hazır!"
            break
        fi
        sleep 1
    done
    
    # ==========================================================================
    # SQL KOMUTLARINI ÇALIŞTIR
    # ==========================================================================
    #
    # 📌 BU BLOK NE YAPAR?
    # Veritabanı ve kullanıcı oluşturma SQL komutlarını çalıştırır.
    #
    # 🤔 HERE DOCUMENT (<<EOF) NEDİR?
    # Çok satırlı veriyi komuta gönderme yöntemi.
    #
    # mysql -u root << EOF
    #   ... SQL komutları ...
    # EOF
    #
    # << → Redirection operator
    # EOF → Sonlandırıcı (End Of File)
    # mysql komutuna SQL'leri gönder
    #
    # ☕ GÜNLÜK HAYAT ÖRNEĞİ:
    # Garsonve sipariş:
    # - Garson (mysql): Hazır, not defteri açık
    # - Müşteri (script): Sipariş listesi:
    #     * 1 çorba
    #     * 2 pilav
    #     * 1 tatlı
    # - EOF = "Sipariş bitti"
    # - Garson mutfağa iletir
    #
    # 🔧 SQL KOMUTLARI TEK TEK:
    #
    # 1. FLUSH PRIVILEGES;
    #    - Yetki tablolarını yeniden yükle
    #    - ALTER USER çalışması için gerekli
    #    - mysql.user tablosunu refresh et
    #
    # 2. ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    #    - root kullanıcısının şifresini ayarla
    #    - İlk kurulumda root şifresiz!
    #    - Güvenlik için şifre zorunlu
    #    - @'localhost': Sadece lokal erişim
    #
    # 3. CREATE DATABASE IF NOT EXISTS `${MYSQL_DATABASE}`;
    #    - WordPress veritabanını oluştur
    #    - IF NOT EXISTS: Varsa hata verme
    #    - ` (backtick): Özel karakterler için escape
    #    - Örnek: wordpress_db
    #
    # 4. CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    #    - WordPress kullanıcısını oluştur
    #    - @'%': Tüm IP'lerden bağlanabilir
    #    - Örnek: wp_user@'%'
    #
    # 5. GRANT ALL PRIVILEGES ON `${MYSQL_DATABASE}`.* TO '${MYSQL_USER}'@'%';
    #    - WordPress kullanıcısına yetki ver
    #    - wordpress_db.* → Tüm tablolar
    #    - ALL PRIVILEGES: SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, vs.
    #
    # 6. FLUSH PRIVILEGES;
    #    - Yetkileri uygula
    #    - Grant cache'i temizle
    #
    # 💡 @'localhost' vs @'%' FARKI?
    # root@'localhost':
    #   - Sadece lokal bağlantı (aynı container)
    #   - Güvenlik: Dışarıdan bağlanamaz
    #
    # wp_user@'%':
    #   - Network'ten bağlanabilir (farklı container)
    #   - WordPress container'dan erişim için gerekli!
    #
    # 🔗 WORDPRESS BAĞLANTISI:
    # wordpress container:
    #   DB_HOST=mariadb
    #   DB_USER=wp_user
    #   DB_PASSWORD=DBdata1.
    #   DB_NAME=wordpress_db
    #
    # → wordpress container (172.18.0.3)
    # → mariadb container (172.18.0.2)
    # → wp_user@'172.18.0.3' → Eşleşir! (% her şeyi kapsar)
    # → Bağlantı BAŞARILI!
    #
    # ⚠️ GÜVENLİK:
    # @'%' tehlikeli görünse de:
    # 1. docker-compose: expose (ports değil)
    # 2. Sadece "net" network'ünden erişim
    # 3. Dış dünyadan erişim YOK!
    # ==========================================================================
    # SQL komutlarını çalıştır
    mysql -u root << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    # ==========================================================================
    # BAŞARI KONTROLÜ
    # ==========================================================================
    #
    # 📌 BU BLOK NE YAPAR?
    # SQL komutlarının başarılı olup olmadığını kontrol eder.
    #
    # 🤔 $? NEDİR?
    # En son çalışan komutun exit code'u (dönüş kodu).
    #
    # Exit codes:
    #   0: Başarılı
    #   1-255: Hata (farklı kodlar farklı hatalar)
    #
    # Örnek:
    #   ls /var → $? = 0 (başarılı)
    #   ls /yok → $? = 2 (klasör yok hatası)
    #
    # ☕ GÜNLÜK HAYAT ÖRNEĞİ:
    # Sipariş sonrası garson:
    # - Mutfaktan cevap geldi mi?
    # - "Tamam" → Exit code 0 → Başarılı!
    # - "Malzeme yok" → Exit code 1 → Hata!
    #
    # 🔧 KONTROL MANTIGI:
    # if [ $? -eq 0 ]; then
    #   -eq: Equal (eşit mi?)
    #   0: Başarı kodu
    #   → SQL komutları başarılı!
    #
    # else
    #   → SQL komutları başarısız!
    #   → Muhtemelen syntax hatası veya bağlantı sorunu
    #
    # 💡 SQL HATALARI:
    # Olası hatalar:
    #   - Syntax error: SQL yanlış yazılmış
    #   - Connection error: mysqld hazır değil
    #   - Permission error: root izni yok
    #
    # Hatalar ekrana yazdırılır (stderr).
    # Script devam eder ama MariaDB düzgün kurulmamış olur!
    #
    # ⚠️ ÖNEMLİ:
    # Hata olsa bile script durmuyor!
    # Container başlar ama veritabanı çalışmaz.
    # Log'lara bakman gerekir: docker-compose logs mariadb
    # ==========================================================================
    # Başarıyı kontrol et
    if [ $? -eq 0 ]; then
        echo "SQL komutları başarıyla çalıştırıldı!"
    else
        echo "HATA: SQL komutları çalıştırılamadı!"
    fi
    
    # ==========================================================================
    # GEÇİCİ MYSQLD'Yİ KAPAT
    # ==========================================================================
    #
    # 📌 BU KOMUTLAR NE YAPAR?
    # Arka planda çalışan geçici mysqld'yi düzgün şekilde kapatır.
    #
    # 🤔 NEDEN KAPATIYORUZ?
    # Geçici mysqld:
    #   - --skip-networking ile başlatıldı
    #   - Sadece kurulum için gerekti
    #   - Gerçek mysqld farklı parametrelerle başlayacak
    #
    # İki mysqld aynı anda çalışamaz!
    # → Geçicini kapat → Gerçeğini başlat
    #
    # ☕ GÜNLÜK HAYAT ÖRNEĞİ:
    # Fabrika test modu:
    # - Test modunda ayarları yaptın
    # - Fabrikayı kapat
    # - Gerçek modda yeniden aç
    #
    # 🔧 KOMUT DETAYI:
    #
    # mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown 2>/dev/null
    #   mysqladmin: Yönetim aracı
    #   -u root: Root kullanıcısı olarak
    #   -p"...": Şifre (boşluk OLMADAN!)
    #   shutdown: Kapat komutu
    #   2>/dev/null: Hata mesajlarını gösterme
    #
    # Neden 2>/dev/null?
    #   Bazen mysqld zaten kapanmış olabilir.
    #   "Server not running" hatası → Önemli değil, gösterme
    #
    # wait $PID 2>/dev/null
    #   wait: Process bitene kadar bekle
    #   $PID: Arka plan mysqld'nin process ID'si
    #   2>/dev/null: Hata gösterme
    #
    # Neden wait?
    #   shutdown komutu sinyali gönderir ama process hemen bitmez.
    #   Birkaç saniye sürebilir (dosyaları kapat, cache'i flush et).
    #   wait ile bitene kadar bekleriz.
    #
    # 💡 GRACEFUL SHUTDOWN:
    # mysqladmin shutdown:
    #   1. Yeni bağlantıları reddet
    #   2. Mevcut sorguları bitir
    #   3. Dirty page'leri diske yaz
    #   4. Transaction loglarını flush et
    #   5. Socket'i kapat
    #   6. Process'i sonlandır
    #
    # kill $PID ile fark:
    #   kill: Ani sonlandırma (veri kaybı riski!)
    #   mysqladmin shutdown: Düzgün kapanma (güvenli)
    #
    # 🔗 SONRAKI ADIM:
    # Bu mysqld kapatıldı → exec "$@" çalışır
    # → CMD ["mariadbd", "--user=mysql"] başlar
    # → Gerçek mysqld network ile birlikte çalışır!
    #
    # ⚠️ PROCESS YÖNETİMİ:
    # PID'yi saklamıştık: PID=$!
    # Şimdi kullanıyoruz: wait $PID
    # PID kaybolursa wait çalışmaz (problem değil).
    # ==========================================================================
    # mysqld'yi kapat
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown 2>/dev/null
    wait $PID 2>/dev/null
    
    echo "MariaDB başarıyla yapılandırıldı!"
fi

echo "MariaDB başlatılıyor..."

# ============================================================================
# DAEMON BAŞLATMA - exec "$@"
# ============================================================================
#
# 📌 BU KOMUT NE YAPAR?
# Gerçek MariaDB daemon'ını başlatır.
# Script'in process ID'sini daemon'a verir.
#
# 🤔 exec NEDİR?
# Mevcut process'i yeni komutla değiştirir.
#
# Normal çalıştırma:
#   ./setup-mysql.sh → Process 1 (PID 1)
#     ├─ mariadbd → Process 2 (Child process)
#   Docker stop → Process 1'e sinyal gider
#   → Process 1, Process 2'yi kapatmalı (karmaşık!)
#
# exec ile:
#   ./setup-mysql.sh → Process 1
#   exec mariadbd → Process 1 artık mariadbd!
#   Docker stop → mariadbd'ye direkt sinyal gider!
#   → Düzgün kapanma (graceful shutdown)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Gece bekçisi:
# - Sabah bekçisi (setup script) gelir
# - Gece bekçisi (mariadbd) görevini devreder
# - Sabah bekçisi gider → Gece bekçisi process 1 olur
# - Müdür (Docker) → Direkt gece bekçisine talimat verir
#
# 🔧 "$@" NEDİR?
# Tüm argümanları temsil eder.
#
# Dockerfile'dan gelir:
#   CMD ["mariadbd", "--user=mysql"]
#
# Script çalışırken:
#   $@ = "mariadbd --user=mysql"
#
# exec "$@" → exec mariadbd --user=mysql
#
# 💡 NEDEN TIRNAK İÇİNDE?
# "$@": Her argüman ayrı (doğru!)
#   ["mariadbd", "--user=mysql"]
#
# $@: Argümanlar birleşir (yanlış!)
#   ["mariadbd --user=mysql"] → Tek argüman, çalışmaz!
#
# 🔗 DOCKER SİNYALLERİ:
# docker stop:
#   1. SIGTERM sinyali gönderir (düzgün kapat)
#   2. 10 saniye bekler
#   3. SIGKILL gönderir (zorla kapat)
#
# exec sayesinde:
#   SIGTERM → mariadbd'ye direkt gider
#   → Düzgün kapanır (10 saniye yeter)
#
# exec olmasaydı:
#   SIGTERM → script'e gider
#   → Script mariadbd'yi kapatmalı
#   → Karmaşık! 10 saniye yetmeyebilir!
#   → SIGKILL → Veri kaybı riski!
#
# ⚠️ ÖNEMLİ:
# exec'ten sonra script BİTER!
# Sonrasındaki satırlar ÇALIŞMAZ!
# exec son komut olmalı!
#
# 🎯 SONUÇ:
# Container başladı → setup-mysql.sh çalıştı
# → İzinler düzeltildi
# → Şifreler okundu
# → Veritabanı kuruldu (ilk kez ise)
# → exec mariadbd → MariaDB daemon çalışıyor!
# → Port 3306 dinleniyor
# → WordPress bağlanabilir!
# ============================================================================
exec "$@"

# ============================================================================
# ÖZET - setup-mysql.sh'TEN ÖĞRENDİKLERİMİZ
# ============================================================================
#
# 1. SHEBANG: #!/bin/bash (script yorumlayıcısı)
# 2. İZİNLER: chown -R mysql:mysql (sahiplik)
# 3. SECRETS: /run/secrets/ (güvenli şifre okuma)
# 4. DEĞİŞKEN KONTROLÜ: [ -z "${!var}" ] (boş mu?)
# 5. IDEMPOTENT: Veritabanı varsa kurulum atla
# 6. mysql_install_db: Sistem veritabanları oluştur
# 7. BACKGROUND PROCESS: & ve PID=$!
# 8. BEKLEME: for döngüsü + mysqladmin ping
# 9. HERE DOCUMENT: <<EOF ... EOF
# 10. SQL KOMUTLARI: FLUSH, ALTER, CREATE, GRANT
# 11. EXIT CODE: $? kontrolü
# 12. GRACEFUL SHUTDOWN: mysqladmin shutdown + wait
# 13. exec "$@": Process ID'yi daemon'a ver
#
# ÇALIŞMA AKIŞI:
# Container başla
#   ↓
# setup-mysql.sh çalış
#   ↓
# İzinleri düzelt
#   ↓
# Şifreleri oku
#   ↓
# Veritabanı var mı?
#   ├─ Var: Atla
#   └─ Yok: Kur
#       ├─ Sistem DB'leri oluştur
#       ├─ Geçici mysqld başlat
#       ├─ SQL komutlarını çalıştır
#       └─ Geçici mysqld'yi kapat
#   ↓
# exec mariadbd
#   ↓
# MariaDB çalışıyor!
#   ↓
# WordPress bağlanabilir!
#
# GÜVENLİK:
# - mysql kullanıcısı (root değil!)
# - Secrets (environment değil!)
# - --skip-networking (kurulum sırasında)
# - root@'localhost' (lokal erişim)
# - wp_user@'%' (sadece network, dış dünyaya kapalı)
#
# PERSİSTENCE:
# - Volume: /var/lib/mysql
# - Restart: Veritabanı kalır
# - Idempotent: Yeniden kurulum yapmaz
#
# ============================================================================
