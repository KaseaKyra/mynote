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

##### 1. main.dart

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

##### 2. Directory Repository

###### local_repository.dart

Tạo database ở local máy, sử dụng package sqflite.

```dart
import 'package:mynote/ui/views/note/note_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalRepository {
  /// Xây dựng một hàm tạo private
  LocalRepository._internal();

  /// Lưu cache để không phải tạo nhiều đối tượng
  static final _cache = <String, LocalRepository>{};

  /// Tạo một getter để lấy ra chính nó
  static LocalRepository get instance =>
      _cache.putIfAbsent('LocalPersistence', () => LocalRepository._internal());

  bool isInitialized = false;
  Database _db;

  Future<Database> db() async {
    if (!isInitialized) await _init();
    return _db;
  }

  Future _init() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'note_app2612.db');

    _db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      /// Trong trường hợp database chưa có
      /// TODO: Trường hợp thay đổi lược đồ cần phải nghiên cứu kỹ
      await db.execute(Note.createTable);

      /// TODO: Thêm các bảng khác ở đây như đối với Note
    });
    isInitialized = true;
  }
}
```

###### repository.dart

Lớp trừu tượng để cho các model thừa kế và dùng trong việc thêm / sửa / xóa và lấy dữ liệu (Create, Read, Update, Delete - CRUD). 

Lớp này bao gồm các phương thức: insert, update, delete, items và softDelete (phương thức mới thêm dùng cho việc xóa tạm thời các ghi chú)

```dart
import 'local_repository.dart';

/// Lớp trừu tượng để cho các model thừa kế và dùng trong việc
/// thêm / sửa / xóa và lấy dữ liệu (Create, Read, Update, Delete - CRUD)
abstract class Repository<T> {
  LocalRepository localRepo;

  Future<dynamic> insert(T item);

  Future<dynamic> update(T item);

  Future<dynamic> softDelete(T item);

  Future<dynamic> delete(T item);

  Future<List<T>> items();
}
```

##### 3. Bên trong note folder

###### note_repository.dart

Class này kế thừa class abstract Repository và định nghĩa phần body các phương thức có sẵn.

```dart
import 'package:mynote/repostory/local_repository.dart';
import 'package:mynote/repostory/repository.dart';

import 'note_model.dart';

class NoteRepository implements Repository<Note> {
  NoteRepository._internal(LocalRepository localRepo) {
    this.localRepo = localRepo;
  }

  static final _cache = <String, NoteRepository>{};

  factory NoteRepository() {
    return _cache.putIfAbsent('NoteRepository',
        () => NoteRepository._internal(LocalRepository.instance));
  }

  @override
  LocalRepository localRepo;

  @override
  Future<dynamic> insert(Note item) async {
    final db = await localRepo.db();
    return await db.insert(Note.tableName, item.toMap());
  }

  @override
  Future<dynamic> update(Note item) async {
    final db = await localRepo.db();

    return await db.update(Note.tableName, item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  @override
  Future<dynamic> delete(Note item) async {
    return await localRepo.db().then((db) =>
        db.delete(Note.tableName, where: 'id' + ' = ?', whereArgs: [item.id]));
  }

  @override
  Future<List<Note>> items() async {
    final db = await localRepo.db();
    var maps = await db.query(Note.tableName);

    return Note.fromList(maps);
  }

  /*
  * Dùng để thực hiện chức năng xóa tạm thời của item
  * Cập nhật trạng thái của note là isDeleted
  * */
  @override
  Future softDelete(Note item) async {
    final db = await localRepo.db();

    return await db.update(Note.tableName, item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }
}
```

###### note_model.dart

Xây dựng class Note gồm các thuộc tính: title, desc và hai phương thức toMap, fromMap.

```dart
import 'package:flutter/material.dart';

class Note {
  /// id tự sinh ra ngẫu nhiên
  String id =
      UniqueKey().hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');

  final String title;
  final String desc;
  bool isDeleted = false;

  Note(this.title, this.desc);

  /// Tên của bảng CSDL, nó nên được gán sẵn và có thể lấy ra từ data
  /// model mà không cần khởi tạo nên nó là static để dễ sử dung.
  static String get tableName => 'Notes';

  /// Chuỗi lệnh SQL để tạo bảng CSDL, nó nên được thiết lập để tạo bảng
  /// trong CSDL mà không cần khởi tạo nên nó là static để dễ sử dụng.
  static String get createTable =>
      'CREATE TABLE $tableName(`id` TEXT PRIMARY KEY,'
      ' `title` TEXT,'
      ' `desc` TEXT,'
      ' `isDeleted` INTEGER DEFAULT 0)';

  /// Phương thức này được thiết lập để tạo nên danh sách các ghi chú
  /// được lấy về từ CSDL, nó được tạo dưới dạng danh sách các ghi chú
  /// theo cấu trúc Map mà không cần khởi tạo đối tượng nên nó là static.
  static List<Note> fromList(List<Map<String, dynamic>> query) {
    List<Note> items = List<Note>();
    for (Map map in query) {
      items.add(Note.fromMap(map));
    }

    return items;
  }

  /// Hàm tạo có tên, đây là một hàm tạo từ đối số là dữ liệu đưa vào
  /// dưới dạng Map
  Note.fromMap(Map data)
      : id = data['id'],
        title = data['title'],
        desc = data['desc'],
        isDeleted = data['isDeleted'] == 1 ? true : false;

  /// Phương thức của đối tượng, nó cho phép tạo ra dữ liệu dạng Map từ
  /// dữ liệu của một đối tượng ghi chú.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'desc': desc,
        'isDeleted': isDeleted ? 1 : 0,
      };
}
```

###### note_view.dart

Đây là view chính của app note dùng để hiển thị danh sách các ghi chú.

```dart
import 'package:flutter/material.dart';
import 'package:mynote/ui/views/note/widgets/note_view_item.dart';
import 'package:stacked/stacked.dart';

import 'note_viewmodel.dart';
import 'note_model.dart';

class NoteView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NoteViewModel>.reactive(
      onModelReady: (model) => model.init(),
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(title: Text(model.title)),
        body: Stack(
          children: [
            model.state == NoteViewState.listView
                ? ListView.builder(
                    itemCount: model.items.length,
                    itemBuilder: (BuildContext context, int index) {
                      Note item = model.items[index];
                      return Dismissible(
                        key: Key(item.id),
                        onDismissed: (direction) {
                          /*
                          * Vuốt để xóa note.
                          * Các bước để xóa 1 note.
                          *     1. Xóa item trên giao diện
                          *     2. Xóa trong db
                          * */
                          model.items.removeAt(index);
                          model.editingItem = item;
                          model.delete();
                        },
                        // set background color khi vuốt
                        // TODO: sau khi thiết kế tính năng setting theme sẽ làm global
                        background: Container(color: Colors.lightBlueAccent),
                        child: ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.desc),
                          onTap: () {
                            model.editingItem = item;
                            model.viewItem();
                          },
                        ),
                      );
                    },
                  )
                : model.state == NoteViewState.itemView
                    ? NoteViewItem()
                    : SizedBox(),
          ],
        ),
        floatingActionButton: model.state == NoteViewState.listView
            ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  // tạo mới một note
                  model.viewItem();
                },
              )
            : null,
      ),
      viewModelBuilder: () => NoteViewModel(),
    );
  }
}
```

###### note_viewmodel.dart

NoteViewModel là class đứng giữa View và Model.

```dart
import 'package:flutter/material.dart';
import 'package:mynote/ui/views/note/note_repository.dart';
import 'package:stacked/stacked.dart';

import 'note_model.dart';

/// Trạng thái của view
enum NoteViewState { listView, itemView }

class NoteViewModel extends BaseViewModel {
  final title = 'Note App';

  /// Danh sách các bản ghi được load bất đồng bộ bên trong view model,
  /// khi load thành công thì thông báo đến view để cập nhật trạng thái
  var _items = <Note>[];

  /// Danh sách các bản ghi dùng để hiển thị trên ListView
  /// Vì quá trình load items là bất đồng bộ nên phải tạo một getter
  /// `get items => _items` để tránh xung đột
  List<Note> get items => _items;

  /// Trạng thái mặc định của view là listView, nó có thể thay đổi
  /// bên trong view model
  var _state = NoteViewState.listView;

  /// Khi thay đổi trạng thái thì sẽ báo cho view biết để cập nhật
  /// nên cần tạo một setter để vừa nhận giá trị vừa thông báo đến view
  set state(value) {
    // Cập nhật giá trị cho biến _state
    _state = value;

    // Thông báo cho view biết để cập nhật trạng thái của widget
    notifyListeners();
  }

  /// Cần có một getter để lấy ra trạng thái view cục bộ cho view
  NoteViewState get state => _state;

  Note editingItem;

  var editingControllerTitle = TextEditingController();
  var editingControllerDesc = TextEditingController();

  var repo = NoteRepository();

  Future init() async {
    return reloadItems();
  }

  Future reloadItems() async {
    return repo.items().then((value) {
      _items = value;
      notifyListeners();
    });
  }

  // void addItem() {
  //   var timestamp = DateTime.now();
  //   var title = timestamp.millisecondsSinceEpoch.toString();
  //   var desc = timestamp.toLocal().toString();
  //
  //   var item = Note(title, desc);
  //   repo.insert(item).then((value) {
  //     reloadItems();
  //   });
  // }

  /*
  * Nếu chọn edit => hiển thị chi tiết 1 note
  * còn chọn create => chỉ cần chuyển sang màn note_view_item
  * */
  void viewItem() {
    // Nếu chọn edit item
    if (editingItem != null) {
      editingControllerTitle.text = editingItem.title;
      editingControllerDesc.text = editingItem.desc;
    }

    state = NoteViewState.itemView;
  }

  /*
   * Hàm này xử chung tạo mới và cập nhật item
   * */
  void saveItem() {
    // 1. CREATE ITEM
    // lấy giá trị hiện tại trong TextEditingController
    var title = editingControllerTitle.text;
    var desc = editingControllerDesc.text;

    if (editingItem == null && title != null && desc != null) {
      var item = Note(title, desc);
      repo.insert(item).then((value) {
        state = (NoteViewState.listView);
        reloadItems();
      });

      return;
    }

    // 2. UPDATE ITEM
    var editNote = _getNewNote();

    // TODO lưu editing item
    repo.update(editNote).then((value) {
      print(value);
      _state = NoteViewState.listView;
    });

    // TODO editingItem = null
    editingItem = null;
    reloadItems();
  }

  Note _getNewNote() {
    return Note.fromMap({
      'id': editingItem.id,
      'title': editingControllerTitle.text,
      'desc': editingControllerDesc.text,
      'isDeleted': editingItem.isDeleted,
    });
  }

  /*
  * Xóa item
  * */
  delete() async {
    repo.delete(editingItem).then((value) {
      _state = NoteViewState.listView;
    });

    editingItem = null;
    return notifyListeners();
  }
}
```

###### note_view_item.dart
 
Đây là widget chung được sử dụng cho cả tạo mới và cập nhật ghi chú.

Widget bao có một Form gồm 2 TextFormField dùng để nhập title và desc.

```dart
import 'package:flutter/material.dart';
import 'package:mynote/ui/views/note/note_viewmodel.dart';
import 'package:stacked/stacked.dart';

class NoteViewItem extends ViewModelWidget<NoteViewModel> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, model) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => model.state = NoteViewState.listView,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => model.saveItem(),
          )
        ],
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    autocorrect: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập tiêu đề',
                    ),
                    validator: (value) {
                      return value.isEmpty ? 'Không được để trống!' : null;
                    },
                    controller: model.editingControllerTitle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Nhập mô tả',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      return value.isEmpty ? 'Không được để trống!' : null;
                    },
                    controller: model.editingControllerDesc,
                    maxLines: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```