import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/sheets_and_dialogs.dart';
import '../save_controller.dart';

/// Quick Save: paste a link or some text and save it with one tap.
/// Links are detected automatically; anything else is saved as a note.
void showQuickSaveSheet() {
  // The controller is created for this sheet and removed when it closes.
  final controller = Get.put(SaveController(), tag: 'quick');
  showAppSheet(_QuickSaveSheet(controller: controller)).whenComplete(() {
    Get.delete<SaveController>(tag: 'quick');
  });
}

class _QuickSaveSheet extends StatefulWidget {
  final SaveController controller;

  const _QuickSaveSheet({required this.controller});

  @override
  State<_QuickSaveSheet> createState() => _QuickSaveSheetState();
}

class _QuickSaveSheetState extends State<_QuickSaveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.quickSave(
      text: _inputController.text,
      title: _titleController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Quick Save',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a link or type something to remember.',
              style: AppTheme.text(size: 14, color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: '',
              hint: 'https://... or your text',
              controller: _inputController,
              maxLines: 4,
              minLines: 2,
              validator: (value) => Validators.required(value, 'Link or text'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: '',
              hint: 'Title (optional)',
              controller: _titleController,
            ),
            const SizedBox(height: 20),
            Obx(
              () => PrimaryButton(
                label: 'Save to Library',
                isLoading: widget.controller.isSaving.value,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
