import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:payloadsurveillanceapp/firebase_options.dart';

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
      title: 'Payload Surveillance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoadcellDataPage(),
    );
  }
}

class LoadcellDataPage extends StatefulWidget {
  const LoadcellDataPage({super.key});

  @override
  State<LoadcellDataPage> createState() => _LoadcellDataPageState();
}

class _LoadcellDataPageState extends State<LoadcellDataPage> {
  // Firebase database reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child(
    'loadcell',
  );

  String _date = '--';
  String _time = '--';
  int _systemTime = 0;
  double _totalWeight = 0.0;
  double _weight1 = 0.0;
  double _weight2 = 0.0;

  @override
  void initState() {
    super.initState();

    _databaseRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _date = data['date']?.toString() ?? '--';
          _time = data['time']?.toString() ?? '--';
          _systemTime = data['systemTime'] ?? 0;
          _totalWeight = double.parse((data['totalWeight'] ?? 0).toString());
          _weight1 = double.parse((data['weight1'] ?? 0).toString());
          _weight2 = double.parse((data['weight2'] ?? 0).toString());
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // Dark blue background
      appBar: AppBar(
        title: const Text(
          "Payload Surveillance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF34495E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
    return AspectRatio(
      aspectRatio: 1.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left weight pad
          _buildWeightPad("Weight Pad 1", _weight1),

          // Right weight pad
          _buildWeightPad("Weight Pad 2", _weight2),
        ],
      ),
    );
  }

  Widget _buildWeightPad(String label, double weight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Weight pad label
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),

        // 3D weight pad with perspective
        Stack(
          alignment: Alignment.center,
          children: [
            // Main weight pad surface with perspective transform
            Transform(
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX(0.3) // tilt around X-axis
                    ..rotateY(-0.1), // slight tilt around Y-axis
              alignment: Alignment.center,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFCA8A45), // Light wood
                      Color(0xFF8B5A2B), // Dark wood
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 15,
                      offset: const Offset(5, 5),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF5D4037), width: 2),
                ),
                child: CustomPaint(painter: WoodTexturePainter()),
              ),
            ),

            // Front edge of the weight pad (thickness)
            Positioned(
              bottom: 0,
              child: Transform(
                transform:
                    Matrix4.identity()
                      ..rotateX(1.0) // rotate to show the front edge
                      ..translate(0.0, 0.0, -20.0), // position at the bottom
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 130,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D4037), // Darker wood color for edge
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Weight value display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${weight.toStringAsFixed(1)} kg',
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
      ],
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
            Color(0xFF3498DB), // Light blue
            Color(0xFF2980B9), // Dark blue
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL WEIGHT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
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

// Custom painter to add wood grain texture
class WoodTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Paint wood grain lines
    for (int i = 0; i < 20; i++) {
      final y = i * (size.height / 20);
      final path = Path();

      // Create wavy lines for realistic wood grain
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += size.width / 10) {
        path.quadraticBezierTo(
          x + size.width / 20,
          y + (i % 3 == 0 ? 2 : -2),
          x + size.width / 10,
          y,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
