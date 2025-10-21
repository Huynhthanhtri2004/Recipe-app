pipeline {
	// Agent: Chạy job trên bất kỳ agent nào (máy ảo Ubuntu đã cài Flutter/Firebase CLI)
  agent any

  environment {
		// ⚠️ CẦN THAY THẾ: ID Project Firebase thực tế của bạn (ví dụ: recipeapp-90db2)
    FIREBASE_PROJECT_ID = "recipeapp-90db2"
    // ⚠️ CẦN THAY THẾ: Branch bạn muốn deploy
    GIT_BRANCH = "main"
    // Credential ID của GitHub PAT (đã lưu trong Jenkins)
    GITHUB_CREDENTIALS = "github-pat"
    // Credential ID của Secret File Firebase (ID: firebase-sa)
    FIREBASE_CREDENTIALS = "firebase-sa"
  }

  stages {
		stage('Checkout') {
			steps {
				// Lấy mã nguồn từ GitHub (sử dụng credentials nếu repo private)
        checkout([$class: 'GitSCM',
          branches: [[name: "*/${GIT_BRANCH}"]],
          userRemoteConfigs: [[
            url: 'https://github.com/huynhthanhhn2004/Recipe-app.git',
            credentialsId: GITHUB_CREDENTIALS
          ]]
        ])
      }
    }

    stage('Install Dependencies & Setup') {
			steps {
				// Lấy dependencies Flutter
        sh 'flutter pub get'
      }
    }

    stage('Build Flutter Web') {
			steps {
				// Thực hiện build Flutter Web cho Production. Kết quả nằm trong thư mục 'build/web'
        sh 'flutter build web --release'
      }
      post {
				// Lưu lại artifact (tệp build) vào Jenkins để xem lại sau
        success {
					archiveArtifacts artifacts: 'build/web/**', fingerprint: true
        }
      }
    }

    stage('Deploy to Firebase Hosting') {
			steps {
				// withCredentials lấy file Secret Account JSON (ID: firebase-sa)
        // và lưu đường dẫn file tạm thời vào biến môi trường FIREBASE_SA
        withCredentials([file(credentialsId: FIREBASE_CREDENTIALS, variable: 'FIREBASE_SA')]) {
					sh '''
            # 1. Export biến môi trường GOOGLE_APPLICATION_CREDENTIALS
            # (Firebase CLI yêu cầu biến này để xác thực bằng Service Account)
            export GOOGLE_APPLICATION_CREDENTIALS=${FIREBASE_SA}

            # 2. Chạy lệnh deploy. --only hosting chỉ deploy Hosting (Flutter Web)
            firebase deploy --only hosting --project ${FIREBASE_PROJECT_ID}
          '''
        }
      }
    }
  }

  post {
		always {
			// Dọn dẹp nếu cần
      echo 'Pipeline finished.'
    }
    success {
			echo '✅ Deploy to Firebase Hosting successful!'
    }
    failure {
			echo '❌ Pipeline failed during build or deploy stage. Check Console Output.'
    }
  }
}