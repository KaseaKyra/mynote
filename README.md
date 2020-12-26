# mynote

Xây dựng ứng dụng Note.

Đây là bài thu hoach của học phần **Phát triển ứng dụng di động đa nền tảng** đang được giảng dạy tại **Khoa Công nghệ thông tin của Trường Đại học Mỏ - Địa chất**

## Tổng quan

Ứng dụng được xây dựng trên việc kế thừa template tại link: https://github.com/chuyentt/mynote

Cấu trúc thư mục:

```
lib
--- main.dart
--- repository
--- --- local_repository.dart
--- --- repository.dart
--- ui
--- --- views
--- --- --- note
--- --- --- --- note_model.dart
--- --- --- --- note_repository.dart
--- --- --- --- note_view.dart
--- --- --- --- note_viewmodel.dart
--- --- --- --- widgets
--- --- --- -- --- note_view_item.dart
```

Một số phần được cập nhật:

1. Xóa bỏ widget **note_view_item_edit.dart**: trong ``ui -> views -> note -> widgets``. Mục đích của việc này nhằm gộp hai hành động thêm mới và cập nhật thành dùng chung một view duy nhất là **note_view_item.dart**.

2. Chỉnh sửa lại tính năng thêm mới một ghi chú với tiêu đề và nội dung do người dùng nhập vào, thay cho việc trước đó thêm mặc định với giá trị là thời gian hiện tại.

3. Thêm tính năng cập nhật một ghi chú.

4. Thêm tính năng xóa một ghi chú. Với tính năng xóa ghi chú xây dựng gồm 2 tính năng nhỏ, gồm: xóa tạm thời và xóa vĩnh viễn.

## Mã nguồn

###### 1. main.dart

File main sẽ import trực tiếp một view duy nhất là NoteView.

```dart
import 'package:flutter/material.dart';
import 'package:mynote/ui/views/note/note_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NoteView(),
    );
  }
}
```

###### 2. Repository

###### 3. Bên trong note folder