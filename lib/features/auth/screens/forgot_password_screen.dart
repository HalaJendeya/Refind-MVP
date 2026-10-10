import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../auth_controller.dart';

/// Step 1: ask for the email. Step 2: "check your inbox" confirmation.
/// Firebase sends the email and hosts the page where the new password is typed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final sent = await _auth.sendPasswordReset(_emailController.text);
    if (sent && mounted) setState(() => _emailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _emailSent ? _sentView() : _formView(),
        ),
      ),
    );
  }

  Widget _icon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(Icons.mail_outline),
          const SizedBox(height: 24),
          Text(
            'Reset your password',
            style: AppTheme.text(size: 28, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "Enter the email address associated with your account and we'll send you a link to reset your password.",
            style: AppTheme.text(
              size: 16,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Email Address',
            hint: 'alex@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 24),
          Obx(
            () => PrimaryButton(
              label: 'Send Reset Link',
              isLoading: _auth.isLoading.value,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextLinkButton(
              label: 'Back to Log In',
              onPressed: () => Get.back(),
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icon(Icons.mark_email_read_outlined),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: AppTheme.text(size: 28, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'If an account exists for ${_emailController.text.trim()}, we sent a link to reset your password. '
          'Open it, choose a new password, then come back and log in.',
          style: AppTheme.text(
            size: 16,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Back to Log In', onPressed: () => Get.back()),
        const SizedBox(height: 8),
        Center(
          child: TextLinkButton(
            label: 'Use a different email',
            onPressed: () => setState(() => _emailSent = false),
          ),
        ),
      ],
    );
  }
}
