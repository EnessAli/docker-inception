FROM debian:bullseye

# Temel imaj: Debian Bullseye

RUN apt-get update && apt-get install -y php-fpm php-mysql wget 
# PHP-FPM, MySQL php uzantısı ve wget kurulur

RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/sendmail && chmod +x /usr/sbin/sendmail
# Bazı paketler sendmail arar; burada basit bir stub oluşturuluyor (gerçek posta gönderimi yok)

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli
# wp-cli : WordPress yönetimi için CLI aracı. Burada indiriliyor ve /usr/local/bin'e taşınıyor

RUN mkdir -p /var/www/html
# Web dizini oluşturulur

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/
# PHP-FPM pool konfigürasyonu kopyalanır (www.conf)

COPY ./tools/wordpress-start.sh /
# Başlatma scripti kopyalanır

RUN chmod +x /wordpress-start.sh
# Script çalıştırılabilir yapılır

WORKDIR /var/www/html
# WORKDIR : sonraki RUN/CMD/ENTRYPOINT komutları için çalışma dizinini belirler

ENTRYPOINT [ "/wordpress-start.sh" ]
# Container başladığında önce bu script çalışacak (ENTRYPOINT)

CMD ["/usr/sbin/php-fpm7.4", "--nodaemonize"]
# CMD : ENTRYPOINT'e argüman olarak verilebilir; burada php-fpm foreground modda çalışacak
