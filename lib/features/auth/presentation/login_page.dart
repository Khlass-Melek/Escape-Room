import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/auth/presentation/providers/auth_provider.dart';
import 'package:escape_room_admin/shared/widgets/animations.dart';
import 'package:escape_room_admin/shared/widgets/custom_text_field.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      next.when(
        data: (state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppTheme.primaryRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.isAuthenticated) {
            context.go('/dashboard-home');
          }
        },
        error: (err, stack) {},
        loading: () {},
      );
    });

    final authStateAsync = ref.watch(authProvider);
    final authState = authStateAsync.value ?? const AuthState();
    final isLoading = authStateAsync.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Background Decoration
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/saw1.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryRed.withOpacity(0.05),
                  AppTheme.primaryBlack,
                  AppTheme.primaryBlack,
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeInSlide(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Gap(32),
                      const FadeInSlide(
                        delay: 0.2,
                        child: Text(
                          'SYSTÈME DE CONTRÔLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const FadeInSlide(
                        delay: 0.3,
                        child: Text(
                          'ACCÈS SÉCURISÉ REQUIS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Gap(48),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _usernameController,
                              label: 'Email',
                              hint: 'Entrez votre email',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer une adresse email';
                                }
                                return null;
                              },
                            ),
                            const Gap(16),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              hint: 'Entrez votre mot de passe',
                              obscureText: !_isPasswordVisible,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: AppTheme.grayText,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un mot de passe';
                                }
                                return null;
                              },
                            ),
                            const Gap(24),
                            
                            // Error Message
                            if (authState.error != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryRed.withOpacity(0.1),
                                  border: Border.all(color: AppTheme.secondaryRed),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppTheme.primaryRed),
                                    const Gap(8),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: const TextStyle(color: AppTheme.primaryRed),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            const Gap(24),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: PrimaryButton(
                                label: 'SE CONNECTER',
                                isLoading: isLoading,
                                onPressed: _handleLogin,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.white,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}