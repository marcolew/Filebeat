# Use Alpine Linux as the base image
FROM alpine:latest

# Install necessary packages for building Filebeat
RUN apk update && \
    apk add bash ca-certificates wget gcc musl-dev go make

# Add a non-root user
RUN adduser -D -u 1000 filebeat
USER filebeat

# Set working directory for Filebeat
WORKDIR /usr/share/filebeat

# Environment variables for Go
ENV GOPATH=/usr/share/filebeat/go
ENV PATH=$PATH:$GOPATH/bin

# Download and compile Filebeat
ARG FILEBEAT_VERSION=7.10.0
RUN wget https://github.com/elastic/beats/archive/v${FILEBEAT_VERSION}.tar.gz -O /tmp/filebeat.tar.gz && \
    mkdir -p $GOPATH/src/github.com/elastic/ && \
    tar xzvf /tmp/filebeat.tar.gz -C $GOPATH/src/github.com/elastic/ && \
    mv $GOPATH/src/github.com/elastic/beats-${FILEBEAT_VERSION} $GOPATH/src/github.com/elastic/beats && \
    cd $GOPATH/src/github.com/elastic/beats/filebeat && \
    make && \
    cp filebeat /usr/share/filebeat/ && \
    rm -rf $GOPATH

# Clean up unnecessary packages and files
USER root
RUN apk del wget gcc musl-dev go make && \
    rm -rf /var/cache/apk/* /tmp/*
USER filebeat

# Copy the Filebeat configuration file
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

# Set the default command to run Filebeat
CMD ["./filebeat", "-e", "-c", "filebeat.yml"]
