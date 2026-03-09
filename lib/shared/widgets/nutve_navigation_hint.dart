import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class NutveNavigationHint {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) =>
          _NavigationHintWidget(onDismiss: () => entry.remove()),
    );

    overlay.insert(entry);
  }
}

class _NavigationHintWidget extends StatefulWidget {
  final VoidCallback onDismiss;

  const _NavigationHintWidget({required this.onDismiss});

  @override
  State<_NavigationHintWidget> createState() => _NavigationHintWidgetState();
}

class _NavigationHintWidgetState extends State<_NavigationHintWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent background (optional, but requested "overlay that doesn't block permanently")
          // We'll use a very light dim or nothing to keep it clean.
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kitchen Icon in a circle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.nutveSelectionGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.kitchen_outlined,
                        color: AppColors.nutveSelectionGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "¡Ingredientes agregados!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text:
                            "Ahora puedes ver tu lista de compras completa entrando a la sección de ",
                        children: [
                          const TextSpan(
                            text: "Despensa",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: " (icono de la nevera "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.kitchen_outlined,
                              size: 16,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          const TextSpan(text: ") en el menú principal."),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.7),
                        height: 1.5,
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
