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

            const SizedBox(height: 20), // Reduced spacing
            // Weight pads visualization
            _buildWeightPadsVisualization(),

            const SizedBox(height: 20), // Reduced spacing
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
    return SizedBox(
      height: 150, // Reduced height
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left weight pad
          _buildWeightPad(_weight1, isLeft: true),

          // Right weight pad
          _buildWeightPad(_weight2, isLeft: false),
        ],
      ),
    );
  }

  Widget _buildWeightPad(double weight, {required bool isLeft}) {
    // Perspective parameters - make them mirror images of each other
    final double topWidthRatio = 0.8; // Top width as percentage of bottom width

    return SizedBox(
      width: 160,
      height: 140, // Reduced height
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom shaped weight pad
          Positioned(
            bottom: 0,
            child: SizedBox(
              width: 160,
              height: 120, // Reduced height
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // The weight pad with perspective (trapezoid)
                  ClipPath(
                    clipper: TrapezoidClipper(
                      topWidthRatio: topWidthRatio,
                      isLeft: isLeft,
                      cornerRadius: 8.0,
                    ),
                    child: Container(
                      width: 160,
                      height: 100, // Reduced height
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF355C7D), // Darker blue at top
                            Color(0xFF6C7A89), // Medium blue-gray at bottom
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),

                  // Add a border to the trapezoid
                  CustomPaint(
                    size: const Size(160, 100), // Reduced height
                    painter: TrapezoidBorderPainter(
                      topWidthRatio: topWidthRatio,
                      borderColor: const Color(0xFF2C3E50),
                      borderWidth: 2.0,
                      isLeft: isLeft,
                      cornerRadius: 8.0,
                    ),
                  ),

                  // Thickness of the pad (front edge)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 160,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 0.5,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Weight value display - floating above the pad
          Positioned(
            top: 0,
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

// Custom clipper to create trapezoid shape with rounded corners
class TrapezoidClipper extends CustomClipper<Path> {
  final double topWidthRatio;
  final bool isLeft;
  final double cornerRadius;

  TrapezoidClipper({
    this.topWidthRatio = 0.8,
    this.isLeft = true,
    this.cornerRadius = 8.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final double topWidth = size.width * topWidthRatio;
    final double horizontalOffset = (size.width - topWidth) / 2;

    // Make inner sides more vertical - reduce the skew for inner edges
    double leftInnerOffset =
        isLeft ? 0.1 : horizontalOffset; // Almost vertical for inner edge
    double rightInnerOffset =
        isLeft
            ? horizontalOffset + topWidth
            : size.width - 0.1; // Almost vertical for inner edge

    if (isLeft) {
      // Left weight pad - inner (right) side nearly vertical
      // Start with rounded top-left corner
      path.moveTo(horizontalOffset, cornerRadius);
      path.lineTo(horizontalOffset, 0);
      path.lineTo(rightInnerOffset - cornerRadius, 0);
      path.quadraticBezierTo(
        rightInnerOffset,
        0,
        rightInnerOffset,
        cornerRadius,
      );

      // Right (inner) side - almost vertical
      path.lineTo(size.width - cornerRadius, size.height - cornerRadius);
      path.quadraticBezierTo(
        size.width,
        size.height - cornerRadius,
        size.width,
        size.height,
      );

      // Bottom side
      path.lineTo(cornerRadius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

      // Left side back up
      path.lineTo(horizontalOffset, cornerRadius);
    } else {
      // Right weight pad - inner (left) side nearly vertical
      // Start with rounded top-left corner
      path.moveTo(leftInnerOffset, cornerRadius);
      path.lineTo(leftInnerOffset, 0);
      path.lineTo(size.width - horizontalOffset - cornerRadius, 0);
      path.quadraticBezierTo(
        size.width - horizontalOffset,
        0,
        size.width - horizontalOffset,
        cornerRadius,
      );

      // Right side
      path.lineTo(size.width - cornerRadius, size.height - cornerRadius);
      path.quadraticBezierTo(
        size.width,
        size.height - cornerRadius,
        size.width,
        size.height,
      );

      // Bottom side
      path.lineTo(cornerRadius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

      // Left (inner) side - almost vertical
      path.lineTo(leftInnerOffset, cornerRadius);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(TrapezoidClipper oldClipper) =>
      oldClipper.topWidthRatio != topWidthRatio ||
      oldClipper.isLeft != isLeft ||
      oldClipper.cornerRadius != cornerRadius;
}

// Painter to add border to trapezoid with rounded corners
class TrapezoidBorderPainter extends CustomPainter {
  final double topWidthRatio;
  final Color borderColor;
  final double borderWidth;
  final bool isLeft;
  final double cornerRadius;

  TrapezoidBorderPainter({
    this.topWidthRatio = 0.8,
    this.borderColor = const Color(0xFF2C3E50),
    this.borderWidth = 2.0,
    this.isLeft = true,
    this.cornerRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final path = Path();
    final double topWidth = size.width * topWidthRatio;
    final double horizontalOffset = (size.width - topWidth) / 2;

    // Make inner sides more vertical - reduce the skew for inner edges
    double leftInnerOffset =
        isLeft ? 0.1 : horizontalOffset; // Almost vertical for inner edge
    double rightInnerOffset =
        isLeft
            ? horizontalOffset + topWidth
            : size.width - 0.1; // Almost vertical for inner edge

    if (isLeft) {
      // Left weight pad - inner (right) side nearly vertical
      // Start with rounded top-left corner
      path.moveTo(horizontalOffset, cornerRadius);
      path.lineTo(horizontalOffset, 0);
      path.lineTo(rightInnerOffset - cornerRadius, 0);
      path.quadraticBezierTo(
        rightInnerOffset,
        0,
        rightInnerOffset,
        cornerRadius,
      );

      // Right (inner) side - almost vertical
      path.lineTo(size.width - cornerRadius, size.height - cornerRadius);
      path.quadraticBezierTo(
        size.width,
        size.height - cornerRadius,
        size.width,
        size.height,
      );

      // Bottom side
      path.lineTo(cornerRadius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

      // Left side back up
      path.lineTo(horizontalOffset, cornerRadius);
    } else {
      // Right weight pad - inner (left) side nearly vertical
      // Start with rounded top-left corner
      path.moveTo(leftInnerOffset, cornerRadius);
      path.lineTo(leftInnerOffset, 0);
      path.lineTo(size.width - horizontalOffset - cornerRadius, 0);
      path.quadraticBezierTo(
        size.width - horizontalOffset,
        0,
        size.width - horizontalOffset,
        cornerRadius,
      );

      // Right side
      path.lineTo(size.width - cornerRadius, size.height - cornerRadius);
      path.quadraticBezierTo(
        size.width,
        size.height - cornerRadius,
        size.width,
        size.height,
      );

      // Bottom side
      path.lineTo(cornerRadius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

      // Left (inner) side - almost vertical
      path.lineTo(leftInnerOffset, cornerRadius);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrapezoidBorderPainter oldDelegate) =>
      oldDelegate.topWidthRatio != topWidthRatio ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.isLeft != isLeft ||
      oldDelegate.cornerRadius != cornerRadius;
}

// Custom painter to add wood grain texture
class WoodTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Calculate the perspective ratio for each line
    for (int i = 0; i < 25; i++) {
      final y = i * (size.height / 25);
      final double lineWidthRatio =
          0.7 + (0.3 * y / size.height); // Lines get wider as they get closer
      final double horizontalOffset = size.width * (1 - lineWidthRatio) / 2;

      final path = Path();
      final startX = horizontalOffset;
      final endX = size.width - horizontalOffset;

      // Create wavy lines for realistic wood grain
      path.moveTo(startX, y);

      final segmentWidth = (endX - startX) / 12;
      for (double x = startX; x < endX; x += segmentWidth) {
        path.quadraticBezierTo(
          x + segmentWidth / 2,
          y + (i % 3 == 0 ? 1.5 : -1.5),
          x + segmentWidth,
          y,
        );
      }

      canvas.drawPath(path, paint);
    }

    // Add some knots/circles in the wood
    paint.color = Colors.brown.withOpacity(0.05);
    paint.style = PaintingStyle.fill;

    // Calculate positions that respect the perspective
    final topOffset = size.width * (1 - 0.7) / 2;

    // First knot - in the upper area
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3 + topOffset * 0.6, size.height * 0.3),
        width: 12,
        height: 5,
      ),
      paint,
    );

    // Second knot - in the lower area
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7 - topOffset * 0.3, size.height * 0.7),
        width: 15,
        height: 8,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
