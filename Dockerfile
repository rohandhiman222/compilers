# Use the latest Judge0 compilers image as the base.
# You can specify a more precise version if needed, e.g., judge0/compilers:1.X.X
FROM judge0/compilers:latest

# Set environment variables for non-interactive installations.
ENV DEBIAN_FRONTEND=noninteractive

# --- General System Updates and Dependencies ---
# Update apt package lists and install necessary tools like curl, gnupg for language installations.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# --- Install Latest Node.js (v24.x) ---
# Add NodeSource GPG key and repository for Node.js v24.x using the updated method.
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    NODE_MAJOR=24 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    # Update apt again to include the new Node.js repository
    apt-get update && \
    # Install Node.js and npm
    apt-get install -y --no-install-recommends nodejs && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*

# Verify Node.js and npm versions
RUN node -v && npm -v

# --- Install Latest Python (3.12.x) from Source ---
# This is the recommended method for Debian-based images where the desired Python version is not in the default repos.
RUN apt-get update && \
    # Install build dependencies for Python
    apt-get install -y --no-install-recommends \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libsqlite3-dev \
        wget \
        libbz2-dev && \
    # Download Python source
    wget https://www.python.org/ftp/python/3.12.4/Python-3.12.4.tgz -O /tmp/Python-3.12.4.tgz && \
    tar -xzf /tmp/Python-3.12.4.tgz -C /usr/src && \
    cd /usr/src/Python-3.12.4 && \
    # Configure, compile, and install Python
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    # Use altinstall to avoid overwriting the default python3
    make altinstall && \
    # Clean up build dependencies and source files
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /usr/src/Python-3.12.4 /tmp/Python-3.12.4.tgz && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as the default python3 using update-alternatives.
# Using python3.12 from /usr/local/bin where 'make altinstall' places it.
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.12 1

# Verify Python version (should be 3.12.x) and pip3 version
RUN python3 --version && python3 -m pip --version

# --- Install Latest Java (OpenJDK 24.0.1) ---
# Define arguments for Java version and download URL.
ARG JAVA_VERSION=24.0.1
ARG JDK_FILENAME=openjdk-${JAVA_VERSION}_linux-x64_bin.tar.gz
# IMPORTANT: The JDK_URL must be verified for the latest specific build.
# This URL is for OpenJDK 24.0.1 from jdk.java.net (GPL license, no-fee terms).
ARG JDK_URL=https://download.java.net/java/GA/jdk${JAVA_VERSION}/8f9801659a8449579b18d2709794882c/36/GPL/${JDK_FILENAME}

# Download, extract, and clean up the OpenJDK tarball.
RUN curl -L -o /tmp/${JDK_FILENAME} ${JDK_URL} && \
    tar -xzf /tmp/${JDK_FILENAME} -C /usr/local/ && \
    rm /tmp/${JDK_FILENAME}

# Set JAVA_HOME and add Java bin directory to PATH.
ENV JAVA_HOME="/usr/local/jdk-${JAVA_VERSION}"
ENV PATH="$PATH:${JAVA_HOME}/bin"

# Verify Java version
RUN java -version

# --- Install Latest TypeScript (5.8.3) ---
# npm is already available from the Node.js installation.
# Install TypeScript globally.
RUN npm install -g typescript@5.8.3

# Verify TypeScript compiler version
RUN tsc --version

# --- Final Cleanup ---
# Clean up all unnecessary packages and files to keep the image size minimal.
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
