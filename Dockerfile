# Use the latest Judge0 compilers image as the base.
# This image contains many compilers, which we will augment with specific versions.
FROM judge0/compilers:latest

# Set environment variables for non-interactive installations to prevent prompts during build.
ENV DEBIAN_FRONTEND=noninteractive

# --- General System Updates and Dependencies ---
# Update apt package lists and install necessary tools like curl, gnupg, and wget.
# These are essential for adding external repositories and downloading files.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    wget \
    apt-transport-https \
    # Clean up apt cache to reduce image size and keep it lean.
    && rm -rf /var/lib/apt/lists/*

# --- Install Latest Node.js (v24.x) ---
# Add NodeSource GPG key and repository for Node.js v24.x.
# This ensures we get the latest stable version directly from NodeSource.
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    NODE_MAJOR=24 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    # Update apt again to include the new Node.js repository definitions.
    apt-get update && \
    # Install Node.js and npm (Node Package Manager).
    apt-get install -y --no-install-recommends nodejs && \
    # Clean up apt cache again.
    rm -rf /var/lib/apt/lists/*

# Verify Node.js and npm versions to confirm successful installation.
RUN node -v && npm -v

# --- Install Latest Python (3.12.x) from Source ---
# This method compiles Python from source, ensuring the exact version is installed.
# It's robust for environments where the desired Python version isn't in default repos.
RUN apt-get update && \
    # Install build dependencies required to compile Python from source.
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
        libbz2-dev && \
    # Download Python source code.
    wget https://www.python.org/ftp/python/3.12.4/Python-3.12.4.tgz -O /tmp/Python-3.12.4.tgz && \
    # Extract the source archive.
    tar -xzf /tmp/Python-3.12.4.tgz -C /usr/src && \
    cd /usr/src/Python-3.12.4 && \
    # Configure, compile, and install Python. --enable-optimizations improves performance.
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    # Use 'altinstall' to avoid overwriting the default 'python3' symlink,
    # allowing us to manage it with update-alternatives.
    make altinstall && \
    # Clean up build dependencies and source files to minimize image size.
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /usr/src/Python-3.12.4 /tmp/Python-3.12.4.tgz && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as the default 'python3' using update-alternatives.
# This ensures 'python3' command points to the newly installed 3.12.
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.12 1

# Verify Python version (should be 3.12.x) and pip3 version.
RUN python3 --version && python3 -m pip --version

# --- Install Latest Java (OpenJDK 21 - using Adoptium Temurin) ---
# Adoptium provides reliable, pre-built OpenJDK binaries.
# We're installing OpenJDK 21, an LTS release, for stability.
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/keyrings/adoptium.gpg > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    # Install Temurin OpenJDK 21 development kit.
    apt-get install -y --no-install-recommends temurin-21-jdk && \
    # Clean up apt cache.
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME and add Java bin directory to PATH for easy execution.
# The exact path might vary slightly, so verify it if you encounter issues.
# A common path is /usr/lib/jvm/temurin-21-jdk-amd64.
ENV JAVA_HOME="/usr/lib/jvm/temurin-21-jdk-amd64"
ENV PATH="$PATH:${JAVA_HOME}/bin"

# Verify Java version to confirm successful installation of OpenJDK 21.
RUN java -version

# --- Install Latest TypeScript (5.8.3) ---
# npm is already available from the Node.js installation.
# Install TypeScript globally for command-line access to 'tsc'.
RUN npm install -g typescript@5.8.3

# Verify TypeScript compiler version.
RUN tsc --version

# --- Final Cleanup ---
# Perform a final cleanup of unnecessary packages and files.
# This helps keep the Docker image as small and efficient as possible.
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
