import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/ui_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/screen_header.dart';
import '../save_controller.dart';
import '../widgets/details_form.dart';

/// Step 1: paste a URL. Step 2: preview it and add optional details.
/// We do not download the web page (that needs a backend), so the title
/// starts as the website name and the user can change it.
class AddLinkScreen extends StatefulWidget {
  const AddLinkScreen({super.key});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  final _urlFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final DetailsFormData _details = DetailsFormData();
  final SaveController _save = Get.find<SaveController>();

  bool _showDetails = false;
  String _url = '';

  @override
  void initState() {
    super.initState();

    final arguments = Get.arguments;

    if (arguments is Map && arguments['sharedUrl'] is String) {
      final sharedUrl = (arguments['sharedUrl'] as String).trim();

      if (sharedUrl.isNotEmpty) {
        _urlController.text = sharedUrl;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _generatePreview();
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _details.dispose();
    super.dispose();
  }

  void _generatePreview() {
    if (!_urlFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _url = Validators.normalizeUrl(_urlController.text);
    _details.title.text = Uri.parse(_url).host.replaceFirst('www.', '');
    setState(() => _showDetails = true);
  }

  void _saveLink() {
    if (!_detailsFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _save.saveLink(
      url: _url,
      title: _details.title.text.trim(),
      note: _details.note.text.trim(),
      category: _details.category,
      intent: _details.intent,
      tags: _details.tagList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(
        title: _showDetails ? 'Save Link' : 'Add Link',
        onBack: () {
          if (_showDetails) {
            setState(() => _showDetails = false);
          } else {
            closePage();
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _showDetails ? _detailsStep() : _urlStep(),
        ),
      ),
    );
  }

  Widget _urlStep() {
    return Form(
      key: _urlFormKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Paste URL',
            hint: 'https://',
            controller: _urlController,
            keyboardType: TextInputType.url,
            autofocus: true,
            validator: Validators.url,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Generate Preview', onPressed: _generatePreview),
        ],
      ),
    );
  }

  Widget _detailsStep() {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewCard(),
          const SizedBox(height: 24),
          Text(
            'OPTIONAL DETAILS',
            style: AppTheme.text(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.textMedium,
            ).copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            'You can add metadata now or organize it later.',
            style: AppTheme.text(size: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          DetailsForm(data: _details),
          const SizedBox(height: 24),
          Obx(
            () => PrimaryButton(
              label: 'Save to Library',
              isLoading: _save.isSaving.value,
              onPressed: _saveLink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final host = Uri.parse(_url).host.replaceFirst('www.', '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.link, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TypeBadge(label: 'Link'),
                const SizedBox(height: 6),
                Text(host, style: AppTheme.text(weight: FontWeight.w600)),
                Text(
                  _url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(size: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
