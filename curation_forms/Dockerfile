FROM perl:5.18.4-buster
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y apache2
RUN cpanm install DBI Bundle::CPAN Mail::Mailer MIME::Lite Tie::IxHash JSON LWP Math::SigFigs Email::Send::Gmail Text::CSV_XS Dotenv CGI DBD::Pg
RUN a2enmod headers
RUN a2enmod rewrite
RUN a2enmod cgid
RUN ln -f -s /usr/local/bin/perl /usr/bin/perl

RUN mkdir -p /usr/lib/cgi-bin
COPY curation_forms/cgi_files/ /usr/lib/cgi-bin
COPY curation_forms/apache_conf/apache2.conf /etc/apache2/apache2.conf
COPY curation_forms/apache_conf/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY curation_forms/apache_conf/httpd.conf /etc/apache2/httpd.conf
COPY .env /usr/lib/cgi-bin/
COPY curation_forms/Jex.pm /usr/share/perl/5.18.2/Jex.pm
COPY curation_forms/cgi_files/test_perl.cgi /usr/lib/cgi-bin/test_perl.cgi
RUN chmod 755 /usr/lib/cgi-bin/test_perl.cgi
RUN chmod 755 /usr/lib/cgi-bin/ontology_annotator.cgi

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
