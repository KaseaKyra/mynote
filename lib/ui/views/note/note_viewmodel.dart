import 'package:flutter/material.dart';
import 'package:mynote/ui/views/note/note_repository.dart';
import 'package:stacked/stacked.dart';

import 'note_model.dart';

/// Trạng thái của view
enum NoteViewState { listView, itemView}

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

  void addItem() {
    var timestamp = DateTime.now();
    var title = timestamp.millisecondsSinceEpoch.toString();
    var desc = timestamp.toLocal().toString();

    var item = Note(title, desc);
    repo.insert(item).then((value) {
      reloadItems();
    });
  }

  void viewItem() {
    // Nếu chọn edit item
    if (editingItem != null) {
      editingControllerTitle.text = editingItem.title;
      editingControllerDesc.text = editingItem.desc;
    }

    state = NoteViewState.itemView;
  }

  void saveItem() {
    // 1. CREATE ITEM
    var title = editingControllerTitle.text;
    var desc = editingControllerDesc.text;

    if (editingItem == null && title != null && desc != null) {
      var item = Note(title, desc);
      repo.insert(item).then((value) {
        print(value);
        // TODO: return list
        state = (NoteViewState.listView);
        reloadItems();
        return;
      });
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

    return notifyListeners();
  }
}
