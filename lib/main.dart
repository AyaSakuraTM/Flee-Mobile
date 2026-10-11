
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/tracking_service.dart';

void main() 
{WidgetsFlutterBinding.ensureInitialized();

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
        ),
      ),
      home: const FleetOpsSplashScreen(),
    );
  }
}

// ------------------------------------------------------------
// SPLASH SCREEN
// ------------------------------------------------------------

class FleetOpsSplashScreen extends StatefulWidget {
  const FleetOpsSplashScreen({super.key});

  @override
  State<FleetOpsSplashScreen> createState() =>
      _FleetOpsSplashScreenState();
}

class _FleetOpsSplashScreenState
    extends State<FleetOpsSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const FleetOpsAuthGate(),
        ),
      );
    });
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
        width: double.infinity,
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
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeIn,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    size: 56,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FleetOps',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Fleet Tracking',
                  style: TextStyle(
                    fontSize: 15,
                    letterSpacing: 1,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
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

// ------------------------------------------------------------
// AUTHENTICATION GATE
// ------------------------------------------------------------

class FleetOpsAuthGate extends StatefulWidget {
  const FleetOpsAuthGate({super.key});

  @override
  State<FleetOpsAuthGate> createState() =>
      _FleetOpsAuthGateState();
}

class _FleetOpsAuthGateState extends State<FleetOpsAuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final loggedIn = await AuthService().isLoggedIn();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => loggedIn
            ? const FleetOpsHomePage()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ------------------------------------------------------------
// HOME PAGE
// ------------------------------------------------------------

class FleetOpsHomePage extends StatefulWidget {
  const FleetOpsHomePage({super.key});

  @override
  State<FleetOpsHomePage> createState() => _FleetOpsHomePageState();
}

class _FleetOpsHomePageState extends State<FleetOpsHomePage>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  static const String _selectedVehicleKey =
      'fleetops_selected_vehicle_id';

  bool isDarkMode = false;
  bool isTracking = false;
  bool isStartingTracking = false;
  bool isStoppingTracking = false;
  bool isLoadingDispatches = true;

  bool _checkingTrackingStatus = false;
  Timer? _trackingStatusTimer;

  String? dispatchError;
  String? loginEmail;
  List<dynamic> dispatches = [];
  int? expandedDispatchId;
  int? trackingDispatchId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadHomeData();

    // Keep the home screen synchronized with the actual
    // foreground service, including notification stop actions.
    _trackingStatusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _syncTrackingStatus(),
    );

    _syncTrackingStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTrackingStatus();
    }
  }

  @override
  void dispose() {
    _trackingStatusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _syncTrackingStatus() async {
    if (_checkingTrackingStatus || !mounted) return;

    _checkingTrackingStatus = true;

    try {
      final running =
          await FlutterForegroundTask.isRunningService;

      if (!mounted) return;

      if (!running) {
        // Clear only the selected vehicle. Do not clear the
        // login token or sign the user out.
        await _storage.delete(key: _selectedVehicleKey);
      }

      if (!mounted) return;

      setState(() {
        isTracking = running;

        if (!running) {
          trackingDispatchId = null;
          isStartingTracking = false;
          isStoppingTracking = false;
        }
      });
    } catch (e) {
      debugPrint('FleetOps tracking status sync failed: $e');
    } finally {
      _checkingTrackingStatus = false;
    }
  }

  Future<void> _loadHomeData() async {
    loginEmail = await _authService.getLoginEmail();

    if (mounted) {
      setState(() {});
    }

    await _loadDispatches();
  }

  Future<void> _loadDispatches() async {
    if (mounted) {
      setState(() {
        isLoadingDispatches = true;
        dispatchError = null;
      });
    }

    try {
      final result = await _apiService.getMyActiveDispatches();

      if (!mounted) return;

      setState(() {
        dispatches = result;
        isLoadingDispatches = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        dispatchError = _readableError(e);
        dispatches = [];
        isLoadingDispatches = false;
      });
    }
  }

  String _readableError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  String _value(dynamic item, String key) {
    if (item is! Map) return '';
    return item[key]?.toString() ?? '';
  }

  int? _intValue(dynamic item, String key) {
    final value = _value(item, key);
    return int.tryParse(value);
  }

  String _dispatchNumber(dynamic item) {
    final number = _value(item, 'dispatch_no');

    if (number.isNotEmpty && number != 'null') {
      return number;
    }

    final id = _value(item, 'id');
    return id.isNotEmpty ? 'Dispatch #$id' : 'Dispatch';
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------

  Future<void> _logout() async {
    if (isTracking) {
      try {
        await FlutterForegroundTask.stopService();
        await _storage.delete(key: _selectedVehicleKey);
      } catch (e) {
        debugPrint('FleetOps: could not stop tracking: $e');
      }
    }

    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ----------------------------------------------------------
  // TRACKING
  // ----------------------------------------------------------

  Future<void> _toggleTracking(Map dispatch) async {
    if (isStartingTracking || isStoppingTracking) return;

    final dispatchId = int.tryParse(
      dispatch['id']?.toString() ?? '',
    );

    final vehicleId = int.tryParse(
      dispatch['vehicle_id']?.toString() ?? '',
    );

    if (dispatchId == null ||
        vehicleId == null ||
        vehicleId <= 0) {
      _showMessage(
        'This dispatch has no valid vehicle assigned.',
      );
      return;
    }

    if (isTracking) {
      if (trackingDispatchId != dispatchId) {
        _showMessage(
          'Stop the current tracking session before selecting another dispatch.',
        );
        return;
      }

      setState(() => isStoppingTracking = true);

      try {
        await FlutterForegroundTask.stopService();
        await _storage.delete(key: _selectedVehicleKey);

        if (!mounted) return;

        setState(() {
          isTracking = false;
          isStoppingTracking = false;
          trackingDispatchId = null;
        });

        _showMessage('Location tracking stopped.');
      } catch (e) {
        if (!mounted) return;

        setState(() => isStoppingTracking = false);
        _showMessage('Could not stop tracking: $e');
      }

      return;
    }

    setState(() => isStartingTracking = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on your device location service.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is required for tracking.',
        );
        return;
      }

      final notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();

      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // Save the selected vehicle ID for the background task.
      // tracking_service.dart must read this same key.
      await _storage.write(
        key: _selectedVehicleKey,
        value: vehicleId.toString(),
      );

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'FleetOps',
        notificationText: 'Location tracking is active',
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
        trackingDispatchId = dispatchId;
      });

      _showMessage(
        'Tracking started for ${_dispatchNumber(dispatch)}.',
      );
    } catch (e) {
      await _storage.delete(key: _selectedVehicleKey);

      if (!mounted) return;

      setState(() {
        isTracking = false;
        trackingDispatchId = null;
      });

      _showMessage('Unable to start tracking: $e');
    } finally {
      if (mounted) {
        setState(() => isStartingTracking = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final background = isDarkMode
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
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDispatches,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(15),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FleetOps',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
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
                    tooltip: 'Refresh dispatches',
                    onPressed:
                        isLoadingDispatches ? null : _loadDispatches,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: primaryText,
                    ),
                  ),
                  IconButton(
                    tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
                    onPressed: () {
                      setState(() => isDarkMode = !isDarkMode);
                    },
                    icon: Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_outlined,
                      color: primaryText,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your dispatches',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an active dispatch to view its details and start tracking.',
                style: TextStyle(
                  height: 1.4,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 22),

              // Tracking status banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTracking
                        ? const Color(0xFF22C55E)
                            .withValues(alpha: 0.6)
                        : (isDarkMode
                            ? Colors.white10
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isTracking
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isTracking
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_not_fixed_rounded,
                        color: isTracking
                            ? const Color(0xFF15803D)
                            : const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTracking
                                ? 'Tracking is active'
                                : 'Tracking is stopped',
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isTracking
                                ? 'GPS updates are being sent in the background.'
                                : 'Start tracking from an active dispatch below.',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active dispatches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                    ),
                  ),
                  if (!isLoadingDispatches)
                    Text(
                      '${dispatches.length} found',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (isLoadingDispatches)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (dispatchError != null)
                _messageCard(
                  cardColor: cardColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load dispatches',
                  message: dispatchError!,
                  buttonLabel: 'Try again',
                  onPressed: _loadDispatches,
                )
              else if (dispatches.isEmpty)
                _messageCard(
                  cardColor: cardColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  icon: Icons.local_shipping_outlined,
                  title: 'No active dispatches',
                  message:
                      'There are no active dispatches linked to your driver account. Ask your fleet administrator to check your driver assignment.',
                  buttonLabel: 'Refresh',
                  onPressed: _loadDispatches,
                )
              else
                ...dispatches.map((rawDispatch) {
                  final dispatch = rawDispatch is Map
                      ? rawDispatch
                      : <String, dynamic>{};

                  final dispatchId = _intValue(dispatch, 'id');
                  final expanded =
                      dispatchId != null &&
                      expandedDispatchId == dispatchId;

                  final isThisTracking =
                      dispatchId != null &&
                      trackingDispatchId == dispatchId &&
                      isTracking;

                  final origin = _value(dispatch, 'origin');
                  final destination =
                      _value(dispatch, 'destination');
                  final vehicleCode =
                      _value(dispatch, 'vehicle_code');
                  final plateNumber =
                      _value(dispatch, 'plate_number');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isThisTracking
                            ? const Color(0xFF22C55E)
                            : (isDarkMode
                                ? Colors.white10
                                : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            setState(() {
                              expandedDispatchId = expanded
                                  ? null
                                  : dispatchId;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isThisTracking
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFDBEAFE),
                                    borderRadius:
                                        BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_rounded,
                                    color: isThisTracking
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dispatchNumber(dispatch),
                                        style: TextStyle(
                                          color: primaryText,
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        vehicleCode.isNotEmpty
                                            ? vehicleCode
                                            : (plateNumber.isNotEmpty
                                                ? plateNumber
                                                : 'Assigned vehicle'),
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: Color(0xFF22C55E),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isThisTracking
                                                ? 'Tracking now'
                                                : 'Active',
                                            style: const TextStyle(
                                              color: Color(0xFF16A34A),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: secondaryText,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (expanded) ...[
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              18,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _routeRow(
                                  icon: Icons.trip_origin_rounded,
                                  iconColor: const Color(0xFF16A34A),
                                  label: 'ORIGIN',
                                  value: origin.isEmpty
                                      ? 'Not provided'
                                      : origin,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                                const SizedBox(height: 15),
                                _routeRow(
                                  icon: Icons.location_on_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                  label: 'DESTINATION',
                                  value: destination.isEmpty
                                      ? 'Not provided'
                                      : destination,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                                const SizedBox(height: 15),
                                _detailRow(
                                  'Vehicle code',
                                  vehicleCode.isEmpty
                                      ? 'Not provided'
                                      : vehicleCode,
                                  primaryText,
                                  secondaryText,
                                ),
                                const SizedBox(height: 8),
                                _detailRow(
                                  'Plate number',
                                  plateNumber.isEmpty
                                      ? 'Not provided'
                                      : plateNumber,
                                  primaryText,
                                  secondaryText,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed:
                                        (isStartingTracking ||
                                                isStoppingTracking ||
                                                (isTracking &&
                                                    !isThisTracking))
                                            ? null
                                            : () => _toggleTracking(
                                                  dispatch,
                                                ),
                                    icon: Icon(
                                      isThisTracking
                                          ? Icons.stop_circle_rounded
                                          : Icons.gps_fixed_rounded,
                                    ),
                                    label: Text(
                                      isStartingTracking
                                          ? 'Starting tracking...'
                                          : isStoppingTracking
                                              ? 'Stopping tracking...'
                                              : isThisTracking
                                                  ? 'Stop tracking'
                                                  : 'Start delivery tracking',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isThisTracking
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding:
                                          const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isTracking &&
                                    !isThisTracking) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Another dispatch is currently being tracked. Stop it before starting this one.',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 12),

              // Map placeholder retained from the previous home screen.
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white10
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: CustomPaint(
                          painter: _MapPreviewPainter(
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 15,
                      left: 16,
                      child: Text(
                        'MAP PREVIEW',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 16,
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
                                ? 'Tracking service running'
                                : 'Map illustration — not live GPS',
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

              const SizedBox(height: 24),
              Center(
                child: Text(
                  loginEmail == null || loginEmail!.isEmpty
                      ? 'FleetOps • Fleet Tracking System'
                      : 'Signed in as $loginEmail',
                  textAlign: TextAlign.center,
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

  Widget _messageCard({
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: secondaryText),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _routeRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value,
    Color primaryText,
    Color secondaryText,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: secondaryText,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// DECORATIVE MAP PREVIEW (NOT A LIVE MAP)
// ------------------------------------------------------------

class _MapPreviewPainter extends CustomPainter {
  _MapPreviewPainter({required this.isDarkMode});

  final bool isDarkMode;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDarkMode
          ? const Color(0xFF334155)
          : const Color(0xFFFFFFFF)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinRoadPaint = Paint()
      ..color = isDarkMode
          ? const Color(0xFF475569)
          : const Color(0xFFDBEAFE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paths = <Path>[
      Path()
        ..moveTo(-10, size.height * 0.25)
        ..lineTo(size.width * 0.35, size.height * 0.55)
        ..lineTo(size.width * 0.70, size.height * 0.20)
        ..lineTo(size.width + 10, size.height * 0.45),
      Path()
        ..moveTo(size.width * 0.10, size.height + 10)
        ..lineTo(size.width * 0.45, size.height * 0.55)
        ..lineTo(size.width * 0.60, -10),
      Path()
        ..moveTo(size.width * 0.80, size.height + 10)
        ..lineTo(size.width * 0.68, size.height * 0.65)
        ..lineTo(size.width + 10, size.height * 0.70),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, thinRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode;
  }
}
