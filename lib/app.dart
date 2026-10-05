import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'models/senzhub_models.dart';
import 'services/mock_data_service.dart';
import 'services/device_repository.dart';
import 'widgets/gas_level_ring.dart';
import 'widgets/glass_card.dart';
import 'widgets/mini_line_chart.dart';
import 'widgets/status_chip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/auth_service.dart';
import 'core/supabase/realtime_service.dart';

class SenzHubApp extends StatelessWidget {
  const SenzHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeChoice, _) {
        return ValueListenableBuilder<AppAppearanceMode>(
          valueListenable: AppTheme.appearanceNotifier,
          builder: (context, appearanceMode, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'SENZHUB',
              theme: AppTheme.themeFor(
                themeChoice,
                brightness: Brightness.light,
              ),
              darkTheme: AppTheme.themeFor(
                themeChoice,
                brightness: Brightness.dark,
              ),
              themeMode: AppTheme.themeMode,
              routes: {
                '/splash': (_) => const SplashScreen(),
                '/onboarding': (_) => const OnboardingScreen(),
                '/login': (_) => const LoginScreen(),
                '/register': (_) => const RegisterScreen(),
                '/forgot-password': (_) => const ForgotPasswordScreen(),
                '/setup-pin': (_) => const SetupPinScreen(),
                '/verify-otp': (context) => VerifyOtpScreen(
                  phone: ModalRoute.of(context)!.settings.arguments as String,
                ),
                '/reset-password': (_) => const ResetPasswordScreen(),
                '/reset-pin': (_) => const ResetPinScreen(),
                '/verification': (_) => const TwoStepVerificationScreen(),
                '/dashboard': (_) => const DashboardScreen(),
                                '/diagnostics': (_) => const DiagnosticsScreen(),
                '/booking': (_) => const LpgBookingScreen(),
                '/theme-settings': (_) => const ThemeSettingsScreen(),
                '/sdg-goals': (_) => const SdgGoalsScreen(),
                '/about': (_) => const AboutScreen(),
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _splashTimer;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService().authStateChanges.listen((data) async {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isPinRecovery = prefs.getBool('is_pin_recovery') ?? false;
        await prefs.remove('is_pin_recovery');
        if (!mounted) return;
        
        if (isPinRecovery) {
          Navigator.of(context).pushReplacementNamed('/reset-pin');
        } else {
          Navigator.of(context).pushReplacementNamed('/reset-password');
        }
      }
    });

    _splashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final user = AuthService().currentUser;
      if (user != null) {
        Navigator.of(context).pushReplacementNamed('/verification');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, const Color(0xFF0A1715)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 46,
                  color: AppTheme.accentSoft,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SENZHUB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Smart LPG Gas Safety & Monitoring',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 14,
                  letterSpacing: 0.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = MockDataService.onboardingSlides;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.accentSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (value) =>
                      setState(() => _currentPage = value),
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = constraints.maxHeight;
                          return SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: availableHeight > 0
                                    ? availableHeight
                                    : 0,
                              ),
                              child: Center(
                                child: GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _onboardingIcon(slide.icon),
                                            size: 36,
                                            color: AppTheme.accentSoft,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      StatusChip(
                                        label: slide.badge,
                                        tone: StatusTone.info,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        slide.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        slide.subtitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.accent
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_currentPage < slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _currentPage == slides.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _onboardingIcon(String key) {
    switch (key) {
      case 'shield':
        return Icons.shield_rounded;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'lock':
        return Icons.lock_outline_rounded;
      default:
        return Icons.sensor_occupied_rounded;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);
      // Ensure the user has a personal organization now that a session exists.
      await _authService.ensurePersonalOrganization();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/verification');
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException during signIn: ${e.message} (statusCode: ${e.statusCode})');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.formatAuthError(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during signIn: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.formatAuthError(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const SizedBox(height: 28),
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Secure control for your LPG safety system.',
                style: TextStyle(color: AppTheme.muted, fontSize: 15),
              ),
              const SizedBox(height: 26),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Email address is required';
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value!.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/forgot-password'),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: AppTheme.accentSoft),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to SENZHUB?',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/register'),
                    child: Text(
                      'Create account',
                      style: TextStyle(color: AppTheme.accentSoft),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    final phone = _emailController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.requestPhoneOtp(phone);
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        '/verify-otp',
        arguments: phone,
      );
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException during requestPhoneOtp: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.formatAuthError(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during requestPhoneOtp: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          duration: Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Forgot password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Reset your password',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the mobile number associated with your SENZHUB account and we will send you a 6-digit OTP.',
                style: TextStyle(color: AppTheme.muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleResetRequest,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Send OTP',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.phone});
  
  final String phone;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    
    setState(() => _isLoading = true);
    try {
      await _authService.requestPhoneOtp(widget.phone);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPhoneOtp(widget.phone, otp);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/reset-password');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.formatAuthError(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired OTP.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Enter Verification Code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${widget.phone}.',
                style: const TextStyle(color: AppTheme.muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP',
                        prefixIcon: Icon(Icons.password_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Verify OTP',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (_countdown > 0 || _isLoading) ? null : _handleResend,
                      child: Text(
                        _countdown > 0 ? 'Resend OTP in ${_countdown}s' : 'Resend OTP',
                        style: TextStyle(
                          color: _countdown > 0 ? AppTheme.muted : AppTheme.accentSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter and confirm your new password.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updatePassword(password);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Password updated'),
          content: const Text(
            'Your password has been updated successfully. Please log in with your new password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException during updatePassword: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.formatAuthError(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during updatePassword: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          duration: Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set new password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Create new password',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your new password must be at least 6 characters long.',
                style: TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleUpdatePassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Update password',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // When email confirmation is enabled, the session is null after signUp.
      // Do NOT navigate as if the user is authenticated.
      // Instead, inform them to confirm their email.
      final confirmed = response.session != null;
      final email = _emailController.text.trim();
      if (confirmed) {
        // Email confirmation is disabled — session is immediately available.
        await _authService.ensurePersonalOrganization();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/verification');
      } else {
        // Email confirmation is enabled — user must verify inbox before logging in.
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm your email'),
            content: Text(
              'Registration successful. We sent a confirmation link to $email. '
              'Please check your inbox and confirm your account before logging in.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException during signUp: ${e.message} (statusCode: ${e.statusCode})');
      if (!mounted) return;
      
      String errorMessage = AuthService.formatAuthError(e);
      // Explicitly check for rate limit errors and override the message for UX
      if (e.statusCode == '429' || e.statusCode == '429' || e.message.toLowerCase().contains('rate limit')) {
        errorMessage = 'Too many signup attempts. Please wait a few minutes and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during signUp: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.formatAuthError(e)),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Email address is required';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value!.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final trimmed = (value ?? '').replaceAll(
                        RegExp(r'\s+'),
                        '',
                      );
                      if (trimmed.isEmpty) {
                        return 'Phone number is required';
                      }
                      if (trimmed.length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Password is required';
                      }
                      if ((value ?? '').length < 6) {
                        return 'Use at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Create account',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                        child: Text(
                          'Login',
                          style: TextStyle(color: AppTheme.accentSoft),
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
    );
  }
}

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _deviceRepository = DeviceRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.isEmpty || confirmPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter and confirm your new PIN.')),
      );
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits.')),
      );
      return;
    }
    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _deviceRepository.resetValvePin(pin);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('PIN Updated'),
          content: const Text('Your valve PIN has been reset securely.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting PIN: $e'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Reset Valve PIN', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Enter a new 4-digit PIN for valve operations. This replaces your previous PIN securely.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New 4-digit PIN',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF142C24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirm New PIN',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF142C24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleResetPin,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFB2),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Reset PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _deviceRepository = DeviceRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSetupPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.isEmpty || confirmPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter and confirm your new PIN.')),
      );
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits.')),
      );
      return;
    }
    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _deviceRepository.setValvePin(pin); // setValvePin, NOT resetValvePin
      if (!mounted) return;

      // Mark the local PIN-configured state as true
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_secure_pin_configured', true);
      if (!mounted) return;

      // Successfully configured, go to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (!mounted) return;
      String message = 'Error setting PIN: $e';
      if (e.toString().contains('409') || e.toString().contains('already configured')) {
        message = 'A PIN has already been set for this account. Continuing to dashboard.';
        // Also update local cache
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('has_secure_pin_configured', true);
        });
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Do not allow Back/cancel to bypass PIN setup
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: const Text('Set your SENZHUB PIN', style: TextStyle(color: Colors.white)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'Create a mandatory 4-digit PIN to secure your valve operations.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New 4-digit PIN',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF142C24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm New PIN',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF142C24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSetupPin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFB2),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Complete Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TwoStepVerificationScreen extends StatefulWidget {
  const TwoStepVerificationScreen({super.key});

  @override
  State<TwoStepVerificationScreen> createState() =>
      _TwoStepVerificationScreenState();
}

class _TwoStepVerificationScreenState extends State<TwoStepVerificationScreen> {
  static const String mockCode = '482716';
  static const int _initialCountdown = 134;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _countdownTimer;
  int _secondsRemaining = _initialCountdown;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _handleDigitInput(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
      return;
    }

    final nextValue = digit.length > 1
        ? digit.substring(digit.length - 1)
        : digit;
    _controllers[index].value = TextEditingValue(
      text: nextValue,
      selection: const TextSelection.collapsed(offset: 1),
    );

    if (nextValue.isNotEmpty && index < _controllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handlePaste() async {
    final clipboardData = await Clipboard.getData('text/plain');
    final pasted = (clipboardData?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (pasted.isEmpty) return;
    final digits = pasted.split('').take(6).toList();
    for (var i = 0; i < digits.length; i++) {
      if (i < _controllers.length) {
        _controllers[i].text = digits[i];
      }
    }
    for (var i = 0; i < _controllers.length; i++) {
      final node = _focusNodes[i];
      if (i < digits.length) {
        node.requestFocus();
      }
    }
    final nextIndex = digits.length >= 6 ? 5 : digits.length;
    if (nextIndex < _controllers.length) {
      _focusNodes[nextIndex].requestFocus();
    }
    setState(() {});
  }

  void _resendCode() {
    _secondsRemaining = _initialCountdown;
    _errorText = '';
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    _countdownTimer?.cancel();
    _startCountdown();
    setState(() {});
  }

  bool _isLoading = false;

  Future<void> _verifyCode() async {
    if (_code.length != 6) {
      setState(() => _errorText = 'Enter the full 6-digit code.');
      return;
    }

    if (_code == mockCode) {
      setState(() => _isLoading = true);
      try {
        final deviceRepo = DeviceRepository();
        final hasPin = await deviceRepo.getValvePinStatus();
        
        if (!mounted) return;
        
        if (hasPin) {
          // User already has a PIN. Update cache.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_secure_pin_configured', true);
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          // Mandatory PIN setup for new users
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/setup-pin');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorText = 'Unable to verify SENZHUB security status. Please check your connection and try again.';
        });
      }
      return;
    }

    setState(() => _errorText = 'Invalid verification code. Please try again.');
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _code.length == 6;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Two-step verification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 6-digit verification code sent to your registered number.',
                style: TextStyle(color: AppTheme.muted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onLongPress: _handlePaste,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 40,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _controllers[index].text.isNotEmpty
                                    ? AppTheme.accent
                                    : AppTheme.accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              onChanged: (value) =>
                                  _handleDigitInput(index, value),
                              onTap: () => _controllers[index].selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _controllers[index].text.length,
                                    ),
                                  ),
                              onSubmitted: (_) {
                                if (index < _controllers.length - 1) {
                                  _focusNodes[index + 1].requestFocus();
                                }
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              cursorColor: AppTheme.accent,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Code expires in ${_formatCountdown(_secondsRemaining)}',
                          style: TextStyle(
                            color: AppTheme.accentSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_secondsRemaining == 0)
                          TextButton(
                            onPressed: _resendCode,
                            child: Text(
                              'Resend code',
                              style: TextStyle(color: AppTheme.accentSoft),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_errorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorText,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_isLoading || !isReady) ? null : _verifyCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Verify and continue',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        'Resend code',
                        style: TextStyle(color: AppTheme.accentSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    MonitorScreen(),
    AlertsScreen(),
    DevicesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart_rounded),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other_rounded),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeviceRepository _deviceRepo = DeviceRepository();
  final RealtimeService _realtimeService = RealtimeService();

  Future<SystemSnapshot?>? _snapshotFuture;
  SystemSnapshot? _currentSnapshot;
  RealtimeChannel? _readingsChannel;
  RealtimeChannel? _devicesChannel;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  void _loadSnapshot() {
    _snapshotFuture = _deviceRepo.getDashboardSnapshot().then((snap) {
      if (snap != null && mounted) {
        setState(() {
          _currentSnapshot = snap;
        });
        _setupRealtime(snap.deviceId);
      }
      return snap;
    });
  }

  void _setupRealtime(String deviceId) {
    _realtimeService.unsubscribe(_readingsChannel);
    _realtimeService.unsubscribe(_devicesChannel);

    _readingsChannel = _realtimeService.subscribeToReadings(
      deviceId: deviceId,
      onNewReading: (newRecord) {
        if (!mounted || _currentSnapshot == null) return;
        final newPpm = newRecord['gas_level_ppm'] as int? ?? 0;
        final safety = _safetyFromGas(
          newPpm,
          _currentSnapshot!.warningThreshold,
          _currentSnapshot!.dangerThreshold,
        );

        setState(() {
          _currentSnapshot = SystemSnapshot(
            gasLevelPpm: newPpm,
            warningThreshold: _currentSnapshot!.warningThreshold,
            dangerThreshold: _currentSnapshot!.dangerThreshold,
            gasStatus: safety,
            valveState: _currentSnapshot!.valveState,
            battery: newRecord['battery_percentage'] as int? ?? _currentSnapshot!.battery,
            gsmSignalCsq: newRecord['gsm_signal_csq'] as int? ?? _currentSnapshot!.gsmSignalCsq,
            gsmSignalQuality: _currentSnapshot!.gsmSignalQuality,
            systemOnline: _currentSnapshot!.systemOnline,
            powerSource: _currentSnapshot!.powerSource,
            latestAlert: _currentSnapshot!.latestAlert,
            deviceId: _currentSnapshot!.deviceId,
            location: _currentSnapshot!.location,
          );
        });
      },
    );

    _devicesChannel = _realtimeService.subscribeToDevices(
      onDeviceUpdate: (updatedRecord) {
        if (!mounted || _currentSnapshot == null) return;
        final updatedId = updatedRecord['serial_number'] as String? ?? updatedRecord['id'] as String?;
        if (updatedId != _currentSnapshot!.deviceId && updatedRecord['id'] != _currentSnapshot!.deviceId) return;

        final gasStatusStr = (updatedRecord['gas_status'] as String?)?.toUpperCase() ?? 'SAFE';
        final valveStatusStr = (updatedRecord['valve_status'] as String?)?.toUpperCase() ?? 'OPEN';
        final powerSourceStr = (updatedRecord['power_source'] as String?)?.toUpperCase() ?? 'AC';
        final deviceStatusStr = (updatedRecord['device_status'] as String?)?.toUpperCase() ?? 'OFFLINE';

        SafetyLevel safety;
        if (gasStatusStr == 'DANGER') {
          safety = SafetyLevel.danger;
        } else if (gasStatusStr == 'WARNING') {
          safety = SafetyLevel.warning;
        } else {
          safety = SafetyLevel.safe;
        }

        final ValveState valve = valveStatusStr == 'CLOSED' ? ValveState.closed : ValveState.open;

        setState(() {
          _currentSnapshot = SystemSnapshot(
            gasLevelPpm: _currentSnapshot!.gasLevelPpm,
            warningThreshold: updatedRecord['warning_threshold_ppm'] as int? ?? _currentSnapshot!.warningThreshold,
            dangerThreshold: updatedRecord['danger_threshold_ppm'] as int? ?? _currentSnapshot!.dangerThreshold,
            gasStatus: safety,
            valveState: valve,
            battery: updatedRecord['battery_percentage'] as int? ?? _currentSnapshot!.battery,
            gsmSignalCsq: updatedRecord['gsm_signal'] as int? ?? _currentSnapshot!.gsmSignalCsq,
            gsmSignalQuality: _currentSnapshot!.gsmSignalQuality,
            systemOnline: deviceStatusStr == 'ONLINE',
            powerSource: powerSourceStr == 'BATTERY' ? PowerSource.battery : PowerSource.ac,
            latestAlert: _currentSnapshot!.latestAlert,
            deviceId: _currentSnapshot!.deviceId,
            location: _currentSnapshot!.location,
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _realtimeService.unsubscribe(_readingsChannel);
    _realtimeService.unsubscribe(_devicesChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<SystemSnapshot?>(
          future: _snapshotFuture,
          builder: (context, snapshotAsync) {
            if (snapshotAsync.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshotAsync.hasError) {
              return Center(child: Text('Error loading devices: ${snapshotAsync.error}'));
            }
            final snapshot = _currentSnapshot ?? snapshotAsync.data;
            if (snapshot == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.devices_other_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No devices found.', style: theme.textTheme.titleMedium),
                  ],
                ),
              );
            }

            final status = _safetyFromGas(
              snapshot.gasLevelPpm,
              snapshot.warningThreshold,
              snapshot.dangerThreshold,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, ${AuthService().currentUser?.userMetadata?['full_name']?.split(' ')[0] ?? 'User'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SENZHUB Status',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall safety',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: secondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _safetyLabel(status),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: textColor,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                snapshot.valveState == ValveState.closed
                                    ? 'Valve closed • Safety lock active'
                                    : 'Valve ${_valveLabel(snapshot.valveState).toLowerCase()} • System is monitoring',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _safetyMessage(status),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryColor,
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _safetyColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _safetyIcon(status),
                            color: _safetyColor(status),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricPill(
                          label: 'Gas',
                          value: '${snapshot.gasLevelPpm}',
                        ),
                        _MetricPill(
                          label: 'Battery',
                          value: snapshot.battery != null ? '${snapshot.battery}%' : 'N/A',
                        ),
                        _MetricPill(
                          label: 'Valve',
                          value: _valveLabel(snapshot.valveState),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live sensor reading',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: secondaryColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: GasLevelRing(
                              value: snapshot.gasLevelPpm,
                              warningThreshold: snapshot.warningThreshold,
                              dangerThreshold: snapshot.dangerThreshold,
                              size: 148,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${snapshot.gasLevelPpm}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Warning / Danger thresholds',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _StatusRow(
                            label: 'GSM',
                            value: _gsmQualityLabel(snapshot.gsmSignalCsq),
                          ),
                          _StatusRow(
                            label: 'Power',
                            value: snapshot.powerSource != null ? _powerSourceLabel(snapshot.powerSource!) : 'Not measured',
                          ),
                          _StatusRow(
                            label: 'Status',
                            value: snapshot.systemOnline ? 'ONLINE' : 'OFFLINE',
                          ),
                          ValveControlWidget(snapshot: snapshot),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Latest alert',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        StatusChip(
                          label: _severityLabel(snapshot.latestAlert.severity),
                          tone: _alertTone(snapshot.latestAlert.severity),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      snapshot.latestAlert.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.latestAlert.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          snapshot.latestAlert.timestamp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${snapshot.latestAlert.gasLevel}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.shield_rounded,
                      label: 'Valve',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/valve-control'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.analytics_outlined,
                      label: 'Diagnostics',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/diagnostics'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.local_gas_station_rounded,
                label: 'LPG Booking',
                fullWidth: true,
                onTap: () => Navigator.of(context).pushNamed('/booking'),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Impact',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supporting the Sustainable Development Goals',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/sdg-goals'),
                        icon: const Icon(Icons.eco_rounded),
                        label: const Text('SDG Goals'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.memory_rounded, color: AppTheme.accentSoft),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.deviceId,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                snapshot.location,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(label: 'ONLINE', tone: StatusTone.positive),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
          },
        ),
      ),
    );
  }
}

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final DeviceRepository _deviceRepo = DeviceRepository();
  final RealtimeService _realtimeService = RealtimeService();

  late Future<MonitoringData?> _monitoringFuture;
  MonitoringData? _currentData;
  RealtimeChannel? _readingsChannel;
  RealtimeChannel? _devicesChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<DeviceRecord> _devices = [];
  String? _selectedDeviceId;

  void _loadData() {
    _monitoringFuture = _fetchData();
  }

  Future<MonitoringData?> _fetchData() async {
    final devices = await _deviceRepo.getDevices();
    if (!mounted) return null;
    
    setState(() {
      _devices = devices;
      if (_devices.isNotEmpty && _selectedDeviceId == null) {
        _selectedDeviceId = _devices.first.id;
      }
    });

    if (_devices.isEmpty || _selectedDeviceId == null) {
      setState(() {
        _currentData = null;
      });
      return null;
    }

    final data = await _deviceRepo.getMonitoringSnapshot(_selectedDeviceId);
    if (data != null && mounted) {
      setState(() {
        _currentData = data;
      });
      _setupRealtime(data.deviceId);
    }
    return data;
  }

  void _setupRealtime(String deviceId) {
    _realtimeService.unsubscribe(_readingsChannel);
    _realtimeService.unsubscribe(_devicesChannel);

    _readingsChannel = _realtimeService.subscribeToReadings(
      deviceId: deviceId,
      onNewReading: (newRecord) {
        if (!mounted || _currentData == null) return;
        final newPpm = newRecord['gas_level_ppm'] as int? ?? 0;
        final trendList = List<double>.from(_currentData!.trendValues)..add(newPpm.toDouble());
        if (trendList.length > 20) {
          trendList.removeAt(0);
        }

        SafetyLevel safety;
        if (newPpm >= _currentData!.dangerThreshold) {
          safety = SafetyLevel.danger;
        } else if (newPpm >= _currentData!.warningThreshold) {
          safety = SafetyLevel.warning;
        } else {
          safety = SafetyLevel.safe;
        }

        setState(() {
          _currentData = MonitoringData(
            gasLevelPpm: newPpm,
            warningThreshold: _currentData!.warningThreshold,
            dangerThreshold: _currentData!.dangerThreshold,
            gasStatus: safety,
            valveState: _currentData!.valveState,
            battery: newRecord['battery_percentage'] as int? ?? _currentData!.battery,
            gsmSignalCsq: newRecord['gsm_signal_csq'] as int? ?? _currentData!.gsmSignalCsq,
            systemOnline: _currentData!.systemOnline,
            powerSource: _currentData!.powerSource,
            trendValues: trendList,
            latestReadingAt: 'Just now',
            deviceId: _currentData!.deviceId,
          );
        });
      },
    );

    _devicesChannel = _realtimeService.subscribeToDevices(
      onDeviceUpdate: (updatedRecord) {
        if (!mounted || _currentData == null) return;
        final updatedId = updatedRecord['serial_number'] as String? ?? updatedRecord['id'] as String?;
        if (updatedId != _currentData!.deviceId && updatedRecord['id'] != _currentData!.deviceId) return;

        final gasStatusStr = (updatedRecord['gas_status'] as String?)?.toUpperCase() ?? 'SAFE';
        final valveStatusStr = (updatedRecord['valve_status'] as String?)?.toUpperCase() ?? 'OPEN';
        final powerSourceStr = (updatedRecord['power_source'] as String?)?.toUpperCase() ?? 'AC';
        final deviceStatusStr = (updatedRecord['device_status'] as String?)?.toUpperCase() ?? 'OFFLINE';

        SafetyLevel safety;
        if (gasStatusStr == 'DANGER') {
          safety = SafetyLevel.danger;
        } else if (gasStatusStr == 'WARNING') {
          safety = SafetyLevel.warning;
        } else {
          safety = SafetyLevel.safe;
        }

        final ValveState valve = valveStatusStr == 'CLOSED' ? ValveState.closed : ValveState.open;

        setState(() {
          _currentData = MonitoringData(
            gasLevelPpm: _currentData!.gasLevelPpm,
            warningThreshold: updatedRecord['warning_threshold_ppm'] as int? ?? _currentData!.warningThreshold,
            dangerThreshold: updatedRecord['danger_threshold_ppm'] as int? ?? _currentData!.dangerThreshold,
            gasStatus: safety,
            valveState: valve,
            battery: updatedRecord['battery_percentage'] as int? ?? _currentData!.battery,
            gsmSignalCsq: updatedRecord['gsm_signal'] as int? ?? _currentData!.gsmSignalCsq,
            systemOnline: deviceStatusStr == 'ONLINE',
            powerSource: powerSourceStr == 'BATTERY' ? PowerSource.battery : PowerSource.ac,
            trendValues: _currentData!.trendValues,
            latestReadingAt: _currentData!.latestReadingAt,
            deviceId: _currentData!.deviceId,
          );
        });
      },
    );
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  void dispose() {
    _realtimeService.unsubscribe(_readingsChannel);
    _realtimeService.unsubscribe(_devicesChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<MonitoringData?>(
          future: _monitoringFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 56, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load monitoring data',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.error}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: secondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = _currentData ?? snap.data;
            if (data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices_other_rounded,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect a device to start live gas monitoring.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: secondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live monitoring',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: textColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  if (_devices.length > 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDeviceId,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
                          dropdownColor: theme.colorScheme.surface,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _devices.map((device) {
                            return DropdownMenuItem<String>(
                              value: device.id,
                              child: Text(device.location.isNotEmpty ? '${device.location} (${device.serialNumber})' : device.serialNumber),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null && newId != _selectedDeviceId) {
                              setState(() {
                                _selectedDeviceId = newId;
                                _currentData = null;
                                _loadData();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Current gas level',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryColor,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            StatusChip(
                              label: _gasStatusLabel(data.gasStatus),
                              tone: _safetyTone(data.gasStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: GasLevelRing(
                            value: data.gasLevelPpm,
                            warningThreshold: data.warningThreshold,
                            dangerThreshold: data.dangerThreshold,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${data.gasLevelPpm}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Last updated: ${data.latestReadingAt}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Safe operating range remains below ${data.warningThreshold}. The device is monitoring for the agreed warning and danger thresholds.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ThresholdPill(
                              label: 'Warn',
                              value: '${data.warningThreshold}',
                            ),
                            _ThresholdPill(
                              label: 'Danger',
                              value: '${data.dangerThreshold}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Recent trend',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            StatusChip(
                              label: 'Current ${data.gasLevelPpm}',
                              tone: _safetyTone(data.gasStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (data.hasReadings)
                          MiniLineChart(values: data.trendValues)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No readings available yet.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Warning: ${data.warningThreshold}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Danger: ${data.dangerThreshold}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Live system health',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _StatusRow(
                          label: 'Device ID',
                          value: data.deviceId,
                        ),
                        _StatusRow(
                          label: 'Valve state',
                          value: _valveLabel(data.valveState),
                        ),
                        _StatusRow(
                            label: 'Battery', value: data.battery != null ? '${data.battery}%' : 'Not measured'),
                        _StatusRow(
                          label: 'GSM quality',
                          value: _gsmQualityLabel(data.gsmSignalCsq),
                        ),
                        _StatusRow(
                          label: 'Power source',
                          value: data.powerSource != null ? _powerSourceLabel(data.powerSource!) : 'Not measured',
                        ),
                        _StatusRow(
                          label: 'System status',
                          value: data.systemOnline ? 'ONLINE' : 'OFFLINE',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DeviceRepository _deviceRepo = DeviceRepository();
  final RealtimeService _realtimeService = RealtimeService();

  late Future<List<AlertItem>> _alertsFuture;
  List<AlertItem>? _currentAlerts;
  RealtimeChannel? _alertsChannel;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    _alertsFuture = _deviceRepo.getAlerts().then((alerts) {
      if (mounted) {
        setState(() {
          _currentAlerts = List<AlertItem>.from(alerts);
        });
        _setupRealtime();
      }
      return alerts;
    });
  }

  void _setupRealtime() {
    _realtimeService.unsubscribe(_alertsChannel);
    _alertsChannel = _realtimeService.subscribeToAlerts(
      onNewAlert: (newRecord) {
        if (!mounted || _currentAlerts == null) return;
        final severityStr = (newRecord['severity'] as String?)?.toUpperCase() ?? 'INFO';
        AlertSeverity severity;
        switch (severityStr) {
          case 'WARNING':
            severity = AlertSeverity.warning;
            break;
          case 'DANGER':
            severity = AlertSeverity.danger;
            break;
          case 'CRITICAL':
            severity = AlertSeverity.critical;
            break;
          case 'INFO':
          default:
            severity = AlertSeverity.info;
            break;
        }

        final alertType = newRecord['alert_type'] as String? ?? 'ALERT';
        final title = alertType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');

        final message = newRecord['message'] as String? ?? '';
        final isAck = newRecord['is_acknowledged'] as bool? ?? false;
        final action = isAck ? 'Acknowledged' : 'Active';

        final newAlert = AlertItem(
          title: title,
          message: message,
          severity: severity,
          timestamp: 'Just now',
          gasLevel: newRecord['gas_level_ppm'] as int? ?? 0,
          action: action,
        );

        setState(() {
          _currentAlerts!.insert(0, newAlert);
        });
      },
    );
  }

  void _refresh() {
    setState(() {
      _loadAlerts();
    });
  }

  @override
  void dispose() {
    _realtimeService.unsubscribe(_alertsChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alert history',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<AlertItem>>(
                  future: _alertsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off_rounded,
                                  size: 56, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Could not load alerts',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: textColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snap.error}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: secondaryColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final alerts = _currentAlerts ?? snap.data ?? [];
                    if (alerts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_rounded,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No alerts yet',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: textColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your system is operating normally without active alerts.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: secondaryColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        final tone = _alertTone(alert.severity);
                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: _alertColor(alert.severity),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      alert.message,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: secondaryColor,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        StatusChip(
                                          label: alert.timestamp,
                                          tone: tone,
                                        ),
                                        const Spacer(),
                                        if (alert.gasLevel > 0)
                                          Text(
                                            '${alert.gasLevel} ppm',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Action: ${alert.action}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.accentSoft,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final DeviceRepository _deviceRepo = DeviceRepository();
  final RealtimeService _realtimeService = RealtimeService();

  late Future<List<DeviceRecord>> _devicesFuture;
  List<DeviceRecord>? _currentDevices;
  RealtimeChannel? _devicesChannel;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() {
    _devicesFuture = _deviceRepo.getDevices().then((devices) {
      if (mounted) {
        setState(() {
          _currentDevices = List<DeviceRecord>.from(devices);
        });
        _setupRealtime();
      }
      return devices;
    });
  }

  void _setupRealtime() {
    _realtimeService.unsubscribe(_devicesChannel);
    _devicesChannel = _realtimeService.subscribeToDevices(
      onDeviceUpdate: (updatedRecord) {
        if (!mounted || _currentDevices == null) return;
        _deviceRepo.getDevices().then((updatedList) {
          if (mounted) {
            setState(() {
              _currentDevices = updatedList;
            });
          }
        });
      },
    );
  }

  void _refresh() {
    setState(() {
      _loadDevices();
    });
  }

  @override
  void dispose() {
    _realtimeService.unsubscribe(_devicesChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<DeviceRecord>>(
          future: _devicesFuture,
          builder: (context, snap) {
            // ── Loading ──────────────────────────────────────────────────
            if (snap.connectionState == ConnectionState.waiting && _currentDevices == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // ── Error ────────────────────────────────────────────────────
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 56, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load devices',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.error}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: secondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final devices = _currentDevices ?? snap.data ?? [];

            // ── Empty ────────────────────────────────────────────────────
            if (devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.devices_other_rounded,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No devices found.',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: textColor)),
                    const SizedBox(height: 8),
                    Text(
                      'Register a device to your organization to see it here.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: secondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // ── Devices found ────────────────────────────────────────────
            final device = devices.first;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Connected device',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: textColor,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.memory_rounded,
                                color: AppTheme.accentSoft,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.serialNumber,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: textColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    device.location,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: secondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: device.status == DeviceStatus.online
                                  ? 'Online'
                                  : 'Offline',
                              tone: device.status == DeviceStatus.online
                                  ? StatusTone.positive
                                  : StatusTone.critical,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.signal_cellular_alt_rounded,
                                color: AppTheme.accentSoft,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Connectivity',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _gsmQualityLabel(device.gsmSignalCsq),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _InfoSection(
                          title: 'Device identity',
                          items: [
                            _InfoRow(label: 'Serial', value: device.serialNumber),
                            _InfoRow(label: 'Name', value: device.location),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: 'Connectivity',
                          items: [
                            _InfoRow(
                              label: 'GSM quality',
                              value: _gsmQualityLabel(device.gsmSignalCsq),
                            ),
                            _InfoRow(
                              label: 'Power',
                              value: device.powerSource != null ? _powerSourceLabel(device.powerSource!) : 'Not measured',
                            ),
                            _InfoRow(
                              label: 'Last communication',
                              value: device.lastCommunication,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: 'Safety',
                          items: [
                            _InfoRow(
                                label: 'Gas status', value: device.gasStatus),
                            _InfoRow(
                              label: 'Valve',
                              value: _valveLabel(device.valveState),
                            ),
                            _InfoRow(
                              label: 'Battery',
                              value: device.battery != null ? '${device.battery}%' : 'Not measured',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final authService = AuthService();
    bool isLoading = false;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureConfirmPassword = !obscureConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final password = passwordController.text;
                          final confirm = confirmPasswordController.text;
                          if (password.isEmpty || confirm.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill out both password fields.')),
                            );
                            return;
                          }
                          if (password.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters.')),
                            );
                            return;
                          }
                          if (password != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match.')),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            await authService.updatePassword(password);
                            if (!dialogCtx.mounted) return;
                            Navigator.of(dialogCtx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully.')),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AuthService.formatAuthError(e))),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmController = TextEditingController();
    bool isLoading = false;
    bool confirmed = false;
    const expectedText = 'DELETE';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(ctx).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.danger, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This action is permanent and cannot be undone.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text('• Your personal account information will be permanently removed.', style: TextStyle(fontSize: 13, height: 1.5)),
                          Text('• Your membership in shared SENZHUB organizations will be removed.', style: TextStyle(fontSize: 13, height: 1.5)),
                          Text('• Shared devices and organization data are preserved if other members exist.', style: TextStyle(fontSize: 13, height: 1.5)),
                          Text('• If you are the sole member of an organization with no devices, that organization will be deleted.', style: TextStyle(fontSize: 13, height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Type DELETE to confirm',
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      enabled: !isLoading,
                      autofocus: true,
                      onChanged: (v) => setDialogState(
                        () => confirmed = v.trim() == expectedText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'DELETE',
                        errorText: confirmController.text.isNotEmpty && !confirmed
                            ? 'Type DELETE exactly'
                            : null,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.danger, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.danger.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: confirmed && !isLoading ? AppTheme.danger : null,
                  ),
                  onPressed: confirmed && !isLoading
                      ? () async {
                          setDialogState(() => isLoading = true);
                          try {
                            await AuthService().deleteAccount();
                            if (!dialogCtx.mounted) return;
                            Navigator.of(dialogCtx).pop();
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!ctx.mounted) return;
                            final msg = e.toString().contains('network') ||
                                    e.toString().contains('SocketException')
                                ? 'Network error. Please check your connection and try again.'
                                : 'Account deletion failed. Please try again or contact support.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                          }
                        }
                      : null,
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete my account'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() => confirmController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeChoice, _) {
        return ValueListenableBuilder<AppAppearanceMode>(
          valueListenable: AppTheme.appearanceNotifier,
          builder: (context, appearanceMode, _) {
            final theme = Theme.of(context);
            final textColor = theme.colorScheme.onSurface;
            final secondaryColor = theme.colorScheme.onSurfaceVariant;
            final userEmail = AuthService().currentUser?.email ?? 'Configured';

            return Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: textColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: secondaryColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SettingsRow(title: 'Account', value: userEmail),
                            Divider(color: theme.dividerColor, height: 1),
                            _SettingsRow(
                              title: 'Change Password',
                              value: 'Update',
                              onTap: () => _showChangePasswordDialog(context),
                            ),
                            Divider(color: theme.dividerColor, height: 1),
                            _SettingsRow(title: 'Security', value: 'Protected'),
                            Divider(color: theme.dividerColor, height: 1),
                            _SettingsRow(
                              title: 'Notifications',
                              value: 'Enabled',
                            ),
                            Divider(color: theme.dividerColor, height: 1),
                          FutureBuilder<SystemSnapshot?>(
                            future: DeviceRepository().getDashboardSnapshot(),
                            builder: (context, snapshot) {
                              final systemOnline = snapshot.data?.systemOnline ?? false;
                              final warn = snapshot.data?.warningThreshold ?? 3200;
                              final dang = snapshot.data?.dangerThreshold ?? 3700;
                              final deviceId = snapshot.data?.deviceId ?? 'No Device';
                              return Column(
                                children: [
                                  _SettingsRow(title: 'Device', value: deviceId),
                                  Divider(color: theme.dividerColor, height: 1),
                                  _SettingsRow(
                                    title: 'Safety Thresholds',
                                    value: '$warn / $dang',
                                  ),
                                  Divider(color: theme.dividerColor, height: 1),
                                  _SettingsRow(
                                    title: 'Appearance / Theme',
                                    value: themeChoice.label,
                                    onTap: () => Navigator.of(context).pushNamed('/theme-settings'),
                                  ),
                                  Divider(color: theme.dividerColor, height: 1),
                                  _SettingsRow(
                                    title: 'Appearance Mode',
                                    value: appearanceMode.label,
                                    onTap: () => Navigator.of(context).pushNamed('/theme-settings'),
                                  ),
                                  Divider(color: theme.dividerColor, height: 1),
                                  _SettingsRow(title: 'System', value: systemOnline ? snapshot.data?.systemOnline == true ? 'System Healthy' : 'Attention Required' : 'Offline/Error'),
                                  Divider(color: theme.dividerColor, height: 1),
                                  _SettingsRow(
                                    title: 'Sustainability / SDG Goals',
                                    value: 'View',
                                    onTap: () => Navigator.of(context).pushNamed('/sdg-goals'),
                                  ),
                                  Divider(color: theme.dividerColor, height: 1),
                                  _SettingsRow(
                                    title: 'About',
                                    value: 'SENZHUB',
                                    onTap: () => Navigator.of(context).pushNamed('/about'),
                                  ),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thresholds',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<SystemSnapshot?>(
                            future: DeviceRepository().getDashboardSnapshot(),
                            builder: (context, snapshot) {
                              final warn = snapshot.data?.warningThreshold ?? 3200;
                              final dang = snapshot.data?.dangerThreshold ?? 3700;
                              return Column(
                                children: [
                                  _RangeRow(label: 'Warning', value: '$warn'),
                                  _RangeRow(label: 'Danger', value: '$dang'),
                                ],
                              );
                            }
                          ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // ── Account Danger Zone ─────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          color: AppTheme.danger.withValues(alpha: 0.04),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: AppTheme.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Account',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppTheme.danger,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showDeleteAccountDialog(context),
                                icon: const Icon(
                                  Icons.delete_forever_rounded,
                                  size: 18,
                                ),
                                label: const Text('Delete Account'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side: const BorderSide(
                                    color: AppTheme.danger,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ── Log Out ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await AuthService().signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Log out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, selectedTheme, _) {
        return ValueListenableBuilder<AppAppearanceMode>(
          valueListenable: AppTheme.appearanceNotifier,
          builder: (context, selectedAppearance, _) {
            final theme = Theme.of(context);
            final textColor = theme.colorScheme.onSurface;
            final secondaryColor = theme.colorScheme.onSurfaceVariant;
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text('Theme / Appearance'),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 18),
                    children: [
                      Text(
                        'Appearance',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Theme colors update the interface branding while preserving the safety meaning of the app.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Theme',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: secondaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...AppTheme.themeChoices.map((choice) {
                        final palette = AppTheme.paletteFor(choice);
                        final selected = choice == selectedTheme;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            onTap: () async {
                              await AppTheme.persistTheme(choice);
                              if (mounted) setState(() {});
                            },
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: palette.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        choice.label,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: textColor,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selected ? 'Selected' : 'Tap to apply',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: secondaryColor,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: palette.accent,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 22),
                      Text(
                        'Appearance Mode',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: secondaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...AppTheme.appearanceChoices.map((mode) {
                        final selected = mode == selectedAppearance;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            onTap: () async {
                              await AppTheme.persistAppearanceMode(mode);
                              if (mounted) setState(() {});
                            },
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    mode.label,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.accent,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SdgGoalsScreen extends StatelessWidget {
  const SdgGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final goals = MockDataService.sdgGoals;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sustainable Development Goals'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore the 17 Sustainable Development Goals and learn what each goal aims to achieve, including its official targets.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SENZHUB and the SDGs',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Only where there is a genuine connection does the app mention its relationship to a goal; the remaining goals are shown for awareness and education.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: goals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final assetPath = 'assets/sdg/${goal.icon}.png';
                    return GlassCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SdgGoalDetailScreen(goal: goal),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.number,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  goal.summary,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: secondaryColor,
                                    height: 1.45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: secondaryColor,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source: United Nations Sustainable Development Goals communications materials',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchUrl(
                        'https://www.un.org/sustainabledevelopment',
                      ),
                      child: Text(
                        'https://www.un.org/sustainabledevelopment',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The content of this publication has not been approved by the United Nations and does not reflect the views of the United Nations or its officials or Member States.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) {
    if (url.isEmpty) return;
  }
}

class SdgGoalDetailScreen extends StatelessWidget {
  const SdgGoalDetailScreen({super.key, required this.goal});

  final SdgGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final assetPath = 'assets/sdg/${goal.icon}.png';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(goal.number),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      goal.number,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      goal.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      goal.purpose,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Official Targets',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...goal.targets.map(
                (target) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.number,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        target.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryColor,
                          height: 1.55,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (goal.senzhubRelation != null &&
                  goal.senzhubRelation!.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'SENZHUB relevance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    goal.senzhubRelation!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryColor,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final DeviceRepository _deviceRepo = DeviceRepository();
  late Future<List<DeviceRecord>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _devicesFuture = _deviceRepo.getDevices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _devicesFuture = _deviceRepo.getDevices();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<DeviceRecord>>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final devices = snapshot.data ?? [];
            final List<DiagnosticItem> diagnostics = [];

            if (devices.isEmpty) {
              diagnostics.add(const DiagnosticItem(
                name: 'Network Connection',
                status: 'Error',
                lastChecked: 'Just now',
                message: 'No devices found for this account.',
              ));
            } else {
              final device = devices.first;
              
              // Sensor Health
              diagnostics.add(DiagnosticItem(
                name: 'MQ-6 Sensor',
                status: device.gasStatus == 'SAFE' ? 'Optimal' : (device.gasStatus == 'WARNING' ? 'Elevated' : 'Danger'),
                lastChecked: device.lastCommunication,
                message: 'Sensor is active and reporting data.',
              ));
              
              // Solenoid Valve
              diagnostics.add(DiagnosticItem(
                name: 'Solenoid Valve',
                status: device.valveState == ValveState.open ? 'Open' : 'Closed',
                lastChecked: device.lastCommunication,
                message: 'Valve mechanism is operating nominally.',
              ));

              // Power Supply
              diagnostics.add(DiagnosticItem(
                name: 'Power Supply',
                status: device.powerSource != null ? (device.powerSource == PowerSource.ac ? 'AC Mains' : 'Battery') : 'Unknown',
                lastChecked: device.lastCommunication,
                message: device.battery != null ? 'Battery at ${device.battery}%' : 'Power status is not currently measured by hardware.',
              ));
              
              // GSM Network
              diagnostics.add(DiagnosticItem(
                name: 'Cellular Network',
                status: device.gsmSignalCsq > 15 ? 'Good' : (device.gsmSignalCsq > 9 ? 'Fair' : 'Poor'),
                lastChecked: device.lastCommunication,
                message: 'Signal strength: ${device.gsmSignalCsq}/31. ${device.gsmSignalQuality}',
              ));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 420 ? 1 : 2;
                final aspectRatio = constraints.maxWidth < 420 ? 1.45 : 1.15;
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    itemCount: diagnostics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final item = diagnostics[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: secondaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.status,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: textColor,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.lastChecked,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                item.message,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryColor,
                                  fontSize: 11,
                                  height: 1.45,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('About'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SENZHUB',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A household LPG safety experience designed to keep safety information simple, understandable, and actionable for everyday users.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(color: theme.dividerColor),
                    const SizedBox(height: 18),
                    _AboutRow(label: 'Focus', value: 'Home LPG safety'),
                    _AboutRow(label: 'Monitoring', value: 'Local mock system'),
                    _AboutRow(
                      label: 'Safety model',
                      value: 'User-friendly guidance',
                    ),
                    _AboutRow(label: 'Hardware', value: 'ESP32 safety layer'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ValveControlWidget extends StatefulWidget {
  const ValveControlWidget({super.key, required this.snapshot});
  final SystemSnapshot snapshot;

  

  @override
  State<ValveControlWidget> createState() => _ValveControlWidgetState();
}

class _ValveControlWidgetState extends State<ValveControlWidget> {
  final DeviceRepository _deviceRepository = DeviceRepository();
  final RealtimeService _realtimeService = RealtimeService();

  List<DeviceRecord> _devices = [];
  DeviceRecord? _selectedDevice;
  bool _isLoading = true;
  String? _errorMessage;

  // Command Execution State
  bool _isExecutingCommand = false;
  String _commandStatusMessage = '';
  String? _activeCommandId;
  Timer? _commandTimer;

  RealtimeChannel? _commandSubscription;
  RealtimeChannel? _deviceSubscription;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _setPinFormKey = GlobalKey<FormState>();

  bool _hasSecurePinConfigured = false;
  bool _isCheckingPin = false;
  bool _pinStatusError = false;
  int _pinCheckGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkPinConfigured();
  }

  Future<void> _checkPinConfigured() async {
    final int currentGen = ++_pinCheckGeneration;
    setState(() {
      _isCheckingPin = true;
      _pinStatusError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    // Remove old insecure PIN if it exists
    if (prefs.containsKey('valve_pin')) {
      await prefs.remove('valve_pin');
    }
    
    try {
      final hasPin = await _deviceRepository.getValvePinStatus();
      if (!mounted || _pinCheckGeneration != currentGen) return;
      
      setState(() {
        _hasSecurePinConfigured = hasPin;
        _isCheckingPin = false;
        _pinStatusError = false;
      });
      await prefs.setBool('has_secure_pin_configured', hasPin);
    } catch (e) {
      if (!mounted || _pinCheckGeneration != currentGen) return;
      setState(() {
        _isCheckingPin = false;
        _pinStatusError = true;
      });
    }
  }

  Future<void> _markPinConfigured() async {
    _pinCheckGeneration++; // Invalidate any pending check
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_secure_pin_configured', true);
    setState(() {
      _hasSecurePinConfigured = true;
      _isCheckingPin = false;
      _pinStatusError = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    if (routeArg is String && routeArg.isNotEmpty && _selectedDevice?.id != routeArg) {
      _selectDeviceById(routeArg);
    }
  }

  @override
  void dispose() {
    _commandTimer?.cancel();
    _reasonController.dispose();
    _pinController.dispose();
    _realtimeService.unsubscribe(_commandSubscription);
    _realtimeService.unsubscribe(_deviceSubscription);
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final devices = await _deviceRepository.getDevices();
      if (!mounted) return;

      if (devices.isEmpty) {
        setState(() {
          _devices = [];
          _selectedDevice = null;
          _isLoading = false;
          _errorMessage = 'No registered LPG devices found for your organization.';
        });
        return;
      }

      String targetId = widget.snapshot.deviceId;
      final routeArg = ModalRoute.of(context)?.settings.arguments;
      if (targetId.isEmpty && routeArg is String) {
        targetId = routeArg;
      }

      DeviceRecord? targetDevice;
      if (targetId.isNotEmpty) {
        targetDevice = devices.firstWhere(
          (d) => d.id == targetId || (d.id.length > 8 && targetId.contains(d.id)),
          orElse: () => devices.first,
        );
      } else {
        targetDevice = devices.first;
      }

      setState(() {
        _devices = devices;
        _selectedDevice = targetDevice;
        _isLoading = false;
      });

      _subscribeToDeviceUpdates();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load device status: ${e.toString()}';
      });
    }
  }

  void _selectDeviceById(String id) {
    if (_devices.isEmpty) return;
    final match = _devices.firstWhere(
      (d) => d.id == id,
      orElse: () => _devices.first,
    );
    if (match.id != _selectedDevice?.id) {
      setState(() {
        _selectedDevice = match;
      });
      _subscribeToDeviceUpdates();
    }
  }

  void _subscribeToDeviceUpdates() {
    _realtimeService.unsubscribe(_deviceSubscription);
    

    _deviceSubscription = _realtimeService.subscribeToDevices(
      onDeviceUpdate: (updatedRow) {
        if (!mounted || _selectedDevice == null) return;
        final updatedId = updatedRow['id'] as String?;
        if (updatedId == widget.snapshot.deviceId) {
          final newValveStr = (updatedRow['valve_status'] as String?)?.toUpperCase() ?? 'CLOSED';
          final newDeviceStatusStr = (updatedRow['device_status'] as String?)?.toUpperCase() ?? 'OFFLINE';

          final ValveState newValveState = newValveStr == 'OPEN'
              ? ValveState.open
              : newValveStr == 'SAFETY_LOCK'
                  ? ValveState.safetyLock
                  : ValveState.closed;

          setState(() {
            _selectedDevice = DeviceRecord(
              id: widget.snapshot.deviceId,
              serialNumber: widget.snapshot.deviceId,
              status: newDeviceStatusStr == 'ONLINE' ? DeviceStatus.online : DeviceStatus.offline,
              location: updatedRow['device_name'] as String? ?? widget.snapshot.location,
              lastCommunication: _selectedDevice!.lastCommunication,
              gasStatus: updatedRow['gas_status'] as String? ?? _selectedDevice!.gasStatus,
              valveState: newValveState,
              battery: updatedRow['battery_percentage'] as int? ?? _selectedDevice!.battery,
              gsmSignalCsq: updatedRow['gsm_signal'] as int? ?? _selectedDevice!.gsmSignalCsq,
              gsmSignalQuality: _selectedDevice!.gsmSignalQuality,
              powerSource: _selectedDevice!.powerSource,
            );
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = widget.snapshot.valveState == ValveState.closed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExecutingCommand || _isCheckingPin)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isCheckingPin ? 'Verifying security status...' : _commandStatusMessage, 
                      style: TextStyle(color: AppTheme.accent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Valve Status: ' + (isClosed ? 'CLOSED' : 'OPEN'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            FilledButton.tonal(
              onPressed: (_isExecutingCommand || _isCheckingPin) ? null : () => _promptValveCommandConfirmation(isClosed),
              style: FilledButton.styleFrom(
                backgroundColor: isClosed ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.warning.withValues(alpha: 0.2),
                foregroundColor: isClosed ? AppTheme.accent : AppTheme.warning,
              ),
              child: _isCheckingPin 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isClosed ? 'OPEN' : 'CLOSE'),
            ),
          ],
        ),
      ],
    );
  }
  void _promptValveCommandConfirmation(bool isCurrentlyClosed) {
    if (_isCheckingPin) return;

    if (_pinStatusError) {
      _showSafetyDialog(
        title: 'Security Check Failed',
        message: 'Unable to verify security status. Please check your connection and try again.',
        isError: true,
      );
      return;
    }

    if (!_hasSecurePinConfigured) {
      _promptSetPin();
      return;
    }

    _reasonController.text = 'Manual user request';
    _pinController.clear();
    final isOpening = isCurrentlyClosed;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1E1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(bottomSheetContext).viewInsets.bottom + 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isOpening ? Icons.lock_open_rounded : Icons.lock_rounded,
                      color: isOpening ? AppTheme.accent : AppTheme.warning,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOpening ? 'Confirm Open Valve' : 'Confirm Close Valve',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Target Device: ${widget.snapshot.location} (${widget.snapshot.deviceId})',
                  style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _pinController,
                  style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Enter 4-digit SENZHUB PIN',
                    labelStyle: const TextStyle(color: AppTheme.muted, letterSpacing: 0, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF142C24),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val == null || val.length != 4 || int.tryParse(val) == null) return 'Enter 4 numeric digits';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                      _showForgotPinDialog();
                    },
                    child: Text('Forgot SENZHUB PIN?', style: TextStyle(color: AppTheme.accent)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final reasonStr = _reasonController.text.trim();
                        final pin = _pinController.text;
                        Navigator.of(bottomSheetContext).pop();
                        if (isOpening) {
                          _startOpenValveSequence(reasonStr, pin);
                        } else {
                          _dispatchValveCommand(ValveAction.close, reasonStr, pin: pin);
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isOpening ? AppTheme.accent : AppTheme.warning,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      isOpening ? 'Next: Request OTP' : 'Submit Close Command',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1E1A),
        title: const Text('Forgot SENZHUB PIN?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'To securely reset your PIN, we need to verify your email identity.\n\nWe will send a secure recovery link to your registered email address. Please click the link to return to the app and set a new PIN.',
          style: TextStyle(color: AppTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final email = AuthService().currentUser?.email;
                if (email == null) throw Exception('No authenticated email found.');
                await AuthService().resetPasswordForEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recovery link sent to your email.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showSafetyDialog(title: 'Recovery Failed', message: e.toString(), isError: true);
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            child: const Text('Send Recovery Link', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _promptSetPin() {
    _pinController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1E1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(bottomSheetContext).viewInsets.bottom + 28),
          child: Form(
            key: _setPinFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Set New SENZHUB PIN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('Create a 4-digit PIN for secure valve operations.', style: TextStyle(color: AppTheme.muted, height: 1.4, fontSize: 13)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _pinController,
                  style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Enter 4-digit PIN',
                    labelStyle: const TextStyle(color: AppTheme.muted, letterSpacing: 0, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF142C24),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val == null || val.length != 4 || int.tryParse(val) == null) return 'Enter 4 numeric digits';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (_setPinFormKey.currentState?.validate() ?? false) {
                        final pin = _pinController.text;
                        Navigator.of(bottomSheetContext).pop();
                        await _submitNewPin(pin);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Save PIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitNewPin(String pin) async {
    setState(() {
      _isExecutingCommand = true;
      _commandStatusMessage = 'Setting secure PIN...';
    });

    try {
      await _deviceRepository.setValvePin(pin);
      await _markPinConfigured();
      setState(() {
        _isExecutingCommand = false;
      });
      _showSafetyDialog(
        title: 'PIN Configured',
        message: 'Your SENZHUB PIN has been securely set.',
        isError: false,
      );
    } catch (e) {
      setState(() {
        _isExecutingCommand = false;
      });
      if (e.toString().contains('409') || e.toString().contains('already configured')) {
        _showSafetyDialog(title: 'PIN Setup Error', message: 'PIN is already configured.', isError: true);
        await _markPinConfigured();
      } else {
        _showSafetyDialog(title: 'PIN Setup Failed', message: e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _startOpenValveSequence(String reason, String pin) async {
    setState(() {
      _isExecutingCommand = true;
      _commandStatusMessage = 'Verifying PIN & requesting OTP...';
    });

    try {
      await _deviceRepository.requestValveOtp(widget.snapshot.deviceId, ValveAction.open);
      setState(() {
        _isExecutingCommand = false;
      });
      _promptOtpEntry(reason, pin);
    } catch (e) {
      setState(() {
        _isExecutingCommand = false;
      });
      _showSafetyDialog(
        title: 'Verification Failed',
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _promptOtpEntry(String reason, String pin) {
    _otpController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1E1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(bottomSheetContext).viewInsets.bottom + 28),
          child: Form(
            key: _otpFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OTP Required to Open Valve', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('A 6-digit OTP has been sent to your verified device/email. Enter it to confirm opening the valve.', style: TextStyle(color: AppTheme.muted, height: 1.4, fontSize: 13)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _otpController,
                  style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit OTP',
                    labelStyle: const TextStyle(color: AppTheme.muted, letterSpacing: 0, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF142C24),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val == null || val.length != 6 || int.tryParse(val) == null) return 'Enter 6 numeric digits';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_otpFormKey.currentState?.validate() ?? false) {
                        final otp = _otpController.text;
                        Navigator.of(bottomSheetContext).pop();
                        _dispatchValveCommand(ValveAction.open, reason, pin: pin, otp: otp);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Verify & Open Valve', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _dispatchValveCommand(ValveAction action, String reason, {required String pin, String? otp}) async {
    setState(() {
      _isExecutingCommand = true;
      _commandStatusMessage = 'Dispatching secure command...';
    });

    try {
      final res = await _deviceRepository.submitValveCommand(
        widget.snapshot.deviceId,
        action,
        reason: reason,
        pin: pin,
        otp: otp,
      );

      final commandId = res['command_id'] as String?;
      if (commandId == null) throw Exception('Failed to receive valid command reference from server.');

      setState(() {
        _activeCommandId = commandId;
        _commandStatusMessage = 'Command queued (PENDING). Awaiting ESP32 hardware pickup...';
      });

      _commandTimer?.cancel();
      _commandTimer = Timer(const Duration(seconds: 15), () {
        _handleCommandTimeout(action);
      });

      _realtimeService.unsubscribe(_commandSubscription);
      _commandSubscription = _realtimeService.subscribeToCommand(
        commandId: commandId,
        onCommandUpdate: (updatedRow) {
          if (!mounted) return;
          final status = (updatedRow['status'] as String?)?.toUpperCase() ?? 'PENDING';

          if (status == 'SENT') {
            setState(() {
              _commandStatusMessage = 'Command acknowledged by device (SENT). Executing relay...';
            });
          } else if (status == 'EXECUTED') {
            _commandTimer?.cancel();
            _onCommandExecutedSuccess(action);
          } else if (status == 'FAILED') {
            _commandTimer?.cancel();
            final failReason = updatedRow['failure_reason'] as String? ?? 'Device reported hardware execution failure.';
            _onCommandFailed(failReason);
          }
        },
      );
    } catch (e) {
      _commandTimer?.cancel();
      setState(() {
        _isExecutingCommand = false;
        _activeCommandId = null;
      });
      _showSafetyDialog(title: 'Command Dispatch Failed', message: e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _onCommandExecutedSuccess(ValveAction action) async {
    try {
      final actualState = await _deviceRepository.getValveStatus(widget.snapshot.deviceId);
      final expectedState = action == ValveAction.open ? ValveState.open : ValveState.closed;

      setState(() {
        _isExecutingCommand = false;
        _activeCommandId = null;
      });

      if (actualState == expectedState) {
        _showSafetyDialog(
          title: 'Physical Valve Confirmed',
          message: 'The ESP32 hardware confirmed that the valve has been successfully ${action == ValveAction.open ? 'OPENED' : 'CLOSED'}.',
          isError: false,
        );
      } else {
        _showSafetyDialog(
          title: 'Hardware State Warning',
          message: 'Command was acknowledged, but physical sensor state does not match requested state yet.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isExecutingCommand = false;
      });
    }
  }

  void _onCommandFailed(String reason) {
    setState(() {
      _isExecutingCommand = false;
      _activeCommandId = null;
    });
    _showSafetyDialog(title: 'Command Failed', message: 'The ESP32 safety relay rejected the command.\n\nHardware report: $reason', isError: true);
  }

  void _handleCommandTimeout(ValveAction action) {
    setState(() {
      _isExecutingCommand = false;
      _activeCommandId = null;
    });
    _showSafetyDialog(title: 'Command Timeout', message: 'The device did not acknowledge the command within 15 seconds. Ensure the ESP32 is online and connected to WiFi.', isError: true);
  }

  void _showSafetyDialog({required String title, required String message, required bool isError}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1E1A),
        title: Row(
          children: [
            Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: isError ? AppTheme.danger : AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

}

class LpgBookingScreen extends StatelessWidget {
  const LpgBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('LPG Booking'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cylinder status',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Healthy and within expected range',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...MockDataService.bookingHistory.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryColor,
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  item.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mock booking request created. This is not connected to a live provider.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Request delivery',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: fullWidth ? null : null,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.accentSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.muted,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.value, this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdPill extends StatelessWidget {
  const _ThresholdPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});

  final String title;
  final List<_InfoRow> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

SafetyLevel _safetyFromGas(
  int gasLevel,
  int warningThreshold,
  int dangerThreshold,
) {
  if (gasLevel >= dangerThreshold) return SafetyLevel.danger;
  if (gasLevel >= warningThreshold) return SafetyLevel.warning;
  return SafetyLevel.safe;
}

String _safetyLabel(SafetyLevel level) {
  switch (level) {
    case SafetyLevel.safe:
      return 'SAFE';
    case SafetyLevel.warning:
      return 'WARNING';
    case SafetyLevel.danger:
      return 'DANGER';
  }
}

String _safetyMessage(SafetyLevel level) {
  switch (level) {
    case SafetyLevel.safe:
      return 'Gas concentration remains within the safe operating band.';
    case SafetyLevel.warning:
      return 'Monitor closely. Threshold is elevated and should be reviewed.';
    case SafetyLevel.danger:
      return 'Immediate attention required. Safety response is active.';
  }
}

IconData _safetyIcon(SafetyLevel level) {
  switch (level) {
    case SafetyLevel.safe:
      return Icons.check_circle_rounded;
    case SafetyLevel.warning:
      return Icons.warning_amber_rounded;
    case SafetyLevel.danger:
      return Icons.error_rounded;
  }
}

Color _safetyColor(SafetyLevel level) {
  switch (level) {
    case SafetyLevel.safe:
      return AppTheme.accent;
    case SafetyLevel.warning:
      return AppTheme.warning;
    case SafetyLevel.danger:
      return AppTheme.danger;
  }
}

String _gasStatusLabel(SafetyLevel level) {
  switch (level) {
    case SafetyLevel.safe:
      return 'Safe';
    case SafetyLevel.warning:
      return 'Warning';
    case SafetyLevel.danger:
      return 'Danger';
  }
}

StatusTone _safetyTone(SafetyLevel level) {
  switch (level) {
    case SafetyLevel.safe:
      return StatusTone.positive;
    case SafetyLevel.warning:
      return StatusTone.warning;
    case SafetyLevel.danger:
      return StatusTone.critical;
  }
}

String _valveLabel(ValveState state) {
  switch (state) {
    case ValveState.open:
      return 'OPEN';
    case ValveState.closed:
      return 'CLOSED';
    case ValveState.safetyLock:
      return 'SAFETY LOCK';
  }
}

String _powerSourceLabel(PowerSource source) {
  switch (source) {
    case PowerSource.ac:
      return 'AC';
    case PowerSource.battery:
      return 'BATTERY';
  }
}

String _gsmQualityLabel(int csq) {
  if (csq >= 20) return 'Good';
  if (csq >= 12) return 'Fair';
  return 'Weak';
}

StatusTone _alertTone(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.info:
      return StatusTone.info;
    case AlertSeverity.warning:
      return StatusTone.warning;
    case AlertSeverity.danger:
      return StatusTone.critical;
    case AlertSeverity.critical:
      return StatusTone.critical;
  }
}

Color _alertColor(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.info:
      return AppTheme.info;
    case AlertSeverity.warning:
      return AppTheme.warning;
    case AlertSeverity.danger:
      return AppTheme.danger;
    case AlertSeverity.critical:
      return AppTheme.danger;
  }
}

String _severityLabel(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.info:
      return 'INFO';
    case AlertSeverity.warning:
      return 'WARNING';
    case AlertSeverity.danger:
      return 'DANGER';
    case AlertSeverity.critical:
      return 'CRITICAL';
  }
}
