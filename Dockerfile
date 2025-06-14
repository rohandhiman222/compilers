FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PATH="/opt/python/3.11.4/bin:/opt/python/2.7.18/bin:/opt/node/20.4.0/bin:/opt/java/21.0.2/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates libgmp-dev libtinfo5 libblas-dev liblapack-dev \
    libpcre3-dev libncurses5 unzip xz-utils && \
    rm -rf /var/lib/apt/lists/*

### Install Python 3.11.4 (prebuilt from official release)
RUN curl -fsSL https://www.python.org/ftp/python/3.11.4/python-3.11.4-linux-x86_64.tar.xz \
    | tar -xJ -C /opt && mv /opt/python-3.11.4-linux-x86_64 /opt/python/3.11.4

### Install Python 2.7.18 (prebuilt)
RUN curl -fsSL https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz | tar xz && \
    cd Python-2.7.18 && ./configure --prefix=/opt/python/2.7.18 && make -j$(nproc) && make install && \
    cd / && rm -rf Python-2.7.18*

### Install Node.js 20.4.0 (prebuilt)
RUN curl -fsSL https://nodejs.org/dist/v20.4.0/node-v20.4.0-linux-x64.tar.xz \
    | tar -xJ -C /opt && mv /opt/node-v20.4.0-linux-x64 /opt/node/20.4.0

### Install OpenJDK 21.0.2 (prebuilt)
RUN mkdir -p /opt/java/21.0.2 && \
    curl -fsSL https://download.java.net/java/GA/jdk21/9/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz \
    | tar -xz -C /opt/java/21.0.2 --strip-components=1

### Version checks
RUN python3 --version && python2 --version && node --version && java -version

CMD ["bash"]
