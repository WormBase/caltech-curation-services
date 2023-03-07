FROM debian:buster-slim

RUN apt-get update && apt-get install -y git libglib2.0-dev libgtk2.0-dev libreadline-dev build-essential flex-old bison libxmu-dev libcurl4-openssl-dev
RUN git clone https://github.com/WormBase/acedb.git acedb && cd acedb && ln -s wmake/makefile Makefile && export ACEDB_MACHINE=LINUX_64 && make

RUN mkdir -p ${CALTECH_CURATION_FILES_INTERNAL_PATH}
RUN chmod -R 777 ${CALTECH_CURATION_FILES_INTERNAL_PATH}

ENV PATH="${PATH}:/acedb/bin.LINUX_64"

CMD ["bash", "-c", "tail -f /dev/null"]



