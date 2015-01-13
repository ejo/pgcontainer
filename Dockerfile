# BUILD-USING: docker build -t ejo/pg .
# RUN-USING: docker run -d -p 6001:6001 --name pg ejo/pg
# psql in with: psql -h 0.0.0.0 -p 6001 -U cataphor cataphordb

FROM ubuntu:14.04
MAINTAINER Eric Ongerth "ericongerth@gmail.com"

# Import public key
# ADD .ssh/id_rsa /root/.ssh/id_rsa

# Update package lists
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get update

# Deal with base ubuntu box's lack of locale+language defaults
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y install language-pack-en
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
RUN update-locale LANG=en_US.UTF-8

# General system catch-up
RUN apt-get upgrade -y

# Install postgresql
RUN apt-get install -y postgresql-9.4 postgresql-contrib-9.4

# Set access, listening, port
RUN echo "host	all	 all	0.0.0.0/0	md5" >> /etc/postgresql/9.4/main/pg_hba.conf
RUN echo "local all	 all	trust" >> /etc/postgresql/9.4/main/pg_hba.conf
RUN echo "listen_addresses='0.0.0.0'" >> /etc/postgresql/9.4/main/postgresql.conf
RUN echo "port=6001" >> /etc/postgresql/9.4/main/postgresql.conf

USER postgres
RUN service postgresql start &&\
    psql --command "CREATE USER cataphor WITH SUPERUSER PASSWORD 'cataphor';" &&\
    createdb --encoding=UTF8 -O cataphor cataphordb && service postgresql stop

USER root
# Expose pg server port
EXPOSE 6001

VOLUME ["/etc/postgresql", "/var/log/postgresql"]

CMD ["/bin/su", "postgres", "-c", "/usr/lib/postgresql/9.4/bin/postgres -D /var/lib/postgresql/9.4/main -c config_file=/etc/postgresql/9.4/main/postgresql.conf"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
