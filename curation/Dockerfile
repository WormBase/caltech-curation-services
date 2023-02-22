FROM perl:5.18.4-buster
ARG SSH_ACEDB_PASSWORD=""
ARG CALTECH_CURATION_FILES_INTERNAL_PATH=/usr/caltech_curation_files
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y apache2 vim openssh-server makepasswd zsh
ENV TZ="America/Los_Angeles"
RUN useradd -rm -d /home/acedb -s /bin/bash -p $(echo "${SSH_ACEDB_PASSWORD}" | makepasswd --crypt-md5 --clearfrom - | awk '{print $2}') acedb
RUN mkdir -p ${CALTECH_CURATION_FILES_INTERNAL_PATH}
RUN chmod -R 777 ${CALTECH_CURATION_FILES_INTERNAL_PATH}
RUN cpanm install DBI Bundle::CPAN Mail::Mailer MIME::Lite Tie::IxHash JSON LWP Math::SigFigs Email::Send::Gmail Text::CSV_XS Dotenv CGI DBD::Pg
RUN a2enmod headers
RUN a2enmod rewrite
RUN a2enmod cgid
RUN a2enmod ssl

COPY curation/website/apache_conf/apache2.conf /etc/apache2/apache2.conf
COPY curation/website/apache_conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY curation/website/apache_conf/000-default-le-ssl.conf /etc/apache2/sites-enabled/000-default-le-ssl.conf
COPY curation/website/apache_conf/options-ssl-apache.conf /etc/apache2/options-ssl-apache.conf
COPY curation/website/apache_conf/httpd.conf /etc/apache2/httpd.conf
COPY curation/scripts/perl_modules/Jex.pm /usr/local/lib/perl5/5.18.4/Jex.pm
RUN touch /etc/apache2/additional_listeners.conf
RUN chown -R www-data:www-data /usr/lib/cgi-bin/
RUN find /usr/lib/cgi-bin/ \( -name "*.cgi" -o -name "*.pl" \) -exec chmod +x {} \;
RUN chmod -R a+r /usr/lib/cgi-bin/
RUN mkdir -p /etc/user_files

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80
EXPOSE 22

ENV CALTECH_CURATION_FILES_INTERNAL_PATH ""
ENV HOST_NAME=""
ENV SSL_PORT="443"
CMD ["/bin/bash", "-c", "echo \"export CALTECH_CURATION_FILES_INTERNAL_PATH=${CALTECH_CURATION_FILES_INTERNAL_PATH}\" >> /etc/apache2/envvars; \
                         echo \"export HOST_NAME=${HOST_NAME}\" >> /etc/apache2/envvars; \
                         echo \"export SSL_PORT=${SSL_PORT}\" >> /etc/apache2/envvars; \
                         if [[ \"${SSL_PORT}\" -ne \"443\" ]]; then echo \"Listen ${SSL_PORT}\" > /etc/apache2/additional_listeners.conf; fi; \
                         service apache2 start; \
                         service ssh start; \
                         tail -f /dev/null"]
