FROM debian:bullseye

# Temel image: Debian Bullseye kullanılıyor
# FROM <image> -> build sırasında katmanlı olarak bu image'ın üzerine eklenir

RUN apt-get update && apt-get install -y nginx openssl
# RUN satırı: imaj build edilirken paketleri kurar
# - apt-get update : paket listelerini günceller
# - apt-get install -y nginx openssl : nginx web sunucusu ve openssl kurulur

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=TR/ST=Kocaeli/L=Kocaeli/O=42/OU=42/CN=egermen.42.fr"
# Bu komut self-signed SSL sertifikası üretir:
# - openssl req : sertifika imzalama isteği oluştur
# - -x509 : self-signed sertifika üret
# - -nodes : private key şifreleme (no DES) - parola sormaz
# - -days 365 : sertifika 365 gün geçerli
# - -newkey rsa:2048 : yeni 2048-bit RSA anahtarı oluştur
# - keyout : özel anahtarın kaydedileceği dosya
# - out : sertifikanın kaydedileceği dosya
# - -subj : sertifika için DN (Distinguished Name) alanı, interaktif olmayı atlar

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
# COPY: yerel build bağlamındaki nginx.conf dosyasını image içindeki ilgili konuma kopyalar

COPY ./tools/nginx_start.sh /
# Setup scriptini (başlatıcı) image köküne kopyalar

RUN chmod +x /nginx_start.sh
# Script'i çalıştırılabilir yapar (x bitini set eder)

EXPOSE 443
# EXPOSE : container'ın dış dünyaya hangi portları dinleyeceğini belirtsede
# gerçek port yönlendirmesi docker run -p ile yapılır. 443 SSL için standart porttur.

ENTRYPOINT ["/nginx_start.sh"]
# ENTRYPOINT: container her başladığında çalışacak komut. Burada startup script çalışır.

CMD ["nginx", "-g", "daemon off;"]
# CMD: ENTRYPOINT mevcutsa onun argümanları olarak kullanılır; yoksa varsayılan komut olur
# "nginx -g 'daemon off;'" -> nginx'i ön planda çalıştır (PID 1 olarak) böylece container kapanmaz
