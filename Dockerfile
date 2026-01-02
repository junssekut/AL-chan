# Dockerfile for Android App Build Environment
FROM eclipse-temurin:17-jdk

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools
ENV ANDROID_CMDLINE_TOOLS_VERSION=9477386

# Create Android SDK directory
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools

# Download and install Android command line tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Accept Android SDK licenses
RUN yes | sdkmanager --licenses || true

# Install Android SDK components
RUN sdkmanager --update && \
    sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "extras;google;m2repository" \
    "extras;android;m2repository"

# Set working directory
WORKDIR /workspace

# Copy gradle wrapper files (for caching)
COPY gradle gradle
COPY gradlew .
COPY gradlew.bat .
COPY gradle.properties .

# Make gradlew executable
RUN chmod +x gradlew

# Pre-download gradle dependencies (optional, for faster builds)
COPY build.gradle .
COPY settings.gradle .
RUN ./gradlew --version || true

# Default command
CMD ["/bin/bash"]
