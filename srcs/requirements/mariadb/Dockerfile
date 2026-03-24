# ============================================================================
# MARİADB DOCKERFILE - Veritabanı Container İmajı
# ============================================================================
#
# 📌 BU DOSYA NE YAPAR?
# MariaDB veritabanı sunucusu içeren bir Docker image'ı oluşturur.
# WordPress'in tüm verilerini (makaleler, kullanıcılar, ayarlar) saklar.
#
# 🤔 MARİADB vs MYSQL?
# - MariaDB: MySQL'in açık kaynak fork'u
# - %100 MySQL uyumlu
# - Daha hızlı ve özgür
# - WordPress sorunsuz çalışır
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kütüphane binası inşa etmek gibi:
# 1. Temel at (FROM debian)
# 2. Rafları kur (MariaDB kur)
# 3. Katalog sistemini ayarla (config dosyası)
# 4. Kütüphaneciyi eğit (setup script)
# 5. Kapıları aç (CMD ile başlat)
#
# 🔧 BUILD SÜRECİ:
# docker-compose build mariadb komutu:
# 1. Bu Dockerfile'ı okur
# 2. Her satır bir "layer" oluşturur
# 3. Layer'lar üst üste binir
# 4. Sonunda çalışabilir bir image oluşur
# 5. Container bu image'dan başlatılır
#
# ============================================================================

# ============================================================================
# SATIR: FROM debian:bullseye
# ============================================================================
# 
# 📌 BU SATIR NE YAPAR?
# Docker image'ımızın temelini oluşturur.
# "Debian Bullseye" (Debian 11) işletim sistemini base olarak kullanır.
#
# 🤔 NEDEN DEBIAN? NEDEN BULLSEYE?
# Debian:
#   - Çok stabil (crash olmaz)
#   - Güvenilir (uzun yıllardır kullanılır)
#   - İyi paket yöneticisi (apt-get)
#   - Hafif (Alpine kadar değil ama yeterince)
#
# Bullseye:
#   - Debian 11 (2021'de çıktı)
#   - LTS (Long Term Support)
#   - Güncel paketler ama test edilmiş
#
# Alternatifler:
#   Alpine: Çok hafif (~5MB) ama uyumluluk sorunları
#   Ubuntu: Daha şişkin (~70MB), gereksiz paketler
#   Debian Bookworm: Daha yeni (12) ama daha az test edilmiş
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Ev yapmak için zemin seçmek:
# - Debian = Sağlam beton zemin (güvenilir, dayanıklı)
# - Alpine = Hafif ahşap zemin (hafif ama her mobilya uymuyor)
# - Ubuntu = Villa zemini (lüks ama pahalı, gereksiz özellikler)
#
# 🔧 TEKNİK DETAY:
# - "FROM" her Dockerfile'ın ilk komutu olmak ZORUNDA
# - Docker Hub'dan debian:bullseye image'ını indirir
# - Bu image ~120MB civarı
# - Layer sistemi: Bu base layer, diğer layer'ların temeli
# - Etiket (tag) önemli: bullseye → sabit versiyon
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# - docker-compose.yml: build: ./requirements/mariadb → Bu dosyayı okur
# - Tüm RUN komutları bu base image üzerinde çalışır
# - Seçtiğimiz distro, paket yöneticisini belirler (apt-get)
#
# ⚠️ ÖNEMLİ NOTLAR:
# - Tag yazmazsan "latest" kullanır (tehlikeli, her zaman değişebilir!)
# - Production'da MUTLAKA tag kullan (versiyon sabitleme)
# - latest = tahmin edilemez, bullseye = sabit
# ============================================================================
FROM debian:bullseye

# ============================================================================
# SATIR: RUN apt-get update && apt-get upgrade -y && apt-get install -y mariadb-server
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# 1. Paket listesini günceller (apt-get update)
# 2. Yüklü paketleri yükseltir (apt-get upgrade)
# 3. MariaDB sunucusunu kurar (apt-get install mariadb-server)
#
# 🤔 NEDEN 3 KOMUT BİRLEŞTİRİLMİŞ?
# && operatörü: "Başarılı olursa sonrakini çalıştır"
# Docker best practice: Birden fazla komutu birleştir
# Neden? Her RUN komutu yeni bir layer oluşturur
# Daha az layer = Daha küçük image
#
# 🔧 KOMUTLAR TEK TEK:
#
# apt-get update:
#   - Paket listesini günceller
#   - Debian deposundaki en son paket bilgilerini indirir
#   - Kurulum yapmaz, sadece listeyi günceller
#   - Yapmasan eski paketleri kurarsın (güvenlik açığı!)
#
# apt-get upgrade -y:
#   - Yüklü paketleri yeni versiyonlara yükseltir
#   - -y = "yes" (onay isteme, otomatik "evet" de)
#   - Güvenlik yamalarını uygular
#   - İsteğe bağlı ama önerilen
#
# apt-get install -y mariadb-server:
#   - MariaDB veritabanı sunucusunu kurar
#   - -y = Onay isteme
#   - mariadb-server paketi:
#       * MariaDB daemon (mysqld)
#       * Komut satırı araçları (mysql, mysqladmin)
#       * Sistem veritabanları (mysql, performance_schema)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kütüphane kurmak:
# 1. update = Katalog listesini güncelle (hangi kitaplar var?)
# 2. upgrade = Eski kitapların yeni baskılarını al
# 3. install = Kütüphane raflarını ve sistemini kur
#
# 🔧 TEKNİK DETAY - LAYER SİSTEMİ:
# ❌ Kötü (3 layer):
#   RUN apt-get update
#   RUN apt-get upgrade -y
#   RUN apt-get install -y mariadb-server
# → 3 layer = Daha büyük image
#
# ✅ İyi (1 layer):
#   RUN apt-get update && apt-get upgrade -y && apt-get install -y mariadb-server
# → 1 layer = Daha küçük image
#
# 💡 PAKET YÖNETİCİSİ:
# apt-get (Debian/Ubuntu):
#   - update: Listeyi güncelle
#   - install: Paket kur
#   - remove: Paket kaldır
#
# Alternatifler:
#   - yum (CentOS/RHEL)
#   - apk (Alpine)
#   - dnf (Fedora)
#
# ⚠️ CACHE SORUNLARI:
# Docker layer'ları cache'ler.
# apt-get update çalışmışsa bir daha çalışmaz (cache kullanır).
# Sorunu çözmek için:
#   docker-compose build --no-cache
# ============================================================================
RUN apt-get update && apt-get upgrade -y && apt-get install -y mariadb-server

# ============================================================================
# SATIR: COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Kendi ayar dosyamızı container'a kopyalar.
# MariaDB bu ayarları kullanarak çalışır.
#
# 🤔 NEDEN COPY?
# Default ayarlar yeterli değil:
#   - bind-address = 127.0.0.1 (sadece localhost, container'lar bağlanamaz!)
#   - Karakter set ayarları eksik
#   - Port ayarı yapılmalı
#
# Kendi ayar dosyamızla:
#   - bind-address = 0.0.0.0 (tüm IP'lerden bağlanabilir)
#   - UTF-8 karakter seti (Türkçe karakter desteği)
#   - Port 3306 açık şekilde belirtilmiş
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kütüphane çalışma saatlerini ayarlamak:
# - Default = Sadece mahalle sakinleri girebilir
# - Custom = Herkese açık, geniş saatler
#
# 🔧 TEKNİK DETAY:
# COPY kaynak hedef
#   - Kaynak: ./conf/50-server.cnf (build context'e göre)
#   - Hedef: /etc/mysql/mariadb.conf.d/ (container içi)
#
# Build context: docker-compose.yml'de build: ./requirements/mariadb
# → ./conf/50-server.cnf = requirements/mariadb/conf/50-server.cnf
#
# 💡 NEDEN 50-server.cnf?
# /etc/mysql/mariadb.conf.d/ içindeki dosyalar alfabetik sırayla okunur:
#   - 10-*.cnf
#   - 20-*.cnf
#   - 50-server.cnf ← Bizimki
#   - 60-*.cnf
# 50 = Ortada, diğer ayarları override edebilir
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# - conf/50-server.cnf: Asıl ayar dosyası
#   * bind-address = 0.0.0.0
#   * port = 3306
#   * character-set-server = utf8mb4
# - setup-mysql.sh: Bu ayarları kullanarak MariaDB başlatır
#
# ⚠️ ÖDEV:
# Dosya container içinde: /etc/mysql/mariadb.conf.d/50-server.cnf
# MariaDB başlarken otomatik okur ve uygular.
# ============================================================================
COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# ============================================================================
# SATIR: RUN chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf && ...
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Dosya/klasör izinlerini ve sahipliklerini ayarlar.
# Güvenlik ve çalışabilirlik için gerekli.
#
# 🤔 İZİNLER NEDİR?
# Linux'ta her dosyanın:
#   - Sahibi (owner) var: kim oluşturdu?
#   - Grubu (group) var: hangi grup kullanır?
#   - İzinleri (permissions) var: kim ne yapabilir?
#
# 🔧 KOMUTLAR TEK TEK:
#
# chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf:
#   644 ne demek?
#     6 (owner): rw- (okuma + yazma)
#     4 (group): r-- (sadece okuma)
#     4 (others): r-- (sadece okuma)
#   MariaDB bu dosyayı okumalı ama yazmamalı.
#
# chown mysql:mysql /etc/mysql/mariadb.conf.d/50-server.cnf:
#   Dosyanın sahibini "mysql" kullanıcısı yap
#   Dosyanın grubunu "mysql" grubu yap
#   MariaDB daemon "mysql" kullanıcısı olarak çalışır
#
# mkdir -p /var/run/mysqld:
#   MariaDB'nin çalışma dosyalarını sakladığı klasör
#   -p = Parent klasörler yoksa oluştur
#   İçinde: mysqld.pid (process ID), mysqld.sock (socket dosyası)
#
# chown -R mysql:mysql /var/run/mysqld:
#   -R = Recursive (klasör ve içindekilerin hepsi)
#   Tüm dosyaların sahibi mysql olsun
#
# chmod 755 /var/run/mysqld:
#   755:
#     7 (owner): rwx (okuma + yazma + çalıştırma)
#     5 (group): r-x (okuma + çalıştırma)
#     5 (others): r-x (okuma + çalıştırma)
#   Klasöre girebilmek için x (execute) gerekir
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Ofis dosya dolabı:
# - chmod: Dolapta kilit sistemi (kim ne yapabilir?)
# - chown: Dolabın sahibi kim? (ismini yaz)
# - mkdir: Yeni raf ekle
# - 644: Herkes okuyabilir, sadece sahibi yazabilir
# - 755: Herkes girebilir, sadece sahibi değiştirebilir
#
# 🔧 İZİN NUMARALARI:
# r (read) = 4
# w (write) = 2
# x (execute) = 1
#
# 7 = 4+2+1 = rwx (hepsi)
# 6 = 4+2 = rw- (okuma + yazma)
# 5 = 4+1 = r-x (okuma + çalıştırma)
# 4 = 4 = r-- (sadece okuma)
#
# ⚠️ GÜVENLİK:
# MariaDB daemon root olarak ÇALIŞMAMALI!
# Güvenlik riski! Hack olursa sistem ele geçer.
# "mysql" kullanıcısı: Sınırlı yetkiler, güvenli.
# ============================================================================
RUN chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf && \
    chown mysql:mysql /etc/mysql/mariadb.conf.d/50-server.cnf && \
    mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# ============================================================================
# SATIR: COPY ./tools/setup-mysql.sh /
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# İlk kurulum scriptini container'a kopyalar.
# Container başladığında bu script çalışacak.
#
# 🔧 SCRIPT NE YAPAR?
# 1. MySQL sistem veritabanlarını oluşturur (mysql_install_db)
# 2. Root şifresini ayarlar
# 3. WordPress veritabanını oluşturur
# 4. WordPress kullanıcısını oluşturur
# 5. İzinleri verir (GRANT)
# 6. MariaDB daemon'ı başlatır
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kütüphaneyi açmadan önce hazırlık:
# - Rafları kur
# - Katalog sistemini başlat
# - Kütüphaneci kartını oluştur
# - Çalışma saatlerini ayarla
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# - tools/setup-mysql.sh: Asıl script dosyası
# - ENTRYPOINT: Bu scripti çalıştırır
# - secrets/: Script buradan şifreleri okur
# ============================================================================
COPY ./tools/setup-mysql.sh /

# ============================================================================
# SATIR: RUN chmod +x /setup-mysql.sh
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Script dosyasına "çalıştırılabilir" izni verir.
#
# 🤔 +x NE DEMEK?
# x = execute (çalıştırma)
# +x = execute izni ekle
# chmod +x = Bu dosya çalıştırılabilir yap
#
# Yapmasan ne olur?
# ./setup-mysql.sh → Permission denied
# bash setup-mysql.sh → Çalışır ama dolaylı
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Talimat kağıdını yazdın ama kimse okuyamıyor.
# +x = Herkese "bu talimatları uygulayabilirsin" izni ver.
#
# 🔧 ALTERNATİF:
# chmod 755 /setup-mysql.sh → Daha spesifik
# chmod +x /setup-mysql.sh → Basit ve yeterli
# ============================================================================
RUN chmod +x /setup-mysql.sh

# ============================================================================
# SATIR: ENTRYPOINT [ "/setup-mysql.sh" ]
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# Container başladığında ilk çalışacak komutu belirler.
# Her zaman setup-mysql.sh çalışır.
#
# 🤔 ENTRYPOINT vs CMD FARKI?
#
# ENTRYPOINT:
#   - Sabit komut, değiştirilemez (override edilmesi zor)
#   - Container'ın ana amacı
#   - Mutlaka çalışması gereken
#
# CMD:
#   - Varsayılan argümanlar
#   - Kolayca değiştirilebilir
#   - docker run ile override edilir
#
# BU PROJEDE:
#   ENTRYPOINT ["/setup-mysql.sh"] → Sabit, her zaman çalış
#   CMD ["mariadbd", "--user=mysql"] → setup-mysql.sh'ye argüman
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoran açılış prosedürü:
# - ENTRYPOINT = Açılış rutini (mutfak hazırlığı, personel toplantısı)
# - CMD = Menü (değiştirilebilir, günlük özel yemek)
#
# 🔧 TEKNİK DETAY:
# Exec form: ["komut", "arg1", "arg2"]
# Shell form: komut arg1 arg2
#
# Exec form tercih edilir çünkü:
#   - Daha hızlı (shell açmaz)
#   - Sinyalleri doğru yakalar (SIGTERM)
#   - Best practice
#
# 🔗 ÇALIŞMA AKIŞI:
# Container başlar
#   ↓
# ENTRYPOINT çalışır: /setup-mysql.sh
#   ↓
# Script veritabanını kurar
#   ↓
# Script exec "$@" çalıştırır
#   ↓
# CMD çalışır: mariadbd --user=mysql
#   ↓
# MariaDB daemon başlar
#
# exec "$@":
#   - $@ = CMD'deki argümanlar
#   - exec = Script'in process ID'sini MariaDB'ye ver
#   - Docker sinyalleri (stop) MariaDB'ye gönderir
#
# ⚠️ NEDEN exec?
# exec olmazsa:
#   - Script process 1 olur
#   - MariaDB child process olur
#   - docker stop → Script'e sinyal gider
#   - Script MariaDB'yi düzgün kapatamaz
#
# exec ile:
#   - MariaDB process 1 olur
#   - docker stop → MariaDB'ye direkt sinyal
#   - Düzgün kapanır (graceful shutdown)
# ============================================================================
ENTRYPOINT [ "/setup-mysql.sh" ]

# ============================================================================
# SATIR: CMD [ "mariadbd", "--user=mysql" ]
# ============================================================================
#
# 📌 BU SATIR NE YAPAR?
# MariaDB daemon'ını başlatır.
# ENTRYPOINT'e argüman olarak geçirilir.
#
# 🤔 PARAMETRELER:
#
# mariadbd:
#   - MariaDB daemon (server process)
#   - Eskiden "mysqld" denirdi
#   - Veritabanı sunucusunun kendisi
#
# --user=mysql:
#   - mysql kullanıcısı olarak çalış
#   - root olarak ÇALIŞMA! (güvenlik)
#   - Sistem izinlerini sınırla
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Kütüphaneyi açmak:
# - mariadbd = Kütüphaneyi aç
# - --user=mysql = Kütüphaneci olarak çalış (müdür olarak değil)
#
# 🔧 FOREGROUND vs BACKGROUND:
# Docker container'ları foreground process gerektirir!
#
# ❌ Yanlış:
#   CMD ["mariadbd", "&"]  # Background, container hemen kapanır
#
# ✅ Doğru:
#   CMD ["mariadbd"]  # Foreground, container açık kalır
#
# 💡 ALTERNATİF KOMUTLAR:
# mysqld: Eski isim (hala çalışır)
# mariadbd: Yeni isim (tercih edilen)
# mysqld_safe: Wrapper script (container'da gereksiz)
#
# 🔗 SETUP-MYSQL.SH İLE İLİŞKİ:
# setup-mysql.sh son satırı:
#   exec "$@"
#
# $@ = ["mariadbd", "--user=mysql"]
# exec mariadbd --user=mysql → MariaDB başlar
#
# ⚠️ GÜVENLİK:
# --user=mysql ÇOKTAN ÖNEMLİ!
# Root olarak çalışırsa:
#   - SQL injection ile sistem hacklenebilir
#   - Tüm dosyalara erişim olur
# mysql kullanıcısı olarak:
#   - Sadece /var/lib/mysql erişimi
#   - Sistem dosyalarına dokunamaz
# ============================================================================
CMD [ "mariadbd", "--user=mysql" ]

# ============================================================================
# ÖZET - MARİADB DOCKERFILE'DAN ÖĞRENDİKLERİMİZ
# ============================================================================
#
# 1. FROM: Base image seç (debian:bullseye)
# 2. RUN: Komut çalıştır (paket kur, izin ayarla)
# 3. COPY: Dosya kopyala (config, script)
# 4. chmod/chown: İzinleri ayarla (güvenlik)
# 5. ENTRYPOINT: Ana script (kurulum)
# 6. CMD: Daemon başlat (mariadbd)
# 7. Layer optimization: Komutları birleştir (&&)
# 8. exec "$@": Process ID'yi daemon'a ver
# 9. --user=mysql: Root olarak çalıştırma! (güvenlik)
# 10. Foreground process: Container açık kalsın
#
# BUILD SIRASI:
# 1. Debian indir
# 2. MariaDB kur
# 3. Config kopyala
# 4. İzinleri ayarla
# 5. Script kopyala
# 6. Image hazır!
#
# ÇALIŞMA SIRASI:
# 1. Container başlar
# 2. ENTRYPOINT: setup-mysql.sh
# 3. Veritabanı kur
# 4. exec "$@" → CMD
# 5. mariadbd başlar
# 6. Port 3306 dinlemeye başlar
# 7. WordPress bağlanabilir!
#
# ============================================================================
