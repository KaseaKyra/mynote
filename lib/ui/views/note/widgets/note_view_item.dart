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
