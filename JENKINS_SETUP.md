# Jenkins CI/CD Setup for AL-chan

This document describes how to set up Jenkins for automated builds of the AL-chan Android application.

## Prerequisites

1. **Jenkins Server** with the following installed:
   - Jenkins 2.x or later
   - Java Development Kit (JDK) 17 or later
   - Android SDK (if building natively on Jenkins agent)

2. **Required Jenkins Plugins**:
   - Git Plugin
   - Pipeline Plugin
   - Credentials Binding Plugin

3. **Optional - For Docker-based builds**:
   - Docker installed and running on the Jenkins host
   - Docker Pipeline Plugin (or Docker Plugin)
   - Then uncomment the Docker agent configuration in the Jenkinsfile

**Note:** The Jenkinsfile currently uses `agent any` which runs on any available Jenkins agent. If you have the Docker Pipeline plugin installed, you can uncomment the `agent { dockerfile }` section in the Jenkinsfile to build inside a Docker container with all dependencies pre-configured.

## Setup Instructions

### 1. Configure Jenkins Job

There are two Jenkinsfile options available:

**Option A: Standard Jenkinsfile** (Recommended for most users)
- Uses predefined branch list
- Simple setup, no additional plugins required
- File: `Jenkinsfile`

**Option B: Advanced Jenkinsfile** (For advanced users)
- Dynamic branch selection from Git repository
- Requires "Active Choices" plugin
- File: `Jenkinsfile.advanced`

#### Setup Steps:

1. Create a new **Pipeline** job in Jenkins
2. In the job configuration:
   - **General**: Check "This project is parameterized" (parameters are defined in Jenkinsfile)
   - **Build Triggers**: Configure as needed (e.g., Poll SCM, webhooks)
   - **Pipeline**:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: Your repository URL
     - Credentials: Add your Git credentials
     - Branch Specifier: `*/master` (or your default branch)
     - Script Path: `Jenkinsfile` (or `Jenkinsfile.advanced` for dynamic branches)

### 2. Build Parameters

When you run the job, you'll be prompted with the following interactive parameters:

- **BRANCH**: Select the branch to build
  - `master` - Main production branch
  - `develop` - Development branch
  - Other branches as defined in the Jenkinsfile
  
- **BUILD_TYPE**: Select the build type
  - `debug` - Debug build with debugging symbols
  - `release` - Release build with optimizations
  
- **BUILD_VARIANT**: Select the build variant
  - `assembleDebug` - Build debug APK
  - `assembleRelease` - Build release APK
  - `bundleDebug` - Build debug Android App Bundle (AAB)
  - `bundleRelease` - Build release Android App Bundle (AAB)
  
- **CLEAN_BUILD**: Perform a clean build
  - Checked (default): Runs `./gradlew clean` before building
  - Unchecked: Incremental build

### 3. Android Keystore Configuration

For **debug builds**, the project uses the default Android debug keystore configured in `gradle.properties`.

For **release builds**, you need to:

1. Generate or obtain your release keystore
2. Place it in the `keystore/` directory (or update the path in `gradle.properties`)
3. Update the signing configuration in `app/build.gradle` if needed
4. **Security Note**: Never commit your release keystore to version control

### 4. Local Properties Setup

The Jenkins pipeline automatically creates a basic `local.properties` file. For advanced configurations:

1. Add Jenkins credentials for sensitive data:
   ```groovy
   // In Jenkins pipeline, use credentials binding
   withCredentials([string(credentialsId: 'sentry-dsn', variable: 'SENTRY_DSN')]) {
       sh "echo 'SENTRY_DSN=${SENTRY_DSN}' >> local.properties"
   }
   ```

2. Configure Sentry (optional):
   - Add `SENTRY_DSN` in Jenkins credentials
   - Add `SENTRY_AUTH_TOKEN` in Jenkins credentials

### 5. Running a Build

1. Click "Build with Parameters" on the Jenkins job
2. Select your desired options:
   - Choose the branch to build
   - Select build type (debug/release)
   - Select build variant (APK or AAB)
   - Choose whether to perform a clean build
3. Click "Build"

### 6. Build Artifacts

After a successful build:

- APK files will be available in: `app/build/outputs/apk/{buildType}/`
- AAB files will be available in: `app/build/outputs/bundle/{buildType}/`
- Artifacts are automatically archived by Jenkins and can be downloaded from the build page

## Pipeline Stages

The Jenkinsfile defines the following stages:

1. **Preparation**: Display build parameters
2. **Checkout**: Checkout the selected branch from Git
3. **Setup Build Environment**: Create necessary configuration files (local.properties, keystore directory)
4. **Build APK/AAB**: Execute the Gradle build command
5. **Archive Artifacts**: Archive the generated APK/AAB files
6. **Test Reports**: Collect and publish test results (if available)

**Note:** The pipeline currently runs on any available Jenkins agent (`agent any`). If you have the Docker Pipeline plugin installed, you can uncomment the Docker agent configuration in the Jenkinsfile to run the pipeline inside a Docker container.

## Docker Build Environment (Optional)

If you enable the Docker agent in the Jenkinsfile, the `Dockerfile` sets up a complete Android build environment with:

- OpenJDK 17
- Android SDK Command Line Tools
- Android Platform Tools
- Android SDK Platform 34
- Build Tools 34.0.0
- Gradle (via Gradle Wrapper)

To enable Docker builds:
1. Install the Docker Pipeline plugin in Jenkins
2. Ensure Docker is available on the Jenkins host
3. Uncomment the `agent { dockerfile }` section in the Jenkinsfile
4. Comment out the `agent any` line

## Customization

### Adding More Branches

**Method 1: Manual Update (Standard Jenkinsfile)**

Edit the `Jenkinsfile` and add branches to the `BRANCH` parameter:

```groovy
choice(
    name: 'BRANCH',
    choices: ['master', 'develop', 'feature/my-feature'],
    description: 'Select the branch to build'
)
```

**Method 2: Use the Helper Script**

Run the included script to list available branches:

```bash
./scripts/list-branches.sh
```

**Method 3: Dynamic Branches (Advanced)**

Use `Jenkinsfile.advanced` which automatically fetches all branches from the Git repository. Requires the "Active Choices" Jenkins plugin.

### Changing Build Variants

Add or modify build variants in the `BUILD_VARIANT` parameter:

```groovy
choice(
    name: 'BUILD_VARIANT',
    choices: ['assembleDebug', 'assembleRelease', 'testDebug'],
    description: 'Select the build variant'
)
```

### Environment Variables

Add environment variables in the `environment` block of the Jenkinsfile:

```groovy
environment {
    CUSTOM_VAR = "value"
}
```

## Troubleshooting

### Invalid Agent Type Error

If you see an error like "Invalid agent type 'dockerfile' specified. Must be one of [any, label, none]":
- This means the Docker Pipeline plugin is not installed in Jenkins
- The Jenkinsfile has been updated to use `agent any` by default
- If you want to use Docker builds, install the Docker Pipeline plugin and uncomment the Docker agent configuration in the Jenkinsfile

### Docker Permission Issues (Optional - if using Docker agent)

If you enable the Docker agent in the Jenkinsfile, you'll need:
- Docker to be installed on the Jenkins host
- Jenkins to have access to the Docker daemon (usually via `/var/run/docker.sock`)
- Docker Pipeline plugin properly configured in Jenkins

If you see Docker-related errors, ensure:
1. Docker is installed and running on the Jenkins host
2. Jenkins can communicate with Docker daemon
3. The Docker Pipeline plugin is installed in Jenkins

### Android SDK Not Found

If you see "ANDROID_HOME not set" or similar errors:
- Install Android SDK on the Jenkins agent
- Set the `ANDROID_HOME` environment variable
- Or use the Docker agent which includes a pre-configured Android SDK

### SDK License Issues

If you see SDK license errors, ensure the Dockerfile accepts licenses:
```dockerfile
RUN yes | sdkmanager --licenses || true
```

### Build Memory Issues

If builds fail due to memory issues, increase Docker memory limits or adjust Gradle JVM args in `gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048m
```

### Missing Dependencies

If builds fail due to missing Android SDK components, add them to the Dockerfile:
```dockerfile
RUN sdkmanager "platforms;android-XX" "build-tools;XX.X.X"
```

## Security Best Practices

1. **Never commit sensitive data** (keystores, API keys) to version control
2. Use **Jenkins Credentials** for sensitive configuration
3. Restrict access to Jenkins jobs with appropriate permissions
4. Regularly update Docker base images for security patches
5. Use **signed commits** for production releases

## Maintenance

### Updating Android SDK

To update the Android SDK components in the Docker image, edit the `Dockerfile`:

```dockerfile
RUN sdkmanager \
    "platforms;android-35" \
    "build-tools;35.0.0"
```

### Cleaning Up Old Builds

Jenkins Docker plugin automatically manages Docker images created during builds. You can configure Jenkins to clean up old builds and their associated Docker images through:
- Job configuration: "Discard Old Builds" setting
- Jenkins global configuration: Docker settings for image cleanup

Manual cleanup of Docker images can be done on the Jenkins host if needed.

## Support

For issues related to:
- **AL-chan app**: Check the main [README.md](README.md)
- **Jenkins setup**: Refer to [Jenkins Documentation](https://www.jenkins.io/doc/)
- **Docker**: Refer to [Docker Documentation](https://docs.docker.com/)
- **Android builds**: Refer to [Android Developer Documentation](https://developer.android.com/studio/build)

## License

This Jenkins configuration is part of the AL-chan project. See [LICENSE](LICENSE) for details.
