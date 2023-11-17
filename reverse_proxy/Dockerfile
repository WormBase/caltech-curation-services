FROM nginx:1.21.5

RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install certbot

CMD ["/bin/bash", "container_startup_setup.sh"]