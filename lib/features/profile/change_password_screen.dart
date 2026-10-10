import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/validators.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/screen_header.dart';
import '../auth/auth_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? value) {
    if (value != _newController.text) return 'Passwords do not match';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _auth.changePassword(_currentController.text, _newController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        // Block system Back while saving, so we never close the wrong page.
        canPop: !_auth.isLoading.value,
        child: _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Change Password'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Current Password',
                  hint: '••••••••',
                  controller: _currentController,
                  isPassword: true,
                  validator: (value) =>
                      Validators.required(value, 'Current password'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'New Password',
                  hint: '••••••••',
                  controller: _newController,
                  isPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm New Password',
                  hint: '••••••••',
                  controller: _confirmController,
                  isPassword: true,
                  validator: _confirmValidator,
                ),
                const SizedBox(height: 32),
                Obx(
                  () => PrimaryButton(
                    label: 'Update Password',
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
}
