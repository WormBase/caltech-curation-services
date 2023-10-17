FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y wget unzip
RUN wget https://github.com/fstab/grok_exporter/releases/download/v1.0.0.RC5/grok_exporter-1.0.0.RC5.linux-amd64.zip
RUN unzip grok_exporter-1.0.0.RC5.linux-amd64.zip
WORKDIR grok_exporter-1.0.0.RC5.linux-amd64
COPY container_startup_setup.sh .
CMD ["/bin/bash", "container_startup_setup.sh"]
