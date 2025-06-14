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

# --- Install Latest Python (3.12.x) ---
# Install Python 3.12 and its development headers/libraries.
# This assumes the base image is Debian/Ubuntu-based and Python 3.12 is available via apt.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as the default python3 using update-alternatives.
# This helps ensure Judge0 uses this version if it calls 'python3'.
# Priority 1 is a low priority; adjust if other python3 versions might exist.
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Verify Python version (should be 3.12.x) and pip3 version
RUN python3 --version && pip3 --version

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
