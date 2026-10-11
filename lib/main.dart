import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/tracking_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'fleetops_tracking',
      channelName: 'FleetOps Tracking',
      channelDescription:
          'Notifications for FleetOps location tracking.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
    ),
  );

  runApp(const FleetOpsApp());
}

// ============================================================
// APP
// ============================================================

class FleetOpsApp extends StatelessWidget {
  const FleetOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FleetOps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const FleetOpsSplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class FleetOpsSplashScreen extends StatefulWidget {
  const FleetOpsSplashScreen({super.key});

  @override
  State<FleetOpsSplashScreen> createState() =>
      _FleetOpsSplashScreenState();
}

class _FleetOpsSplashScreenState
    extends State<FleetOpsSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _textAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.25,
        0.8,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    Future.delayed(
      const Duration(milliseconds: 2200),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    const FleetOpsAuthGate(),
            transitionsBuilder:
                (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration:
                const Duration(milliseconds: 500),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1D4ED8),
              Color(0xFF2563EB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.20),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 58,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'FleetOps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart Fleet Tracking',
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: 0.85),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 55),
                FadeTransition(
                  opacity: _textAnimation,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _textAnimation,
                  child: Text(
                    'Initializing...',
                    style: TextStyle(
                      color:
                          Colors.white.withValues(alpha: 0.70),
                      fontSize: 13,
                    ),
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

// ============================================================
// AUTHENTICATION GATE
// ============================================================

class FleetOpsAuthGate extends StatefulWidget {
  const FleetOpsAuthGate({super.key});

  @override
  State<FleetOpsAuthGate> createState() =>
      _FleetOpsAuthGateState();
}

class _FleetOpsAuthGateState
    extends State<FleetOpsAuthGate> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final loggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  const FleetOpsHomePage(),
          transitionsBuilder:
              (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration:
              const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class FleetOpsHomePage extends StatefulWidget {
  const FleetOpsHomePage({super.key});

  @override
  State<FleetOpsHomePage> createState() =>
      _FleetOpsHomePageState();
}

class _FleetOpsHomePageState
    extends State<FleetOpsHomePage> {
  bool isTracking = false;
  bool isDarkMode = false;

  // Prevent multiple stop operations at the same time.
  bool isStoppingTracking = false;

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> _logout() async {
    // Stop tracking before logging out.
    if (isTracking) {
      try {
        debugPrint(
          'FleetOps: stopping tracking during logout...',
        );

        await FlutterForegroundTask.stopService();

        debugPrint(
          'FleetOps: tracking stopped during logout.',
        );
      } catch (e) {
        debugPrint(
          'FleetOps: error stopping tracking during logout: $e',
        );
      }
    }

    await AuthService().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ==========================================================
  // LOCATION TRACKING
  // ==========================================================

  Future<void> toggleTracking() async {
    // Prevent another operation while stopping.
    if (isStoppingTracking) {
      return;
    }

    // --------------------------------------------------------
    // STOP TRACKING
    // --------------------------------------------------------

    if (isTracking) {
      if (!mounted) return;

      // Immediately lock the button.
      setState(() {
        isStoppingTracking = true;
      });

      try {
        debugPrint(
          'FleetOps: stopping tracking service...',
        );

        await FlutterForegroundTask.stopService();

        debugPrint(
          'FleetOps: tracking service stopped successfully.',
        );
      } catch (e) {
        // We don't let an error during shutdown
        // crash the Flutter UI.
        debugPrint(
          'FleetOps: error stopping tracking service: $e',
        );
      }

      if (!mounted) return;

      // Update the UI only after the stop request
      // has finished.
      setState(() {
        isTracking = false;
        isStoppingTracking = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location tracking stopped',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // START TRACKING
    // --------------------------------------------------------

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please turn on your device location service.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required for tracking.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    try {
      // ------------------------------------------------------
      // NOTIFICATION PERMISSION
      // ------------------------------------------------------

      final notificationPermission =
          await FlutterForegroundTask
              .checkNotificationPermission();

      if (notificationPermission !=
          NotificationPermission.granted) {
        await FlutterForegroundTask
            .requestNotificationPermission();
      }

      // ------------------------------------------------------
      // START FOREGROUND TRACKING SERVICE
      // ------------------------------------------------------

      debugPrint(
        'FleetOps: starting tracking service...',
      );

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'FleetOps',
        notificationText:
            'Location tracking is active',
        notificationButtons: const [
          NotificationButton(
            id: 'stop_tracking',
            text: 'STOP TRACKING',
          ),
        ],
        notificationInitialRoute: '/',
        callback: startCallback,
      );

      if (!mounted) return;

      setState(() {
        isTracking = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location tracking started',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint(
        'FleetOps: unable to start tracking: $e',
      );

      if (!mounted) return;

      setState(() {
        isTracking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to start tracking: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // HOME UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF5F7FB);

    final cardColor = isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;

    final primaryText = isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);

    final secondaryText = isDarkMode
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FleetOps',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight:
                                FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                        Text(
                          'Fleet Management',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isDarkMode = !isDarkMode;
                      });
                    },
                    icon: Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_outlined,
                      color: primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    tooltip: 'Logout',
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================================
              // WELCOME TEXT
              // ==================================================

              Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Track your fleet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // LIVE TRACKING CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF1D4ED8),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB)
                          .withValues(alpha: 0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.gps_fixed_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'LIVE TRACKING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration:
                                    BoxDecoration(
                                  color: isTracking
                                      ? const Color(
                                          0xFF4ADE80,
                                        )
                                      : Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTracking
                                    ? 'ACTIVE'
                                    : 'OFFLINE',
                                style:
                                    const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vehicle Location',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isTracking
                                    ? 'Tracking active'
                                    : 'Tracking is off',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // TRACKING BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isStoppingTracking
                            ? null
                            : toggleTracking,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color(0xFF1D4ED8),
                          disabledBackgroundColor:
                              Colors.white70,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            if (isStoppingTracking)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                isTracking
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              isStoppingTracking
                                  ? 'Stopping...'
                                  : isTracking
                                      ? 'Stop Tracking'
                                      : 'Start Tracking',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // MAP PREVIEW
              // ==================================================

              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? const [
                                    Color(0xFF1E293B),
                                    Color(0xFF334155),
                                  ]
                                : const [
                                    Color(0xFFEFF6FF),
                                    Color(0xFFDBEAFE),
                                  ],
                          ),
                        ),
                      ),

                      Positioned(
                        top: 65,
                        left: -30,
                        right: -20,
                        child: Transform.rotate(
                          angle: -0.15,
                          child: Container(
                            height: 3,
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.white,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 135,
                        left: -20,
                        right: -30,
                        child: Transform.rotate(
                          angle: 0.18,
                          child: Container(
                            height: 3,
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.white,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 100,
                        left: 90,
                        child: Transform.rotate(
                          angle: 1.1,
                          child: Container(
                            width: 3,
                            height: 160,
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.white,
                          ),
                        ),
                      ),

                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 18,
                        left: 18,
                        child: Text(
                          'MAP PREVIEW',
                          style: TextStyle(
                            color: secondaryText,
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 15,
                        left: 18,
                        right: 18,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isTracking
                                  ? 'Current location'
                                  : 'Waiting for GPS',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FOOTER
              // ==================================================

              Center(
                child: Text(
                  'FleetOps • Fleet Tracking System',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
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