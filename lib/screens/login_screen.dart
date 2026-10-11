import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'two_factor_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(
        email,
        password,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorScreen(
            email: email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }

      _showMessage(message);
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF64748B),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          // ====================================================
          // BACKGROUND DECORATION
          // ====================================================

          Positioned(
            top: -100,
            right: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: 100,
            left: -130,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA)
                    .withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================

                      Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2563EB),
                                Color(0xFF1D4ED8),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.25),
                                blurRadius: 22,
                                offset:
                                    const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 43,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to continue to FleetOps',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ==================================================
                      // LOGIN CARD
                      // ==================================================

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.05),
                              blurRadius: 25,
                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            // Email
                            Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    const Color(0xFF334155),
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextField(
                              controller:
                                  _emailController,
                              focusNode:
                                  _emailFocusNode,
                              keyboardType:
                                  TextInputType.emailAddress,
                              textInputAction:
                                  TextInputAction.next,
                              onSubmitted: (_) {
                                _passwordFocusNode
                                    .requestFocus();
                              },
                              decoration:
                                  _inputDecoration(
                                label: 'Email',
                                hint:
                                    'Enter your email',
                                icon:
                                    Icons.email_outlined,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    const Color(0xFF334155),
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextField(
                              controller:
                                  _passwordController,
                              focusNode:
                                  _passwordFocusNode,
                              obscureText:
                                  _obscurePassword,
                              textInputAction:
                                  TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isLoading) {
                                  _login();
                                }
                              },
                              decoration:
                                  _inputDecoration(
                                label: 'Password',
                                hint:
                                    'Enter your password',
                                icon:
                                    Icons.lock_outline_rounded,
                                suffixIcon:
                                    IconButton(
                                  tooltip:
                                      _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                    color:
                                        const Color(
                                            0xFF64748B),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),

                            // ==================================================
                            // LOGIN BUTTON
                            // ==================================================

                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : _login,
                                style: ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                      const Color(
                                          0xFF2563EB),
                                  disabledBackgroundColor:
                                      const Color(
                                          0xFF93B4F5),
                                  foregroundColor:
                                      Colors.white,
                                  elevation: 0,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style:
                                                TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                            ),
                                          ),
                                          SizedBox(
                                              width: 8),
                                          Icon(
                                            Icons
                                                .arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ==================================================
                            // SECURITY MESSAGE
                            // ==================================================

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: const Color(
                                    0xFFF0FDF4),
                                borderRadius:
                                    BorderRadius
                                        .circular(13),
                                border:
                                    Border.all(
                                  color: const Color(
                                      0xFFDCFCE7),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration:
                                        const BoxDecoration(
                                      color: Color(
                                          0xFFDCFCE7),
                                      shape:
                                          BoxShape.circle,
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .shield_outlined,
                                      size: 17,
                                      color: Color(
                                          0xFF16A34A),
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10),

                                  const Expanded(
                                    child: Text(
                                      'Your account is protected with secure two-factor authentication.',
                                      style:
                                          TextStyle(
                                        fontSize: 11,
                                        height: 1.4,
                                        color: Color(
                                            0xFF166534),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // ==================================================
                      // FOOTER
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 15,
                            color: const Color(
                              0xFF94A3B8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'FleetOps • Fleet Tracking System',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(
                                0xFF94A3B8,
                              ),
                            ),
                          ),
                        ],
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