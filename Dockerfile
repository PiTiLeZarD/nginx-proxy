FROM nginx:1.19.5@sha256:e0f65235cc7bca84baf18bb5146faa7413225bfd1013b7c72f0b85b153deccb6
MAINTAINER Jonathan Adami <contact@jadami.com>
LABEL creator="Jason Wilder mail@jasonwilder.com"

ENV DOCKER_GEN_VERSION=0.7.4 \
    DOCKER_HOST=unix:///tmp/docker.sock

COPY ./crontab /etc/cron.d/root
COPY ./run-cronjob.sh /usr/local/bin/run-cronjob

# Install python with crossplane, wget, cron and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
    cron \
    python3 python3-pip \
 && pip3 install crossplane \
 && apt-get purge -y python3-pip \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf \
 && mkdir /etc/nginx/node.conf.d \
 && mkdir /etc/nginx/certs \
 && echo "http { include ./*.conf; }" > /etc/nginx/node.conf.d/swarm.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

# Install Dockergen
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/

# nginx healthcheck
COPY healthcheck.conf /etc/nginx/conf.d
HEALTHCHECK CMD /app/nginx-healthcheck.sh

VOLUME ["/etc/nginx/static_files", "/etc/nginx/node.conf.d"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
