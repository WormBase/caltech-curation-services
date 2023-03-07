FROM debian:buster-slim

RUN apt-get update && apt-get install -y git libglib2.0-dev libgtk2.0-dev libreadline-dev build-essential flex-old bison libxmu-dev libcurl4-openssl-dev
RUN git clone https://github.com/richarddurbin/acedb.git acedb && cd acedb && ln -s wmake/makefile Makefile && export ACEDB_MACHINE=LINUX_64 && make
ENV PATH="${PATH}:/acedb/bin.LINUX_64"

CMD ["bash", "-c", "tail -f /dev/null"]



