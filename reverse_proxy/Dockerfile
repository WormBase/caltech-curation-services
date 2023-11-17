FROM nginx:1.21.5

RUN apt-get update && \
    apt-get install -y \
        cron \
        && \
    echo '#!/bin/bash\n\ncron && /docker-entrypoint.sh "$@"' >> entrypoint-wrapper.sh && \
    chmod +x /entrypoint-wrapper.sh

ENTRYPOINT ["/entrypoint-wrapper.sh"]

ADD reverse_proxy/crontab /etc/cron.d/certbot_crontab
RUN chmod 0644 /etc/cron.d/certbot_crontab
RUN crontab /etc/cron.d/certbot_crontab

CMD ["nginx", "-g", "daemon off;"]