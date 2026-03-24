FROM debian:bullseye

# FROM <image> : Temel image olarak hangi dağıtım/versiyon kullanılacağını belirtir
# 'debian:bullseye' -> Debian 11 (Bullseye) kullanılıyor

RUN apt-get update && apt-get upgrade -y && apt-get install -y mariadb-server
# RUN <komut> : image oluşturulurken bir layer içinde çalıştırılan komut
# - apt-get update : paket listelerini günceller
# - && : önceki komut başarılı olursa sonraki komutu çalıştırır
# - apt-get upgrade -y : var olan paketleri yükseltir (otomatik 'evet' için -y)
# - apt-get install -y mariadb-server : MariaDB server paketini kurar

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d/
# COPY <kaynak> <hedef> : build bağlamından image içine dosya kopyalar
# - './conf/50-server.cnf' : yerel build klasöründeki konfigürasyon
# - '/etc/mysql/mariadb.conf.d/' : MariaDB'nin konfigürasyon dizini

RUN chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf && \
    chown mysql:mysql /etc/mysql/mariadb.conf.d/50-server.cnf && \
    mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld
# Bu RUN bloğu birden fazla dosya/izin ayarı yapar:
# - chmod 644 file : dosya izinlerini 644 yapar (sahibi rw, grup r, diğerleri r)
# - chown mysql:mysql file : dosyanın sahibi ve grubu 'mysql' olarak ayarlanır
# - mkdir -p /var/run/mysqld : dizin yoksa oluşturur (-p üst dizinleri de sağlar)
# - chown -R mysql:mysql /var/run/mysqld : dizin ve içeriğinin sahibi/grubu mysql
# - chmod 755 /var/run/mysqld : dizine girme ve listeleme izinleri verir
# Not: Bu değişiklikler image oluşturma sırasında yapılır; container runtime'da da uygun izin gerekir

COPY ./tools/setup-mysql.sh /
# Setup scriptini image kök dizinine kopyala

RUN chmod +x /setup-mysql.sh
# Çalıştırılabilir yap: chmod +x -> script'in çalıştırılabilmesi için gerekli

ENTRYPOINT [ "/setup-mysql.sh" ]
# ENTRYPOINT : container başladığında çalışacak ana programı belirtir
# - array form kullanımı (JSON array) -> shell genişletmesi yapılmaz, doğrudan exec tarzı çağırma
# - burada script her container başlangıcında çalıştırılacak

CMD [ "mariadbd", "--user=mysql" ]
# CMD : ENTRYPOINT'e argüman olarak verilen veya ENTRYPOINT yoksa çalışacak varsayılan komut
# - Bu Dockerfile'da ENTRYPOINT var, dolayısıyla CMD, ENTRYPOINT'in sonuna argüman olarak geçer
# - 'mariadbd --user=mysql' : MariaDB daemon'ı mysql kullanıcısı ile başlatır
