# setup build arguments for version of dependencies to use
ARG NGINX_VERSION=
ARG GO_VERSION=1.21.0

ARG DOCKER_GEN_VERSION=0.10.6
ARG FOREGO_VERSION=0.17.2

# Use a specific version of golang to build both binaries
FROM golang:$GO_VERSION as gobuilder

# Build docker-gen from scratch
FROM gobuilder as dockergen

# Download the sources for the given version
ARG DOCKER_GEN_VERSION
ADD https://github.com/nginx-proxy/docker-gen/archive/refs/tags/${DOCKER_GEN_VERSION}.tar.gz sources.tar.gz

RUN tar -xzf sources.tar.gz \
   && mkdir -p /go/src/github.com/jwilder/ \
   && mv docker-gen-* /go/src/github.com/jwilder/docker-gen \
   && cd /go/src/github.com/jwilder/docker-gen \
   && go get -v ./... \
   && CGO_ENABLED=0 GOOS=linux go build -ldflags "-X main.buildVersion=${DOCKER_GEN_VERSION}" ./cmd/docker-gen

FROM gobuilder as forego

ARG FOREGO_VERSION
ADD https://github.com/nginx-proxy/forego/archive/refs/tags/v${FOREGO_VERSION}.tar.gz sources.tar.gz

ENV GO111MODULE=auto

RUN tar -xzf sources.tar.gz \
   && mkdir -p /go/src/github.com/ddollar/ \
   && mv forego-* /go/src/github.com/ddollar/forego \
   && cd /go/src/github.com/ddollar/forego/ \
   && go get -v ./... \
   && CGO_ENABLED=0 GOOS=linux go build -o forego .

FROM nginx:${NGINX_VERSION}
LABEL maintainer="Jonathan Adami <contact@jadami.com>"
LABEL creator="Jason Wilder <mail@jasonwilder.com>"

ENV DOCKER_HOST=unix:///tmp/docker.sock

COPY ./crons/crontab /etc/cron.d/root
COPY ./crons/run-cronjob.sh /usr/local/bin/run-cronjob

# Install python with crossplane, wget, cron and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
    cron \
    python3 python3.11-venv \
 && python3 -m venv $HOME/.venvs/crossplane \
 && /root/.venvs/crossplane/bin/pip3 install crossplane \
 && apt-get purge -y python3.11-venv \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for very long server names
COPY ./nginx/network_internal.conf /etc/nginx/
COPY ./nginx/healthcheck.conf /etc/nginx/conf.d
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf \
 && mkdir /etc/nginx/node.conf.d \
 && mkdir /etc/nginx/certs \
 && echo "http { include ./*.conf; }" > /etc/nginx/node.conf.d/swarm.conf

# Install Forego / Dockergen
COPY --from=forego /go/src/github.com/ddollar/forego/forego /usr/local/bin/forego
COPY --from=dockergen /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/docker-gen

COPY ./app/ /app/
WORKDIR /app/

HEALTHCHECK CMD /app/nginx-healthcheck.sh
VOLUME ["/etc/nginx/static_files", "/etc/nginx/node.conf.d"]
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
