import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphDataService {
  // Singleton pattern
  static final GraphDataService _instance = GraphDataService._internal();
  factory GraphDataService() => _instance;
  GraphDataService._internal();

  // Data for charts
  final List<FlSpot> weight1Spots = [];
  final List<FlSpot> weight2Spots = [];
  final List<FlSpot> totalWeightSpots = [];

  // Maximum number of data points to keep
  final int maxDataPoints = 100;

  // For x-axis time tracking (seconds since start)
  int startTime = 0;

  // Firebase reference
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child(
    'loadcell',
  );

  // Stream controller to notify listeners of data changes
  final StreamController<bool> _updateController =
      StreamController<bool>.broadcast();
  Stream<bool> get onUpdate => _updateController.stream;

  // Track if the service is initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Track active subscriptions
  StreamSubscription<DatabaseEvent>? _dataSubscription;
  Timer? _timer;

  void initialize() {
    if (_isInitialized) return;

    // Set start timestamp if not already set
    startTime =
        startTime == 0
            ? DateTime.now().millisecondsSinceEpoch ~/ 1000
            : startTime;

    // Listen for real-time updates
    _setupDatabaseListener();

    // Set up timer for regular updates (every 10 seconds)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      databaseRef.get().then((snapshot) {
        if (snapshot.value != null) {
          _updateChartData(snapshot.value as Map<dynamic, dynamic>);
        }
      });
    });

    _isInitialized = true;
  }

  void dispose() {
    _timer?.cancel();
    _dataSubscription?.cancel();
    _timer = null;
    _dataSubscription = null;
    _isInitialized = false;
  }

  void _setupDatabaseListener() {
    _dataSubscription?.cancel();
    _dataSubscription = databaseRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        _updateChartData(event.snapshot.value as Map<dynamic, dynamic>);
      }
    });
  }

  void _updateChartData(Map<dynamic, dynamic> data) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timePoint = (currentTime - startTime).toDouble();

    final weight1 = double.parse((data['weight1'] ?? 0).toString());
    final weight2 = double.parse((data['weight2'] ?? 0).toString());
    final totalWeight = double.parse((data['totalWeight'] ?? 0).toString());

    // Add new data points
    weight1Spots.add(FlSpot(timePoint, weight1));
    weight2Spots.add(FlSpot(timePoint, weight2));
    totalWeightSpots.add(FlSpot(timePoint, totalWeight));

    // Limit to max data points
    if (weight1Spots.length > maxDataPoints) {
      weight1Spots.removeAt(0);
      weight2Spots.removeAt(0);
      totalWeightSpots.removeAt(0);
    }

    // Notify listeners
    _updateController.add(true);
  }

  // Clean up resources when the app is done
  void cleanUp() {
    _timer?.cancel();
    _dataSubscription?.cancel();
    _updateController.close();
  }
}
