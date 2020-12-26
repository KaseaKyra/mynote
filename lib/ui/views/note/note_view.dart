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
