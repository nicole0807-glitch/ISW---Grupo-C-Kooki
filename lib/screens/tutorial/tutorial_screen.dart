import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../home/main_layout.dart';

class TutorialScreen extends StatefulWidget {
  final bool showMainLayout;
  const TutorialScreen({super.key, this.showMainLayout = true});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/Mitroglu4.png',
      'title': '¡Hola!',
      'description':
          'Soy tu Maestro Nutricionista. Estoy aquí para ayudarte a transformar tu alimentación.',
    },
    {
      'image': 'assets/Mitroglu3.png',
      'title': 'Comunidad',
      'description':
          'Descubre y comparte tus mejores recetas con otros usuarios.',
    },
    {
      'image': 'assets/Mitroglu4.png',
      'title': 'Asistente IA',
      'description':
          '¿No sabes qué cocinar? Pregúntame lo que sea y te daré recomendaciones.',
    },
    {
      'image': 'assets/Mitroglu3.png',
      'title': 'Tu Salud',
      'description':
          'Registra tus preferencias para que mis consejos se adapten a ti.',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      if (widget.showMainLayout) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index]);
            },
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => _buildDot(index),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Saltar',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _slides.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nutveDarkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1
                        ? '¡Empezar!'
                        : 'Siguiente',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      height: 10,
      width: _currentPage == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.nutveDarkGreen
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildSlide(Map<String, String> slide) {
    return Padding(
      // Reducimos el padding horizontal para que la imagen toque el borde
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. IMAGEN DE MITROGLU (Pegada al extremo izquierdo)
          Align(
            alignment: const Alignment(
              -1.0, // -1.0 es el extremo izquierdo absoluto
              -0.2,
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.45,
              child: Image.asset(slide['image']!, fit: BoxFit.contain),
            ),
          ),

          // 2. NUBE DE TEXTO (Posicionada a la derecha de la imagen, flecha a la IZQUIERDA)
          Align(
            alignment: const Alignment(0.7, 0.1),
            child: CustomPaint(
              painter: ChatBubblePainterLeft(),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                padding: const EdgeInsets.only(
                  left: 35,
                  right: 15,
                  top: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide['title']!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.nutveDarkGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide['description']!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
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
}

// Clase para dibujar la nube con la flecha apuntando a la IZQUIERDA
class ChatBubblePainterLeft extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    double radius = 24;
    double arrowWidth = 20;

    // Dibujar el cuerpo redondeado de la nube (dejando espacio a la IZQUIERDA para la flecha)
    path.addRRect(
      RRect.fromLTRBR(
        arrowWidth,
        0,
        size.width,
        size.height,
        Radius.circular(radius),
      ),
    );

    // Dibujar el triángulo (la flecha que apunta a la IZQUIERDA)
    // Empezamos en el borde IZQUIERDO del cuerpo
    path.moveTo(arrowWidth, size.height * 0.4);
    // Punta de la flecha (hacia la izquierda)
    path.lineTo(0, size.height * 0.5);
    // Regreso al borde
    path.lineTo(arrowWidth, size.height * 0.6);

    canvas.drawShadow(
      path.shift(const Offset(0, 10)),
      Colors.black.withValues(alpha: 0.1),
      15.0,
      true,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
