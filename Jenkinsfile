pipeline {
    // Chạy job trên bất kỳ agent nào (máy ảo Ubuntu)
    agent any

    environment {
        // ⚠️ THAY THẾ GIÁ TRỊ THỰC TẾ CỦA BẠN TRONG KHỐI NÀY ⚠️

        // CẤU HÌNH FIREBASE CHO WEB
        FIREBASE_PROJECT_ID = "recipeapp-90db2"
        FIREBASE_CREDENTIALS = "firebase-sa"

        // CẤU HÌNH GIT
        GIT_BRANCH = "main"
        GITHUB_CREDENTIALS = "github-pat"
        REPO_URL = "https://github.com/Huynhthanhtri2004/Recipe-app.git"
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                // Lấy code từ GitHub
                checkout([$class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: REPO_URL,
                        credentialsId: GITHUB_CREDENTIALS
                    ]]
                ])

                // Cài dependency
                sh 'flutter pub get'
            }
        }

        // 1️⃣ BUILD FLUTTER WEB
        stage('Build Flutter Web') {
            steps {
                echo '🚀 Bắt đầu Build Flutter Web...'
                sh 'flutter build web --release --no-tree-shake-icons'
            }
            post {
                success { archiveArtifacts artifacts: 'build/web/**', fingerprint: true }
            }
        }

        // 2️⃣ TRIỂN KHAI LÊN FIREBASE HOSTING
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
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo '✅ Deploy Flutter Web thành công!'
        }
        failure {
            echo '❌ Pipeline thất bại. Kiểm tra Console Output.'
        }
    }
}
