pipeline {
    agent any
    // Note: If Docker Pipeline plugin is available, you can use:
    // agent {
    //     dockerfile {
    //         filename 'Dockerfile'
    //         reuseNode true
    //     }
    // }
    
    parameters {
        choice(
            name: 'BRANCH',
            choices: ['master', 'develop'],
            description: 'Select the branch to build'
        )
        choice(
            name: 'BUILD_TYPE',
            choices: ['debug', 'release'],
            description: 'Select the build type (debug or release)'
        )
        choice(
            name: 'BUILD_VARIANT',
            choices: ['assembleDebug', 'assembleRelease', 'bundleDebug', 'bundleRelease'],
            description: 'Select the build variant'
        )
        booleanParam(
            name: 'CLEAN_BUILD',
            defaultValue: true,
            description: 'Perform a clean build'
        )
    }
    
    environment {
        APK_OUTPUT_DIR = "app/build/outputs/apk"
        AAB_OUTPUT_DIR = "app/build/outputs/bundle"
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    echo "Building AL-chan Android App"
                    echo "Branch: ${params.BRANCH}"
                    echo "Build Type: ${params.BUILD_TYPE}"
                    echo "Build Variant: ${params.BUILD_VARIANT}"
                    echo "Clean Build: ${params.CLEAN_BUILD}"
                }
            }
        }
        
        stage('Checkout') {
            steps {
                script {
                    // Checkout the selected branch
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${params.BRANCH}"]],
                        userRemoteConfigs: scm.userRemoteConfigs
                    ])
                }
            }
        }
        
        stage('Setup Build Environment') {
            steps {
                script {
                    echo "Setting up build environment..."
                    // Create local.properties file if it doesn't exist
                    sh """
                        if [ ! -f local.properties ]; then
                            echo "sdk.dir=/opt/android-sdk" > local.properties
                            echo "SENTRY_DSN=" >> local.properties
                            echo "SENTRY_AUTH_TOKEN=" >> local.properties
                        fi
                    """
                    
                    // Create keystore directory if it doesn't exist
                    sh """
                        mkdir -p keystore
                        if [ ! -f keystore/debug.keystore ]; then
                            echo "Using default debug keystore from Android SDK"
                        fi
                    """
                }
            }
        }
        
        stage('Build APK/AAB') {
            steps {
                script {
                    def cleanCmd = params.CLEAN_BUILD ? 'clean' : ''
                    def buildCmd = params.BUILD_VARIANT
                    
                    echo "Building with command: ${cleanCmd} ${buildCmd}"
                    
                    sh """
                        ./gradlew ${cleanCmd} ${buildCmd} --no-daemon --stacktrace
                    """
                }
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                script {
                    echo "Archiving build artifacts..."
                    
                    // Archive APK files
                    if (params.BUILD_VARIANT.contains('assemble')) {
                        archiveArtifacts artifacts: "${APK_OUTPUT_DIR}/**/*.apk", 
                                       allowEmptyArchive: true,
                                       fingerprint: true
                    }
                    
                    // Archive AAB files (Android App Bundle)
                    if (params.BUILD_VARIANT.contains('bundle')) {
                        archiveArtifacts artifacts: "${AAB_OUTPUT_DIR}/**/*.aab", 
                                       allowEmptyArchive: true,
                                       fingerprint: true
                    }
                }
            }
        }
        
        stage('Test Reports') {
            steps {
                script {
                    echo "Collecting test reports..."
                    // Publish test results if they exist
                    if (fileExists('app/build/test-results')) {
                        junit '**/build/test-results/**/*.xml'
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                def buildInfo = """
                ========================================
                Build Successful!
                ========================================
                Branch: ${params.BRANCH}
                Build Type: ${params.BUILD_TYPE}
                Build Variant: ${params.BUILD_VARIANT}
                Build Number: ${env.BUILD_NUMBER}
                ========================================
                """
                echo buildInfo
                
                // List generated APK/AAB files
                sh """
                    echo "Generated APK files:"
                    find ${APK_OUTPUT_DIR} -name "*.apk" -type f 2>/dev/null || echo "No APK files found"
                    echo ""
                    echo "Generated AAB files:"
                    find ${AAB_OUTPUT_DIR} -name "*.aab" -type f 2>/dev/null || echo "No AAB files found"
                """
            }
        }
        failure {
            script {
                echo """
                ========================================
                Build Failed!
                ========================================
                Branch: ${params.BRANCH}
                Build Type: ${params.BUILD_TYPE}
                Build Variant: ${params.BUILD_VARIANT}
                Build Number: ${env.BUILD_NUMBER}
                ========================================
                Please check the console output for errors.
                """
            }
        }
        always {
            script {
                echo "Build completed. Workspace will be cleaned by Jenkins if configured."
                // Note: Docker image cleanup is handled automatically by Jenkins Docker plugin
            }
        }
    }
}
