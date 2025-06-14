FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PATH="/opt/node/20.4.0/bin:/opt/java/21.0.2/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates lsb-release gnupg software-properties-common \
    libgmp-dev libtinfo5 libblas-dev liblapack-dev libpcre3-dev libncurses5 unzip xz-utils && \
    echo "deb http://deb.debian.org/debian bookworm-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Optional symlink
RUN ln -s /usr/bin/python3.11 /usr/local/bin/python3

### Install Node.js 20.4.0 (prebuilt)
RUN curl -fsSL https://nodejs.org/dist/v20.4.0/node-v20.4.0-linux-x64.tar.xz \
    | tar -xJ -C /opt && mv /opt/node-v20.4.0-linux-x64 /opt/node/20.4.0

### Install OpenJDK 21.0.2
RUN mkdir -p /opt/java/21.0.2 && \
    curl -fsSL https://download.java.net/java/GA/jdk21/9/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz \
    | tar -xz -C /opt/java/21.0.2 --strip-components=1

RUN python3 --version && node --version && java -version

CMD ["bash"]
