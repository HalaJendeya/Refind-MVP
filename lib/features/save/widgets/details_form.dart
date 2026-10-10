import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Choices offered in the "Category" and "Intent" fields.
const List<String> memoryCategories = [
  'Learning',
  'Inspiration',
  'Work',
  'Personal',
  'Travel',
  'Shopping',
  'Other',
];

const List<String> memoryIntents = [
  'Learn',
  'Buy',
  'Try',
  'Read',
  'Watch',
  'Visit',
];

/// Holds what the user typed/selected in the details form.
/// The screen creates it in initState and calls dispose() in dispose().
class DetailsFormData {
  final TextEditingController title;
  final TextEditingController note;
  final TextEditingController tags;
  String category;
  String intent;

  DetailsFormData({
    String title = '',
    String note = '',
    String tags = '',
    this.category = '',
    this.intent = '',
  }) : title = TextEditingController(text: title),
       note = TextEditingController(text: note),
       tags = TextEditingController(text: tags);

  List<String> get tagList => Validators.parseTags(tags.text);

  void dispose() {
    title.dispose();
    note.dispose();
    tags.dispose();
  }
}

/// Title, Category, Intent, Note and Tags fields shared by the
/// Link / Image / Document save screens and the Edit Memory screen.
class DetailsForm extends StatefulWidget {
  final DetailsFormData data;
  final bool titleRequired;

  const DetailsForm({super.key, required this.data, this.titleRequired = true});

  @override
  State<DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends State<DetailsForm> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    // If an old memory has a category that is not in our list, still show it.
    final categories = [
      if (data.category.isNotEmpty && !memoryCategories.contains(data.category))
        data.category,
      ...memoryCategories,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Title',
          hint: 'Give it a name',
          controller: data.title,
          textInputAction: TextInputAction.next,
          validator: widget.titleRequired
              ? (v) => Validators.required(v, 'Title')
              : null,
        ),
        const SizedBox(height: 16),
        _label('Category (Optional)'),
        DropdownButtonFormField<String>(
          initialValue: data.category.isEmpty ? null : data.category,
          isExpanded: true,
          hint: Text(
            'Choose a category',
            style: AppTheme.text(color: AppColors.textMuted),
          ),
          style: AppTheme.text(),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textMuted,
          ),
          decoration: _dropdownDecoration(),
          items: [
            for (final category in categories)
              DropdownMenuItem(value: category, child: Text(category)),
          ],
          onChanged: (value) => setState(() => data.category = value ?? ''),
        ),
        const SizedBox(height: 16),
        _label('Intent (Optional)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final intent in memoryIntents)
              AppChip(
                label: intent,
                selected: data.intent == intent,
                // Tapping the selected intent again clears it.
                onTap: () => setState(
                  () => data.intent = data.intent == intent ? '' : intent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Note (Optional)',
          hint: 'Why are you saving this?',
          controller: data.note,
          maxLines: 4,
          minLines: 3,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Tags (Optional)',
          hint: 'e.g. design, inspiration',
          controller: data.tags,
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTheme.text(
          size: 14,
          weight: FontWeight.w600,
          color: AppColors.textMedium,
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary),
    );
  }
}
