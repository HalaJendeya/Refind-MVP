import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/memory_model.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/screen_header.dart';
import '../memory/memory_controller.dart';
import '../save/widgets/details_form.dart';

/// Edits an existing memory. It updates the same Firestore document,
/// so no duplicate is created.
class EditMemoryScreen extends StatefulWidget {
  const EditMemoryScreen({super.key});

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final MemoryController _memories = Get.find<MemoryController>();
  late final Memory? _memory;
  late final DetailsFormData _details;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _memory = _memories.byId(Get.arguments as String);
    _details = DetailsFormData(
      title: _memory?.title ?? '',
      note: _memory?.content ?? '',
      tags: _memory?.tags.join(', ') ?? '',
      category: _memory?.category ?? '',
      intent: _memory?.intent ?? '',
    );
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final memory = _memory;
    if (memory == null || _isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    try {
      final saved = await _memories.updateMemory(
        memory,
        title: _details.title.text.trim(),
        content: _details.note.text.trim(),
        category: _details.category,
        intent: _details.intent,
        tags: _details.tagList,
      );
      if (saved) Get.back();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Edit Memory', backIcon: Icons.close),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: DetailsForm(data: _details),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
