FROM perl:5.18.4-buster
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y apache2 vim
ENV TZ="America/Los_Angeles"
RUN cpanm install DBI Bundle::CPAN Mail::Mailer MIME::Lite Tie::IxHash JSON LWP Math::SigFigs Email::Send::Gmail Text::CSV_XS Dotenv CGI DBD::Pg
RUN a2enmod headers
RUN a2enmod rewrite
RUN a2enmod cgid
#RUN ln -f -s /usr/local/bin/perl /usr/bin/perl

#RUN mkdir -p /usr/lib/cgi-bin/oa
#COPY website/cgi_files/ /usr/lib/cgi-bin/
COPY website/apache_conf/apache2.conf /etc/apache2/apache2.conf
COPY website/apache_conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY website/apache_conf/httpd.conf /etc/apache2/httpd.conf
COPY .env /usr/lib/.env
COPY website/Jex.pm /usr/local/lib/perl5/5.18.4/Jex.pm
RUN chown -R www-data:www-data /usr/lib/cgi-bin/
RUN find /usr/lib/cgi-bin/ \( -name "*.cgi" -o -name "*.pl" \) -exec chmod +x {} \;
RUN chmod -R a+r /usr/lib/cgi-bin/
RUN mkdir -p /etc/user_files

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
