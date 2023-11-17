FROM nginx:1.21.5

RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install -y certbot cron

ADD reverse_proxy/crontab /etc/cron.d/certbot_crontab
RUN chmod 0644 /etc/cron.d/certbot_crontab
RUN crontab /etc/cron.d/certbot_crontab

CMD cron && tail -f /dev/null