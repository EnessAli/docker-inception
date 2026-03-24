# ============================================================================
# MAKEFILE - PROJE OTOMASYON DOSYASI
# ============================================================================
#
# 📌 MAKEFILE NEDİR?
# Makefile, tekrarlayan komutları otomatikleştiren bir araçtır.
# "make" komutu ile hedefleri (targets) çalıştırırsın.
#
# 🤔 NEDEN MAKEFILE?
# Docker Compose komutları uzun ve karmaşık olabilir:
#   docker-compose -f ./srcs/docker-compose.yml up --build -d
# Her seferinde yazmak yerine sadece "make" yazıyorsun!
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# TV kumandası gibi düşün:
# - Kanallar = Hedefler (up, down, clean vs.)
# - Kumanda tuşuna bas = "make up" yaz
# - TV karmaşık komutları kendisi halleder
#
# 🔧 TEKNİK DETAY:
# Make aracı, hedefleri ve bağımlılıkları takip eder.
# Sadece değişen kısımları yeniden yapar (akıllı).
#
# ============================================================================

# ============================================================================
# DEĞİŞKENLER (VARIABLES)
# ============================================================================

# COMPOSE_DIR: docker-compose.yml dosyasının bulunduğu dizin
# := operatörü: Değişkeni hemen ata (immediate assignment)
# = operatörü alternatifi: Lazy evaluation (kullanıldığında değerlendirilir)
COMPOSE_DIR := ./srcs

# ============================================================================
# HEDEF: all (Varsayılan hedef)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Sadece "make" yazdığında çalışan varsayılan hedef.
# "up" hedefini çağırır (projeyi başlatır).
#
# 🤔 NEDEN "all"?
# Make geleneği: İlk hedef veya "all" hedefi varsayılandır.
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoran menüsünde "Günün Önerisi" gibi.
# Menüye bakınca ilk gördüğün ve en çok sipariş edilen.
#
# KULLANIM:
#   make        ← Bu kadar! "all" çalışır, "up" tetiklenir
#   make all    ← Aynı şey
# ============================================================================
all: up

# ============================================================================
# HEDEF: up (Projeyi Başlat)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# 1. Veri klasörlerini oluşturur
# 2. Docker container'larını başlatır (build + run)
#
# 🤔 NEDEN BU KOMUTLAR?
# mkdir -p: Klasör yoksa oluştur, varsa hata verme (-p parametresi)
# --build: Her seferinde image'ları yeniden oluştur (güncel kod)
# -d: Detached mode (arka planda çalış, terminal'i bloke etme)
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoran açmak gibi:
# 1. Mutfağı hazırla (mkdir klasörler)
# 2. Personeli çağır (docker-compose up)
# 3. Kapıları aç ve arka planda çalış (-d)
#
# 🔧 TEKNİK DETAY:
# ${HOME}: Kullanıcının ev dizini (/home/username veya C:\Users\username)
# data/wordpress: WordPress dosyaları burada saklanır (wp-content, uploads vs.)
# data/mariadb: Veritabanı dosyaları burada saklanır (tablolar, indexler)
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# - docker-compose.yml: Bu klasörleri volume olarak kullanır
# - WordPress container: /var/www/html → ${HOME}/data/wordpress
# - MariaDB container: /var/lib/mysql → ${HOME}/data/mariadb
#
# ⚠️ ÖNEMLİ:
# Bu klasörler SİLİNMEMELİ! Tüm verileriniz burada.
# Container silsen bile veriler kalır.
#
# KULLANIM:
#   make up
# ============================================================================
up:
	mkdir -p ${HOME}/data/wordpress
	mkdir -p ${HOME}/data/mariadb
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml up --build -d

# ============================================================================
# HEDEF: down (Projeyi Durdur ve Kaldır)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Tüm container'ları durdurur ve siler.
# Network'leri siler.
# Volume'leri SİLMEZ! (--volumes yok)
#
# 🤔 NEDEN "down"?
# "up"ın tersi. Container'ları tamamen kaldırır.
# "stop" sadece durdurur, "down" siler.
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Restoranı kapatmak gibi:
# - Müşterileri gönder
# - Personeli eve yolla
# - Kapıyı kilitle
# Ama mutfak ekipmanı ve yemekler depoda kalır (volume'ler)
#
# 🔧 TEKNİK DETAY:
# Container'lar silinir ama image'lar kalır.
# Tekrar "up" yapınca hızlı başlar (image build'e gerek yok).
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# ${HOME}/data klasörleri DOKUNULMAZdocker-compose down sadece container'ları siler.
#
# KULLANIM:
#   make down
# ============================================================================
down:
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml down

# ============================================================================
# HEDEF: stop (Container'ları Durdur)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Container'ları durdurur ama SİLMEZ.
#
# 🤔 "down" vs "stop" FARKI?
# stop:  Container durdurulur, silinmez → "start" ile devam edilir
# down:  Container durdurulur VE silinir → "up" ile yeniden oluşturulur
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# stop = Dükkanı geçici kapatmak (akşam kapanış)
# down = Dükkanı tamamen boşaltmak (taşınma)
#
# 🔧 TEKNİK DETAY:
# Container'ın durumu (state) korunur.
# "docker-compose start" ile aynı yerden devam eder.
#
# NE ZAMAN KULLANILIR?
# - Geçici olarak durdurmak istersen (güncelleme, yedekleme)
# - Sistem kaynaklarını serbest bırakmak istersen
#
# KULLANIM:
#   make stop
#   # Sonra tekrar başlatmak için:
#   docker-compose -f ./srcs/docker-compose.yml start
# ============================================================================
stop:
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml stop

# ============================================================================
# HEDEF: restart (Yeniden Başlat)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Önce "down" sonra "up" çalıştırır.
# Tüm container'ları tamamen yeniler.
#
# 🤔 NEDEN İKİ HEDEF ÇAĞIRIYOR?
# Makefile'da hedefler birbirini çağırabilir.
# "restart: down up" → down hedefi çalış, sonra up hedefi çalış
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Bilgisayarı yeniden başlatmak gibi:
# 1. Kapat (down)
# 2. Aç (up)
# Tüm sistem temiz başlar.
#
# 🔧 TEKNİK DETAY:
# Container'lar tamamen silinip yeniden oluşturulur.
# Image'lar yeniden build edilir (up --build sayesinde).
#
# NE ZAMAN KULLANILIR?
# - Kod değişikliği yaptın
# - Ayar dosyasını güncelledin
# - Container takılı kaldı
#
# KULLANIM:
#   make restart
# ============================================================================
restart: down up

# ============================================================================
# HEDEF: build (Image'ları Yeniden Oluştur)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Sadece image'ları build eder, container başlatmaz.
#
# 🤔 NEDEN SADECE BUILD?
# Bazen sadece image'ı test etmek istersin.
# Container çalıştırmadan önce build hatalarını görmek için.
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Yemek tarifini hazırlamak ama henüz pişirmemek gibi.
# Malzemeleri hazırla, sonra gerektiğinde pişir.
#
# 🔧 TEKNİK DETAY:
# docker-compose build komutu:
# - Dockerfile'ları okur
# - Her servis için image oluşturur
# - Cache kullanır (değişmeyen layer'lar hızlı)
#
# NE ZAMAN KULLANILIR?
# - Dockerfile değiştirdin ama henüz çalıştırmak istemiyorsun
# - Build süresini test etmek istiyorsun
# - CI/CD pipeline'da (test aşaması)
#
# KULLANIM:
#   make build
# ============================================================================
build:
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml build

# ============================================================================
# HEDEF: clean (Temizlik - Volume'ler Hariç)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Container'ları, network'leri ve volume'leri siler.
# Orphan container'ları da temizler.
#
# 🤔 PARAMETRELER NEDİR?
# --volumes: Volume'leri de sil (VERİLER GİDER!)
# --remove-orphans: docker-compose.yml'de olmayan eski container'ları sil
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Evi temizlemek gibi:
# - Eşyaları topla (container'lar)
# - Odaları düzenle (network'ler)
# - Çöpleri at (orphan container'lar)
# - Depoyu boşalt (volume'ler) ← DİKKAT! Bu verilerini siler!
#
# 🔧 TEKNİK DETAY:
# Orphan container: Eski docker-compose.yml'den kalan container
# Örnek: Servis ismini değiştirdin, eski container kaldı
#
# ⚠️ ÖNEMLİ UYARI:
# Bu komut VERİLERİNİ SİLER!
# ${HOME}/data klasörleri KALIR ama volume içeriği gider.
# Emin değilsen "make down" kullan!
#
# NE ZAMAN KULLANILIR?
# - Sıfırdan başlamak istiyorsun
# - Test verilerini temizlemek istiyorsun
# - Disk alanı kazanmak istiyorsun
#
# KULLANIM:
#   make clean
#   # Emin misin? Veriler gidecek!
# ============================================================================
clean:
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml down --volumes --remove-orphans

# ============================================================================
# HEDEF: fclean (Full Clean - Tam Temizlik)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Her şeyi siler: Container, network, volume, image VE data klasörleri!
#
# 🤔 "clean" vs "fclean" FARKI?
# clean:  Volume'leri siler (container içi)
# fclean: clean + Image'ları + ${HOME}/data klasörlerini siler
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Evi satmadan önce kapsamlı temizlik:
# - Tüm eşyaları at (container, volume)
# - Depoyu boşalt (data klasörleri)
# - Mobilyaları söktür (image'lar)
# Hiçbir iz kalmasın!
#
# 🔧 TEKNİK DETAY:
# @sudo: @ işareti komutun kendisini göstermez (sadece sonuç)
# rm -rf: Zorla ve recursive sil
# --rmi all: Tüm image'ları sil (rmi = remove image)
#
# ⚠️ ÇOK ÖNEMLİ UYARI:
# Bu komut HER ŞEYİ SİLER!
# - Tüm WordPress makalelerin
# - Tüm veritabanı kayıtların
# - Tüm yüklediğin dosyalar
# - Tüm image'lar (yeniden build gerekir)
#
# 🔗 DİĞER DOSYALARLA İLİŞKİ:
# Sonra "make" yaparsan:
# 1. Image'lar sıfırdan build edilir (yavaş)
# 2. Container'lar yeni oluşturulur
# 3. WordPress yeniden kurulur
# 4. Veritabanı sıfırdan oluşturulur
#
# NE ZAMAN KULLANILIR?
# - Projeyi tamamen sıfırlamak istiyorsun
# - Ciddi bir hata oldu, sıfırdan başlayacaksın
# - Submission öncesi temiz başlangıç
#
# KULLANIM:
#   make fclean
#   # 3 kere düşün, sonra yap!
# ============================================================================
fclean: clean
	@sudo rm -rf ${HOME}/data
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml down --rmi all --volumes --remove-orphans

# ============================================================================
# HEDEF: re (Remake - Yeniden Yap)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Tamamen sıfırlar ve yeniden başlatır.
# fclean + all = Her şeyi sil + Sıfırdan kur
#
# 🤔 NEDEN "re"?
# 42 geleneği: "remake" kısaltması
# Projeyi tamamen yenilemek için tek komut.
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Evi yıkıp yeniden inşa etmek gibi:
# 1. Her şeyi yık (fclean)
# 2. Sıfırdan inşa et (all)
# Yepyeni bir başlangıç!
#
# 🔧 TEKNİK DETAY:
# Makefile hedefleri sırayla çalışır:
# 1. fclean çalışır (her şey temizlenir)
# 2. all çalışır (up tetiklenir, her şey yeniden kurulur)
#
# NE ZAMAN KULLANILIR?
# - Kod değişikliği sonrası temiz başlangıç
# - Cache problemleri var
# - "Bilgisayarı kapat aç" felsefesi
#
# KULLANIM:
#   make re
#   # Çay demle, 2-3 dakika sürebilir (build + kurulum)
# ============================================================================
re: fclean all

# ============================================================================
# HEDEF: logs (Logları Göster)
# ============================================================================
#
# 📌 BU HEDEF NE YAPAR?
# Tüm container'ların log çıktılarını gösterir.
# -f parametresi: Follow (canlı takip et)
#
# 🤔 LOG NEDİR?
# Container'ların yazdırdığı mesajlar:
# - Hata mesajları
# - Bilgi mesajları
# - Debug çıktıları
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# Güvenlik kamerası kayıtlarını izlemek gibi:
# - Ne olduğunu görebilirsin
# - Hataları yakalayabilirsin
# - Canlı olayları takip edebilirsin
#
# 🔧 TEKNİK DETAY:
# -f: Follow mode, Ctrl+C ile çıkılır
# Tüm servisler: mariadb, wordpress, nginx logları birlikte
# Renkli çıktı: Her servis farklı renk
#
# NE ZAMAN KULLANILIR?
# - Hata ayıklama (debugging)
# - Container neden başlamadı?
# - Veritabanı bağlantı problemi var mı?
# - WordPress kurulumu başarılı mı?
#
# KULLANIM:
#   make logs
#   # Ctrl+C ile çık
#
# ALTERNATF:
#   docker-compose logs -f mariadb    # Sadece MariaDB
#   docker-compose logs -f --tail=50  # Son 50 satır
# ============================================================================
logs:
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml logs -f

# ============================================================================
# .PHONY - Sahte Hedefler (Phony Targets)
# ============================================================================
#
# 📌 .PHONY NEDİR?
# Make'e şunu söyler: "Bu hedefler dosya ismi değil, komuttur!"
#
# 🤔 NEDEN GEREKLİ?
# Eğer projende "clean" isimli bir DOSYA olsaydı:
# - "make clean" komutu dosyayı kontrol eder
# - Dosya varsa "clean is up to date" der ve çalışmaz
# .PHONY ile bu problem önlenir.
#
# ☕ GÜNLÜK HAYAT ÖRNEĞİ:
# İsim karışıklığını önlemek gibi:
# - Arkadaşın "Fatih" (kişi)
# - İstanbul'da "Fatih" ilçesi var
# .PHONY der ki: "Ben kişiden bahsediyorum, ilçeden değil!"
#
# 🔧 TEKNİK DETAY:
# Make normalde hedeflerin dosya olup olmadığını kontrol eder.
# .PHONY, bu kontrolü atlar, her zaman hedefi çalıştırır.
#
# ⚠️ BEST PRACTICE:
# Dosya oluşturmayan tüm hedefleri .PHONY'e ekle!
#
# ALTERNATİF:
# .PHONY yazmasaydın ve "clean" dosyası olsaydı:
#   $ touch clean          # "clean" dosyası oluştur
#   $ make clean           # Çalışmaz! "clean is up to date"
#   $ rm clean             # Dosyayı sil
#   $ make clean           # Şimdi çalışır
#
# .PHONY ile bu problem yok:
#   $ touch clean
#   $ make clean           # Gene çalışır!
# ============================================================================
.PHONY: all up down stop restart build clean fclean re logs

# ============================================================================
# KULLANIM ÖRNEKLERİ
# ============================================================================
#
# Projeyi başlat:
#   make          veya    make up
#
# Logları izle:
#   make logs
#
# Yeniden başlat (kod değişikliği sonrası):
#   make restart
#
# Temizlik (veriler kalır):
#   make down
#
# Tam temizlik (her şey gider):
#   make fclean
#
# Sıfırdan kur:
#   make re
#
# Sadece durdur (silinmez):
#   make stop
#
# Sadece image build et:
#   make build
#
# ============================================================================
