import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../auth_controller.dart';
import 'auth_widgets.dart';
import '../../../shared/widgets/refind_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _auth.login(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const ReFindLogo(size: 48),
                const SizedBox(height: 28),
                Text(
                  'Welcome back',
                  style: AppTheme.text(size: 30, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to access your digital memory.',
                  style: AppTheme.text(size: 16, color: AppColors.textMedium),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Email',
                  hint: 'alex@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.required(value, 'Password'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextLinkButton(
                    label: 'Forgot password?',
                    onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => PrimaryButton(
                    label: 'Log In',
                    isLoading: _auth.isLoading.value,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),
                Obx(() {
                  final busy =
                      _auth.isLoading.value || _auth.isGoogleLoading.value;
                  return SecondaryButton(
                    label: 'Continue with Google',
                    leading: _auth.isGoogleLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            'G',
                            style: AppTheme.text(
                              size: 20,
                              weight: FontWeight.w700,
                              color: const Color(0xFF4285F4),
                            ),
                          ),
                    onPressed: busy ? null : _auth.signInWithGoogle,
                  );
                }),
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTheme.text(
                          size: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                      TextLinkButton(
                        label: 'Sign up',
                        onPressed: () => Get.toNamed(AppRoutes.signup),
                      ),
                    ],
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
