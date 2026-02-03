import 'package:escape_room_admin/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _signIn() async {
    setState(() {
      _loginError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network/auth delay (replace with real API / WebSocket / Firebase call)
    await Future.delayed(const Duration(seconds: 1, milliseconds: 800));

    // Fake successful login for now
    // In real app: check credentials, get token, save to secure storage / provider / riverpod
    final success = true; // ← change to false to test error

    setState(() => _isLoading = false);

    if (success) {
      // Update auth state somewhere (e.g. Riverpod notifier, Bloc, or simple global)
      setLoggedIn(true);
      // Then redirect
      if (mounted) {
        context.go('/select-scenario');
      }
    } else {
      setState(() {
        _loginError = 'Invalid email or password. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header / Branding
                      const Icon(
                        Icons.security_rounded,
                        size: 80,
                        color: Color.fromARGB(255, 183, 58, 58),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Escape Room Control',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 115, 31, 31),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to manage scenarios & surveillance',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: _validateEmail,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signIn(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () => setState(() => _isObscure = !_isObscure),
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: _validatePassword,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Error message
                      if (_loginError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _loginError!,
                            style: TextStyle(color: theme.colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Sign In Button
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _signIn,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          _isLoading ? 'Signing in...' : 'Sign In',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Optional links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              // TODO: Forgot password screen / dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Forgot password feature coming soon')),
                              );
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}