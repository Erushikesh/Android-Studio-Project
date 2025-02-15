import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(WaterEjectorApp());
}

class WaterEjectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WaterEjectorScreen(),
    );
  }
}

class WaterEjectorScreen extends StatefulWidget {
  @override
  _WaterEjectorScreenState createState() => _WaterEjectorScreenState();
}

class _WaterEjectorScreenState extends State<WaterEjectorScreen>
    with SingleTickerProviderStateMixin {
  bool isEjecting = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  List<Ripple> ripples = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..addListener(() {
      setState(() {});
    });

    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation1 = ColorTween(
      begin: Colors.blue.shade900,
      end: Colors.white,
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: Colors.blue.shade300,
      end: Colors.blue.shade700,
    ).animate(_controller);
  }

  void toggleEjector() {
    if (isEjecting) {
      _controller.reverse();
      _audioPlayer.stop();
    } else {
      _controller.repeat(reverse: true);
      startRippleEffect();
      startEjectSound();
    }
    setState(() {
      isEjecting = !isEjecting;
    });
  }

  void startEjectSound() async {
    await _audioPlayer.setSource(AssetSource('sounds/water_eject.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.resume();
  }

  void startRippleEffect() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!isEjecting) {
        timer.cancel();
        return;
      }
      setState(() {
        ripples.add(Ripple());
      });
      if (ripples.length > 6) ripples.removeAt(0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _colorAnimation1.value ?? Colors.blue,
              _colorAnimation2.value ?? Colors.lightBlue,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(double.infinity, double.infinity),
              painter: RipplePainter(ripples),
            ),
            GestureDetector(
              onTap: toggleEjector,
              child: Transform.scale(
                scale: _animation.value,
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isEjecting ? Icons.water_drop : Icons.play_arrow,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Ripple {
  final double startTime;
  Ripple() : startTime = DateTime.now().millisecondsSinceEpoch.toDouble();
}

class RipplePainter extends CustomPainter {
  final List<Ripple> ripples;
  RipplePainter(this.ripples);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    double centerX = size.width / 2;
    double centerY = size.height / 2;
    final double currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

    for (Ripple ripple in ripples) {
      double progress = (currentTime - ripple.startTime) / 1500.0;
      if (progress > 1) continue;
      double radius = progress * 150;
      paint.color = Colors.blue.withOpacity(1 - progress);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
