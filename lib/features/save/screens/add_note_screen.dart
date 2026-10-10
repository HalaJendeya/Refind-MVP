import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/screen_header.dart';
import '../save_controller.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final SaveController _save = Get.find<SaveController>();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _save.saveNote(title: _titleController.text, content: _noteController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Add Note'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Title',
                  hint: 'e.g. Ideas for my next Flutter project',
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Note',
                  hint: 'Write your note...',
                  controller: _noteController,
                  isRequiredMark: true,
                  minLines: 8,
                  maxLines: 14,
                  validator: (value) => Validators.required(value, 'Note'),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => PrimaryButton(
                    label: 'Save Note',
                    isLoading: _save.isSaving.value,
                    onPressed: _saveNote,
                  ),
                ),
                const SizedBox(height: 12),
                SecondaryButton(label: 'Cancel', onPressed: () => Get.back()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
