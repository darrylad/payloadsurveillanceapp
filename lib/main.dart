import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:payloadsurveillanceapp/firebase_options.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:payloadsurveillanceapp/graph_data_service.dart';
import 'package:payloadsurveillanceapp/maps_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const LoadcellDataPage(),
    const GraphsPage(),
    const MapPage(), // Add the new map page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(255, 23, 41, 59),
        overlayColor: WidgetStateProperty.all(
          const Color.fromARGB(255, 29, 47, 65),
        ),
        indicatorColor: const Color.fromARGB(255, 48, 80, 102),
        height: 70,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Graphs',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key});

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> {
  // Use the singleton service
  final GraphDataService _graphDataService = GraphDataService();

  // Local subscription to data updates
  StreamSubscription<bool>? _updateSubscription;

  // Local state to trigger rebuilds
  bool _hasData = false;

  // Add touch state variables at class level
  Map<String, bool> _isTouched = {
    'totalWeight': false,
    'weight1': false,
    'weight2': false,
  };
  Map<String, double> _touchedValues = {
    'totalWeight': 0,
    'weight1': 0,
    'weight2': 0,
  };
  Map<String, String> _touchedTimes = {
    'totalWeight': '',
    'weight1': '',
    'weight2': '',
  };

  @override
  void initState() {
    super.initState();

    // Initialize the service if not already initialized
    _graphDataService.initialize();

    // Listen for data updates to rebuild the UI
    _updateSubscription = _graphDataService.onUpdate.listen((_) {
      if (mounted) {
        setState(() {
          _hasData = _graphDataService.weight1Spots.isNotEmpty;
        });
      }
    });

    // Set initial state
    _hasData = _graphDataService.weight1Spots.isNotEmpty;
  }

  @override
  void dispose() {
    // Only cancel our update subscription, not the service itself
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 32, 47),
      appBar: AppBar(
        title: const Text(
          "Weight Graphs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 53, 73),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            !_hasData
                ? const Center(
                  child: Text(
                    'Waiting for data...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: _buildChart(
                        'totalWeight',
                        _graphDataService.totalWeightSpots,
                        Colors.amber,
                        _graphDataService.totalWeightTimes, // Pass time list
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildChart(
                        'weight1',
                        _graphDataService.weight1Spots,
                        Colors.greenAccent,
                        _graphDataService.weight1Times, // Pass time list
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildChart(
                        'weight2',
                        _graphDataService.weight2Spots,
                        Colors.purpleAccent,
                        _graphDataService.weight2Times, // Pass time list
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildChart(
    String title,
    List<FlSpot> spots,
    Color color,
    List<String> times,
  ) {
    // Get min and max values for better scaling
    double minY = 0;
    double maxY = 10;

    if (spots.isNotEmpty) {
      minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

      // Add 10% padding on top and bottom
      final padding = (maxY - minY) * 0.1;
      minY = minY - padding;
      maxY = maxY + padding;

      // Ensure reasonable range even if all values are the same
      if (minY == maxY) {
        minY = minY - 1;
        maxY = maxY + 1;
      }

      // Ensure minY is never negative for weight (unless data shows negative)
      if (minY > 0) minY = 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 34, 51, 69),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Show time and value when touched, using the class-level variables
              if (_isTouched[title] == true)
                Text(
                  '${_touchedValues[title]?.toStringAsFixed(1)}g at ${_touchedTimes[title]}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFF2C3E50),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: const Color(0xFF2C3E50),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        // Show actual time values at intervals
                        final int index = value.toInt();
                        if (index >= 0 &&
                            index < spots.length &&
                            index % 5 == 0) {
                          // Only show every 5th point to avoid overcrowding
                          if (index < times.length) {
                            // Extract just the time portion (assuming format like "12:34:56")
                            final timeStr = times[index];
                            final timeOnly =
                                timeStr.contains(':')
                                    ? timeStr.split(' ').last
                                    : timeStr;

                            return Text(
                              timeOnly,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            );
                          }
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFF536878), width: 1),
                ),
                minX: spots.isEmpty ? 0 : 0,
                maxX: spots.isEmpty ? 60 : (spots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipColor: (touchedSpot) {
                      return Colors.black38;
                    },
                  ),
                  touchCallback: (
                    FlTouchEvent event,
                    LineTouchResponse? touchResponse,
                  ) {
                    if (event is FlPanEndEvent || event is FlTapUpEvent) {
                      setState(() {
                        _isTouched[title] = false;
                      });
                      return;
                    }

                    if (touchResponse == null ||
                        touchResponse.lineBarSpots == null ||
                        touchResponse.lineBarSpots!.isEmpty) {
                      setState(() {
                        _isTouched[title] = false;
                      });
                      return;
                    }

                    final FlSpot spot = touchResponse.lineBarSpots!.first;
                    final int spotIndex = spot.x.toInt();

                    if (spotIndex >= 0 && spotIndex < times.length) {
                      setState(() {
                        _isTouched[title] = true;
                        _touchedValues[title] = spot.y;
                        _touchedTimes[title] = times[spotIndex];
                      });
                    }
                  },
                  getTouchedSpotIndicator: (
                    LineChartBarData barData,
                    List<int> spotIndexes,
                  ) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: Colors.white, strokeWidth: 2),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadcellDataPage extends StatefulWidget {
  const LoadcellDataPage({super.key});

  @override
  State<LoadcellDataPage> createState() => _LoadcellDataPageState();
}

class _LoadcellDataPageState extends State<LoadcellDataPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child(
    'loadcell',
  );

  StreamSubscription<DatabaseEvent>? _dataSubscription;

  String _date = '--';
  String _time = '--';
  String _systemTime = '--';
  double _totalWeight = 0.0;
  double _weight1 = 0.0;
  double _weight2 = 0.0;

  @override
  void initState() {
    super.initState();

    _dataSubscription = _databaseRef.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _date = data['date']?.toString() ?? '--';
          _time = data['time']?.toString() ?? '--';
          _systemTime = data['systemTime'].toString();
          _totalWeight = double.parse((data['totalWeight'] ?? 0).toString());
          _weight1 = double.parse((data['weight1'] ?? 0).toString());
          _weight2 = double.parse((data['weight2'] ?? 0).toString());
        });
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 32, 47),
      appBar: AppBar(
        title: const Text(
          "Payload Surveillance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 53, 73),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time information section
            _buildTimeInfoSection(),

            const SizedBox(height: 30),
            // Weight pads visualization
            _buildWeightPadsVisualization(),

            const SizedBox(height: 30),
            // Total weight display
            _buildTotalWeightSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Time',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Uptime',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_systemTime seconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPadsVisualization() {
    return SizedBox(
      height: 160,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left weight pad
          _buildWeightPad(_weight1),
          // Right weight pad
          _buildWeightPad(_weight2),
        ],
      ),
    );
  }

  Widget _buildWeightPad(double weight) {
    return SizedBox(
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 96, 178, 250),
                    Color.fromARGB(255, 7, 75, 147),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: const Color(0xFF2C3E50), width: 2.0),
              ),
            ),
          ),

          // Weight value display - centered over the pad
          Positioned(
            top: 60,
            child: Container(
              width: 160,
              alignment: Alignment.center,
              child: Text(
                '${weight.toStringAsFixed(1)} g',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalWeightSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 31, 115, 171), // Light blue
            Color.fromARGB(255, 12, 88, 139), // Dark blue
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'TOTAL WEIGHT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${_totalWeight.toStringAsFixed(1)} g',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 3),
                  blurRadius: 5.0,
                  color: Color.fromARGB(150, 0, 0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
