import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/widgets/app_button.dart';
import 'package:skep_app/core/widgets/app_text_field.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/auth/bloc/auth_state.dart';
import 'package:skep_app/features/auth/model/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = '이메일을 입력해주세요');
      isValid = false;
    } else if (!_emailRegex.hasMatch(_emailController.text)) {
      setState(() => _emailError = '잘못된 이메일 형식입니다');
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = '비밀번호를 입력해주세요');
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = '비밀번호는 6자 이상이어야 합니다');
      isValid = false;
    }

    return isValid;
  }

  void _handleLogin() {
    if (_validateInputs()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF1F5F9) : AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final role = UserRole.fromString(state.user.role);
            switch (role) {
              case UserRole.platformAdmin:
                context.go('/admin-dashboard');
              case UserRole.equipmentSupplier:
                context.go('/supplier-dashboard');
              case UserRole.bpCompany:
                context.go('/bp-dashboard');
              case UserRole.driver:
              case UserRole.guide:
                context.go('/work-records');
              case UserRole.safetyInspector:
                context.go('/inspections/current');
            }
          } else if (state is AuthFailure) {
            String errorMsg = state.message;
            if (errorMsg.contains('SocketException') || errorMsg.contains('Connection')) {
              errorMsg = '네트워크 오류: 서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.';
            } else if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
              errorMsg = '이메일 또는 비밀번호가 올바르지 않습니다.';
            } else if (errorMsg.contains('timeout')) {
              errorMsg = '서버 응답 시간이 초과되었습니다. 다시 시도해주세요.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isDesktop ? 440 : double.infinity,
              margin: isDesktop
                  ? const EdgeInsets.symmetric(vertical: 40)
                  : EdgeInsets.zero,
              padding: const EdgeInsets.all(32),
              decoration: isDesktop
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 로고
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('S', style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            )),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SKEP',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '산업현장 장비 투입 관리 플랫폼',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 로그인 폼
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return Column(
                        children: [
                          AppTextField(
                            label: '이메일',
                            hint: '이메일 주소를 입력하세요',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            readOnly: isLoading,
                          ),
                          const SizedBox(height: 20),
                          AppTextField(
                            label: '비밀번호',
                            hint: '비밀번호를 입력하세요',
                            controller: _passwordController,
                            obscureText: true,
                            errorText: _passwordError,
                            readOnly: isLoading,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppTextButton(
                              label: '비밀번호를 잊으셨나요?',
                              onPressed: isLoading ? () {} : () {},
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: '로그인',
                            onPressed: isLoading ? () {} : _handleLogin,
                            isLoading: isLoading,
                            width: double.infinity,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: AppColors.border)),
                      const SizedBox(width: 16),
                      Text('또는', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 16),
                      Expanded(child: Container(height: 1, color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('계정이 없으신가요? ', style: AppTextStyles.bodyMedium),
                      AppTextButton(
                        label: '회원가입',
                        onPressed: () => context.go('/register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
