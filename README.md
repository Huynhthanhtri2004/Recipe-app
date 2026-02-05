## Recipe App

Ứng dụng quản lý công thức nấu ăn được xây dựng bằng **Flutter**, sử dụng **Firebase** cho backend (Authentication, Firestore, Storage, Cloud Messaging).  
Người dùng có thể tìm kiếm, lưu yêu thích, tạo và quản lý công thức; admin có màn hình riêng để duyệt và quản lý nội dung.

---

### Tính năng chính

- **Đăng ký / Đăng nhập**
  - Email & password
  - Đăng nhập Google, Facebook, Apple (tuỳ nền tảng)

- **Quản lý công thức**
  - Xem danh sách công thức, phân trang
  - Xem chi tiết công thức, nguyên liệu, hướng dẫn nấu
  - Thêm công thức mới, chỉnh sửa, xóa (theo quyền)
  - Lưu công thức yêu thích

- **Lập kế hoạch bữa ăn**
  - Lên lịch món ăn theo ngày
  - Gợi ý món ăn theo danh mục

- **Thông báo & tương tác**
  - Nhận push notification (Firebase Cloud Messaging)
  - Chia sẻ công thức qua `share_plus`

- **Quản trị (Admin)**
  - Duyệt / từ chối công thức người dùng gửi lên
  - Quản lý người dùng, khóa tài khoản
  - Màn hình quản trị riêng cho admin

- **Khác**
  - Dark/Light theme với `ThemeProvider`
  - State management bằng `Provider`

---

### Công nghệ sử dụng

- **Frontend**: Flutter (Dart)
- **State management**: `provider`
- **Backend & dịch vụ**
  - `firebase_core`, `firebase_auth`
  - `cloud_firestore`
  - `firebase_storage`
  - `firebase_messaging`
- **Thư viện khác**
  - `image_picker`, `video_player`, `share_plus`
  - `table_calendar`, `intl`
  - `shared_preferences`, `url_launcher`, v.v.

---

### Cấu trúc thư mục chính

- `lib/`
  - `main.dart`: khởi tạo Firebase, Provider, định tuyến màn hình chính
  - `Provider/`: các lớp `ChangeNotifier` (auth, theme, favorite, notification,…)
  - `Views/`: các màn hình (login, register, app main, admin, recipe detail,…)
  - `Services/`: dịch vụ lưu trữ, xử lý file,…
  - `Utils/`: helper, constants, data mẫu, migration helper
  - `Widget/`: các widget dùng chung (banner, button, video player,…)
- `assets/images/`: hình ảnh sử dụng trong app
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`: cấu hình build đa nền tảng
- `firebase.json`, `firestore_rules_simple.rules`: cấu hình Firebase & security rules (tham khảo)

---

### Cài đặt & chạy dự án

1. **Yêu cầu**
   - Flutter SDK (phiên bản tương thích với `sdk` trong `pubspec.yaml`)
   - Đã cài đặt Android Studio / Xcode (tùy nền tảng)

2. **Clone & cài đặt dependencies**

   git clone <link-repo-cua-ban>
   cd Recipe_app
   flutter pub get
   