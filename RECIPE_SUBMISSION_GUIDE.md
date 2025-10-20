# Hướng dẫn gửi công thức mới

## Vấn đề đã được khắc phục

Trước đây, khi user gửi công thức và admin duyệt, màn hình chi tiết không hiển thị được vì thiếu một số trường dữ liệu quan trọng.

## Các thay đổi đã thực hiện

### 1. Cập nhật form gửi công thức (`submit_recipe_screen.dart`)

**Thêm trường mới:**
- **Số lượng nguyên liệu**: Trường để nhập số lượng cho từng nguyên liệu (theo thứ tự)

**Cách sử dụng:**
```
Ví dụ:
Nguyên liệu:
- Thịt bò
- Hành tây  
- Cà chua
- Gia vị

Số lượng nguyên liệu:
- 500
- 100
- 200
- 50
```

### 2. Cập nhật admin duyệt (`admin_screens.dart`)

- Đảm bảo khi admin duyệt công thức, tất cả các trường cần thiết được copy đúng cách
- Tự động thêm các trường mặc định nếu thiếu

### 3. Cập nhật màn hình chi tiết (`recipe_detail_screen.dart`)

- Xử lý trường hợp không có `ingredientsAmount` hoặc `ingredientsImage`
- Hiển thị placeholder cho ảnh nguyên liệu nếu không có
- Tự động tạo số lượng mặc định (100g) nếu không có dữ liệu

### 4. Migration tự động (`migration_helper.dart`)

- Tự động cập nhật các công thức hiện có trong database
- Chạy khi khởi động app lần đầu
- Thêm các trường còn thiếu cho công thức cũ

## Cách sử dụng form mới

### Bước 1: Điền thông tin cơ bản
- Tên món ăn
- Hình ảnh (upload từ camera/gallery hoặc nhập URL)
- Video hướng dẫn (tùy chọn)
- Thời gian nấu (phút)
- Lượng calo
- Quốc gia/Ẩm thực
- Độ khó (easy/medium/hard)
- Loại bữa ăn (sáng/trưa/tối)

### Bước 2: Nhập nguyên liệu
**Nguyên liệu (mỗi dòng 1 nguyên liệu):**
```
Thịt bò
Hành tây
Cà chua
Tỏi
Gia vị
```

**Số lượng nguyên liệu (mỗi dòng 1 số lượng, theo thứ tự nguyên liệu trên):**
```
500
100
200
20
50
```

### Bước 3: Nhập hướng dẫn
**Hướng dẫn (mỗi dòng 1 bước):**
```
Bước 1: Rửa sạch thịt bò và cắt miếng vừa ăn
Bước 2: Ướp thịt với gia vị trong 15 phút
Bước 3: Xào thịt với hành tây và cà chua
Bước 4: Nêm nếm vừa ăn và tắt bếp
```

## Lưu ý quan trọng

1. **Thứ tự nguyên liệu**: Số lượng nguyên liệu phải theo đúng thứ tự với danh sách nguyên liệu
2. **Đơn vị**: Số lượng được tính bằng gam (g)
3. **Validation**: Tất cả trường đều bắt buộc, không được để trống
4. **Migration**: Các công thức cũ sẽ được tự động cập nhật khi khởi động app

## Kết quả

Sau khi admin duyệt công thức:
- ✅ Màn hình chi tiết hiển thị đầy đủ thông tin
- ✅ Có thể điều chỉnh số lượng khẩu phần
- ✅ Hiển thị nguyên liệu với số lượng chính xác
- ✅ Tương thích với các tính năng khác (favorite, review, etc.)

## Troubleshooting

Nếu vẫn gặp vấn đề:
1. Kiểm tra console log để xem có lỗi migration không
2. Đảm bảo Firebase connection hoạt động bình thường
3. Thử gửi công thức mới với form đã cập nhật
4. Liên hệ admin để kiểm tra dữ liệu trong database

