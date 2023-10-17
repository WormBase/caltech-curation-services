FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y wget unzip
RUN wget https://github.com/fstab/grok_exporter/releases/download/v1.0.0.RC5/grok_exporter-1.0.0.RC5.linux-amd64.zip
RUN unzip grok_exporter-1.0.0.RC5.linux-amd64.zip
WORKDIR grok_exporter-1.0.0.RC5.linux-amd64
CMD ["./grok_exporter", "-config=/grok/config.yml"]
