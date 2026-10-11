import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class TrackingScreen extends StatefulWidget {
  final int riderId;

  const TrackingScreen({
    super.key,
    required this.riderId,
  });

  @override
  State<TrackingScreen> createState() =>
      _TrackingScreenState();
}

class _TrackingScreenState
    extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {

  final LocationService locationService =
      LocationService();

  final ApiService apiService =
      ApiService();

  bool tracking = false;

  late AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<void> startTracking() async {
    setState(() {
      tracking = true;
    });

    final position =
        await locationService.getCurrentLocation();

    if (position == null) {
      setState(() {
        tracking = false;
      });

      return;
    }

    await apiService.updateLocation(
      widget.riderId,
      position.latitude,
      position.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Tracking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {

                final scale =
                    1.0 +
                    (animationController.value * 0.3);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            Text(
              tracking
                  ? 'Tracking rider...'
                  : 'Tracking stopped',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: startTracking,
              child: const Text(
                'Start Tracking',
              ),
            ),
          ],
        ),
      ),
    );
  }
}