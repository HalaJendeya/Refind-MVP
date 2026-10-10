import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/screen_header.dart';
import '../auth/auth_controller.dart';

/// Lets the user change their display name.
/// (Profile photos are not part of this MVP.)
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = Get.find<AuthController>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _auth.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _auth.updateName(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Edit Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initialsOf(_auth.displayName, _auth.email),
                    style: AppTheme.text(
                      size: 34,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextLinkButton(
                  label: 'Change photo',
                  onPressed: () => showInfo(
                    'Profile photos are not available in this version yet.',
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: _nameController,
                  validator: (value) => Validators.required(value, 'Name'),
                ),
                const SizedBox(height: 16),
                _readOnlyEmail(),
                const SizedBox(height: 32),
                Obx(
                  () => PrimaryButton(
                    label: 'Save Changes',
                    isLoading: _auth.isLoading.value,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _readOnlyEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTheme.text(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.chipBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _auth.email,
            style: AppTheme.text(color: AppColors.textMedium),
          ),
        ),
      ],
    );
  }
}
