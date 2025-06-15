import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/user_repository.dart';
import '../../routes/app_router.dart';
import 'package:get_it/get_it.dart';

import '../../utils/app_colors.dart';
import '../../widgets/loading_button.dart';

@RoutePage()
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordReset = false;
  
  // Tahapan reset password:
  // 1. Input email
  // 2. Input password baru (jika email valid)
  // 3. Sukses
  int _currentStep = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  // Validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Helper method to show error snackbar
  void _showErrorSnackBar(String message) {
    // Extract just the relevant part of the error message if it's from our exception
    String displayMessage = message;
    if (message.startsWith('Exception: ')) {
      displayMessage = message.substring('Exception: '.length);
    }
    
    // Limit the length of the message for better display
    if (displayMessage.length > 100) {
      displayMessage = '${displayMessage.substring(0, 100)}...';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  // Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.black,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.black,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Check if email exists
  Future<void> _checkEmailExists() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        _emailController.text.trim();
        
        // Skip pengecekan email dan asumsikan email valid
        // (PocketBase akan menolak reset jika email tidak ada)
        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
        
        _showSuccessSnackBar('Silakan masukkan password baru Anda.');
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }
  
  // Reset password directly using email instead of user ID
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userRepository = GetIt.I<UserRepository>();
        final email = _emailController.text.trim();
        
        // Gunakan metode resetPasswordDirect baru yang tidak memerlukan user ID
        final result = await userRepository.resetPasswordDirect(
          email,
          _newPasswordController.text,
        );
        
        if (result['success'] == true) {
          // Handle success case
          if (result['method'] == 'email_reset' && result['message'] != null) {
            // If it was an email reset, show the message but keep on reset screen
            setState(() {
              _isLoading = false;
            });
            _showSuccessSnackBar(result['message']);
          } else {
            // For direct password resets, show success screen
            setState(() {
              _isLoading = false;
              _passwordReset = true;
            });
          }
        } else {
          // Handle error case
          setState(() {
            _isLoading = false;
            _errorMessage = result['error'] ?? 'Unknown error occurred';
          });
          _showErrorSnackBar(_errorMessage!);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // Handle next step
  Future<void> _handleNextStep() async {
    if (_currentStep == 1) {
      await _checkEmailExists();
    } else if (_currentStep == 2) {
      await _resetPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _passwordReset ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/wave_icon.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _currentStep == 1 ? 'Forgot Password' : 'Create New Password',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _currentStep == 1 
                ? 'Masukkan email akun Anda untuk reset password secara langsung'
                : 'Silakan masukkan password baru untuk akun Anda',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          
          // Email input step
          if (_currentStep == 1)
            _buildTextField(
              controller: _emailController,
              hint: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            
          // Password reset step  
          if (_currentStep == 2) ...[
            Text(
              'Email: ${_emailController.text}',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newPasswordController,
              hint: 'New Password',
              icon: Icons.lock_outline,
              isPassword: true,
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: 'Confirm New Password',
              icon: Icons.lock_outline,
              isPassword: true,
              validator: _validateConfirmPassword,
            ),
          ],
          
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade800),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
          
          // Continue button
          LoadingButton(
            text: _currentStep == 1 ? 'Lanjutkan' : 'Reset Password',
            isLoading: _isLoading,
            onPressed: _handleNextStep,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => context.router.replace(const LoginRoute()),
              child: const Text(
                'Kembali ke Login',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.primary,
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Berhasil Direset',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Password Anda telah berhasil diubah. Anda dapat login menggunakan password baru.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.router.replace(const LoginRoute()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Kembali ke Login',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        validator: validator,
        obscureText: isPassword,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.6),
            fontFamily: 'DM Sans',
          ),
          prefixIcon: Icon(
            icon,
            color: const Color.fromRGBO(255, 255, 255, 0.6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


