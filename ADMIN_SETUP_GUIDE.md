# Hướng dẫn thiết lập Admin cho Recipe App

## 🚀 Các bước thiết lập Admin

### 1. Tạo tài khoản Admin

#### Cách 1: Sử dụng Debug Screen (Khuyến nghị)
1. Đăng nhập vào ứng dụng với tài khoản thường
2. Vào **Profile** → **Debug Admin**
3. Chọn **"Cập nhật user hiện tại thành admin"** hoặc **"Tạo tài khoản admin mới"**
4. Nếu tạo mới, nhập thông tin:
   - Email: admin@example.com
   - Mật khẩu: 123456
   - Tên hiển thị: Admin

#### Cách 2: Thủ công trong Firebase Console
1. Vào Firebase Console → Authentication
2. Tạo user mới hoặc chọn user hiện có
3. Vào Firestore → Collection `users`
4. Tìm document của user và cập nhật field `role` thành `admin`

### 2. Kiểm tra đăng nhập Admin

1. Đăng xuất khỏi tài khoản hiện tại
2. Đăng nhập lại với tài khoản admin
3. Nếu thành công, bạn sẽ thấy màn hình Admin Console

### 3. Tạo dữ liệu mẫu (Tùy chọn)

1. Vào **Profile** → **Debug Admin**
2. Nhấn **"Tạo dữ liệu mẫu"**
3. Điều này sẽ tạo:
   - 10 danh mục mẫu
   - 3 công thức mẫu
   - 1 công thức chờ duyệt

## 🔧 Tính năng Admin

### Dashboard
- Thống kê tổng quan: số công thức, người dùng, công thức chờ duyệt

### Quản lý công thức
- **Chờ duyệt**: Xem và duyệt công thức mới
- **Tất cả**: Xem, chỉnh sửa, ẩn/hiện, xóa công thức

### Quản lý người dùng
- Xem danh sách tất cả người dùng
- Xem thông tin chi tiết: role, status, email
- Khóa/mở khóa tài khoản

### Quản lý danh mục
- Thêm, sửa, xóa danh mục
- Giao diện thân thiện với error handling

### Quản lý bình luận
- Xem và quản lý bình luận của người dùng

## 🐛 Troubleshooting

### Lỗi đăng nhập Admin
1. Kiểm tra role trong Firestore: `users/{uid}/role = "admin"`
2. Đảm bảo user đã đăng nhập Firebase Auth
3. Kiểm tra kết nối internet

### Lỗi hiển thị dữ liệu
1. Kiểm tra quyền Firestore
2. Đảm bảo collection tồn tại
3. Kiểm tra kết nối Firebase

### Lỗi tạo dữ liệu mẫu
1. Kiểm tra quyền ghi Firestore
2. Đảm bảo không trùng lặp dữ liệu
3. Kiểm tra kết nối internet

## 📱 Cấu trúc dữ liệu

### Collections chính:
- `users`: Thông tin người dùng
- `RecipeApp`: Công thức đã duyệt
- `recipes_pending`: Công thức chờ duyệt
- `App-Category`: Danh mục

### User document structure:
```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "displayName": "User Name",
  "role": "admin" | "user",
  "status": "active" | "locked",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 🔐 Bảo mật

- Chỉ user có role = "admin" mới truy cập được Admin Console
- Tất cả thao tác admin đều có error handling
- Dữ liệu được validate trước khi lưu

### Firestore Rules khuyến nghị cho Admin

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAdmin() {
      return request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId || isAdmin();

      match /favorites/{favoriteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId || isAdmin();
      }
      match /collections/{collectionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId || isAdmin();
      }
      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId || isAdmin();
      }
    }

    match /RecipeApp/{recipeId} {
      allow read: if true;
      allow write: if request.auth != null; // hoặc chỉ cho admin: isAdmin()

      match /likes/{likeId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == likeId || isAdmin();
      }
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
        allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid || isAdmin();
      }
    }

    match /recipes_pending/{recipeId} {
      allow read, write: if request.auth != null;
    }

    match /App-Category/{docId} {
      allow read: if true; // hoặc auth-only
      allow write: if isAdmin();
    }

    match /admin/{document=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

## 📞 Hỗ trợ

Nếu gặp vấn đề, hãy kiểm tra:
1. Console logs trong debug mode
2. Firebase Console để xem dữ liệu
3. Kết nối internet và Firebase
