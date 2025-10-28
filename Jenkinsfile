pipeline {
  // Chạy job trên bất kỳ agent nào (máy ảo Ubuntu)
    agent any

    environment {
    // ⚠️ THAY THẾ GIÁ TRỊ THỰC TẾ CỦA BẠN TRONG KHỐI NÀY ⚠️

        // CẤU HÌNH FIREBASE VÀ DISTRIBUTION
        FIREBASE_PROJECT_ID = "recipeapp-90db2"
        FIREBASE_CREDENTIALS = "firebase-sa"
        FIREBASE_ANDROID_APP_ID = "1:632817783218:android:f080d080710ed9d16354ab" // ⬅️ ID Ứng dụng Android từ Console
        TESTER_GROUPS = "internal-testers"

        // CẤU HÌNH SIGNING (Bắt buộc cho APK)
        ANDROID_KEYSTORE_CRED = "android-keystore" // ID Secret File
        ANDROID_PASS_CRED = "android-signing-creds" // ID Username/Password
        KEY_STORE_FILE = "recipe_app.jks"
        KEY_ALIAS = "recipe_key_alias"
        APK_FILENAME = "recipe-app-release.apk"

        // CẤU HÌNH GIT
        GIT_BRANCH = "main"
        GITHUB_CREDENTIALS = "github-pat"
        REPO_URL = "https://github.com/Huynhthanhtri2004/Recipe-app.git"
    }

    stages {
    stage('Checkout & Setup') {
      steps {
        // Checkout code (sử dụng URL chính xác đã sửa)
                checkout([$class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: REPO_URL,
                        credentialsId: GITHUB_CREDENTIALS
                    ]]
                ])
                // Lấy dependencies
                sh 'flutter pub get'
            }
        }

        // 1. TRIỂN KHAI WEB
        stage('Build Flutter Web') {
      steps {
        echo 'Bắt đầu Build Flutter Web...'
                // Khắc phục lỗi: Thêm cờ --no-tree-shake-icons
                sh 'flutter build web --release --no-tree-shake-icons'
            }
            post {
        success { archiveArtifacts artifacts: 'build/web/**', fingerprint: true }
            }
        }

        stage('Deploy to Firebase Hosting') {
      steps {
        withCredentials([file(credentialsId: FIREBASE_CREDENTIALS, variable: 'FIREBASE_SA')]) {
          sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS=${FIREBASE_SA}
                        firebase deploy --only hosting --project ${FIREBASE_PROJECT_ID}
                    '''
                }
            }
        }

        // 2. TRIỂN KHAI APK (MOBILE)
        stage('Build & Sign Android APK') {
            environment {
                // GHI ĐÈ biến môi trường bị lỗi bằng đường dẫn chính xác của bạn
        ANDROID_HOME = '/home/huynhthanhtri/Android/Sdk'
    }
      steps {
        // Lấy File Keystore và Mật khẩu/Alias
                withCredentials([
                    file(credentialsId: ANDROID_KEYSTORE_CRED, variable: 'KEYSTORE_PATH'),
                    usernamePassword(credentialsId: ANDROID_PASS_CRED, usernameVariable: 'KEY_USER', passwordVariable: 'KEY_PASS')
                ]) {
          sh '''
                        echo "--- BẮT ĐẦU KÝ ỨNG DỤNG ANDROID ---"
                        # 1. Tạo file key.properties cho Gradle để ký
                        echo "storeFile=${KEYSTORE_PATH}" > android/key.properties
                        echo "keyAlias=${KEY_ALIAS}" >> android/key.properties
                        echo "keyPassword=${KEY_PASS}" >> android/key.properties
                        echo "storePassword=${KEY_PASS}" >> android/key.properties

                        # 2. Build APK đã ký
                        flutter build apk --release

                        # 3. Chuẩn bị Artifact
                        cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/${APK_FILENAME}
                    '''
                }
            }
            post {
        success { archiveArtifacts artifacts: "build/app/outputs/flutter-apk/${APK_FILENAME}" }
            }
        }

        stage('Distribute APK via Firebase') {
      steps {
        // Lấy file Service Account để xác thực Firebase
                withCredentials([file(credentialsId: FIREBASE_CREDENTIALS, variable: 'FIREBASE_SA')]) {
          sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS=${FIREBASE_SA}

                        # Phân phối file APK lên App Distribution
                        firebase appdistribution:distribute build/app/outputs/flutter-apk/${APK_FILENAME} \\
                            --app ${FIREBASE_ANDROID_APP_ID} \\
                            --groups ${TESTER_GROUPS} \\
                            --release-notes "CI/CD Build #${BUILD_NUMBER} - KẾT HỢP WEB/APK" \\
                            --project ${FIREBASE_PROJECT_ID}
                    '''
                }
            }
        }
    }

    post {
    always {
      echo 'Pipeline finished.'
        }
        success {
      echo '✅ Deploy KẾT HỢP (Web & APK) thành công!'
        }
        failure {
      echo '❌ Pipeline thất bại. Kiểm tra Console Output.'
        }
    }
}