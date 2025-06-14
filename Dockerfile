# Build Stage: compile all tools
FROM debian:bookworm-slim AS build-env

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      ca-certificates \
      gnupg \
      unzip \
      libgmp-dev \
      libtinfo5 \
      libblas-dev \
      liblapack-dev \
      libpcre3-dev \
      libncurses5 \
      software-properties-common \
      git && \
    rm -rf /var/lib/apt/lists/*

# GCC


# Python
ENV PYTHON_VERSIONS="3.11.4 2.7.18"
RUN for V in $PYTHON_VERSIONS; do \
      curl -fsSL https://www.python.org/ftp/python/$V/Python-$V.tar.xz | tar xJ && \
      cd Python-$V && ./configure --prefix=/opt/python/$V && \
      make -j$(nproc) && make install && \
      cd / && rm -rf Python-$V*; \
    done

# Node.js
ENV NODE_VERSIONS="20.4.0"
RUN for V in $NODE_VERSIONS; do \
      curl -fsSL https://nodejs.org/dist/v$V/node-v$V.tar.gz | tar zx && \
      cd node-v$V && ./configure --prefix=/opt/node/$V && \
      make -j$(nproc) && make install && \
      cd / && rm -rf node-v$V*; \
    done

# OpenJDK
ENV JAVA_VERSIONS="21.0.2"
RUN for V in $JAVA_VERSIONS; do \
      curl -fsSL https://download.java.net/java/GA/jdk$V/9/GPL/openjdk-${V}_linux-x64_bin.tar.gz | tar zx -C /opt/java/$V --strip-components=1 && \
      ln -s /opt/java/$V/bin/java /opt/java/$V/bin/javac; \
    done

# C/C++ via build-essential (already included)

# Clean up build-env
RUN rm -rf /var/lib/apt/lists/*

# Final stage: minimal runtime
FROM debian:bookworm-slim

ENV LANG=C.UTF-8 \
    PATH=/opt/gcc/10.3.0/bin:/opt/python/3.11.4/bin:/opt/node/20.4.0/bin:/opt/java/21.0.2/bin:$PATH

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libgmp-dev libtinfo5 libblas-dev liblapack-dev libpcre3-dev libncurses5 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy compiled toolchains from build-env
COPY --from=build-env /opt/gcc /opt/gcc
COPY --from=build-env /opt/python /opt/python
COPY --from=build-env /opt/node /opt/node
COPY --from=build-env /opt/java /opt/java

# Verify versions at runtime
RUN gcc --version && \
    python3 --version && \
    node --version && \
    java -version

CMD ["bash"]
