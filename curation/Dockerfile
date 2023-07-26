FROM perl:5.18.4-buster
ARG SSH_ACEDB_PASSWORD=""
ARG SSH_CITACE_PASSWORD=""
ARG CALTECH_CURATION_FILES_INTERNAL_PATH=/usr/caltech_curation_files
ARG DEBIAN_FRONTEND=noninteractive
ARG AWS_ACCESS_KEY_ID=""
ARG AWS_SECRET_ACCESS_KEY=""
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -q -y apache2 vim openssh-server makepasswd zsh sendmail cron git libglib2.0-dev libgtk2.0-dev libreadline-dev build-essential flex-old bison libxmu-dev libcurl4-openssl-dev xauth default-jdk postgresql-client debconf locales rsync jq restic mlocate acl
ENV TZ="America/Los_Angeles"
RUN mkdir -p ${CALTECH_CURATION_FILES_INTERNAL_PATH}
RUN chmod -R 777 ${CALTECH_CURATION_FILES_INTERNAL_PATH}
RUN useradd -rm -d ${CALTECH_CURATION_FILES_INTERNAL_PATH} -s /bin/bash -p $(echo "${SSH_ACEDB_PASSWORD}" | makepasswd --crypt-md5 --clearfrom - | awk '{print $2}') acedb
RUN useradd -rm -d ${CALTECH_CURATION_FILES_INTERNAL_PATH}/citace -s /bin/bash -p $(echo "${SSH_CITACE_PASSWORD}" | makepasswd --crypt-md5 --clearfrom - | awk '{print $2}') citace
RUN cpanm install --force DBI Bundle::CPAN Mail::Mailer MIME::Lite Tie::IxHash JSON JSON::XS LWP::Protocol::https LWP Math::SigFigs Email::Send::Gmail Text::CSV_XS Dotenv CGI DBD::Pg Mail::Sendmail
RUN wget https://cpan.metacpan.org/authors/id/L/LD/LDACHARY/Text-Unaccent-1.08.tar.gz && tar xvf Text-Unaccent-1.08.tar.gz && cd Text-Unaccent-1.08 && sed -i 's/int utf16_length = 0;/size_t utf16_length = 0;/;s/int utf16_unaccented_length = 0;/size_t utf16_unaccented_length = 0;/' unac.c && sed -i 's/static int buffer_length;/static size_t buffer_length;/' Unaccent.xs && perl Makefile.PL && make && make test && make install && cd .. && rm -rf Text-Unaccent-1.08*
RUN a2enmod headers
RUN a2enmod rewrite
RUN a2enmod cgid
RUN a2enmod ssl
RUN a2enmod proxy
RUN a2enmod proxy_http

RUN git clone https://github.com/WormBase/acedb.git acedb && cd acedb && ln -s wmake/makefile Makefile && export ACEDB_MACHINE=LINUX_64 && make
RUN git clone https://github.com/alliance-genome/agr_literature_service.git agr_literature_service
RUN cp agr_literature_service/file_uploader/upload_files.sh /bin/agr_referencefile_bulk_uploader
RUN chmod +x /bin/agr_referencefile_bulk_uploader

COPY curation/website/apache_conf/apache2.conf /etc/apache2/apache2.conf
COPY curation/website/apache_conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY curation/website/apache_conf/000-default-le-ssl.conf /etc/apache2/sites-enabled/000-default-le-ssl.conf
COPY curation/website/apache_conf/options-ssl-apache.conf /etc/apache2/options-ssl-apache.conf
COPY curation/website/apache_conf/httpd.conf /etc/apache2/httpd.conf
COPY curation/scripts/perl_modules/Jex.pm /usr/local/lib/perl5/5.18.4/Jex.pm
COPY curation/container_startup_setup.sh .
COPY curation/perl_wrapper.sh /usr/local/sbin/perl
RUN chmod +x /usr/local/sbin/perl
COPY curation/.zshrc /root/.zshrc
COPY curation/.vimrc /root/.vimrc
COPY curation/restic_excludes.txt /restic_excludes.txt
RUN touch /etc/apache2/additional_listeners.conf
RUN chown -R www-data:www-data /usr/lib/cgi-bin/
RUN find /usr/lib/cgi-bin/ \( -name "*.cgi" -o -name "*.pl" \) -exec chmod +x {} \;
RUN chmod -R a+r /usr/lib/cgi-bin/
RUN mkdir -p /etc/user_files

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80
EXPOSE 22

ENV CALTECH_CURATION_FILES_INTERNAL_PATH ""
ENV HOST_NAME=""
ENV SSL_PORT="443"
CMD ["/bin/bash", "container_startup_setup.sh"]
