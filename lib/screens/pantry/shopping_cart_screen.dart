import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/shopping_controller.dart';
import '../../models/shopping_list_item.dart';

/// Pantalla del Carrito de Compras.
/// Muestra los ingredientes faltantes y permite marcarlos como comprados.
class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShoppingController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Carrito de Compras',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            tooltip: 'Limpiar carrito',
            onPressed: () => _confirmClearCart(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        if (controller.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes ingredientes pendientes',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los ingredientes faltantes de tus recetas\naparecerán aquí',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadCartItems,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.cartItems.length,
            itemBuilder: (context, index) {
              final item = controller.cartItems[index];
              return _ShoppingCartItemCard(
                key: ValueKey(item.id),
                item: item,
                controller: controller,
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmClearCart(BuildContext context, ShoppingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar carrito'),
        content: const Text(
          '¿Estás seguro? Esto eliminará todos los ingredientes pendientes del carrito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearCartItems();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}

/// Card individual para cada ítem del carrito.
class _ShoppingCartItemCard extends StatefulWidget {
  final ShoppingListItem item;
  final ShoppingController controller;

  const _ShoppingCartItemCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<_ShoppingCartItemCard> createState() => _ShoppingCartItemCardState();
}

class _ShoppingCartItemCardState extends State<_ShoppingCartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isChecked = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onMarkAsBought() async {
    if (_isRemoving || widget.item.id == null) return;

    setState(() {
      _isChecked = true;
      _isRemoving = true;
    });

    // Esperar un momento para que se vea la animación del check
    await Future.delayed(const Duration(milliseconds: 500));

    // Animar la salida de la card
    await _animController.forward();

    // Ejecutar la lógica
    final success = await widget.controller.markAsBought(widget.item.id!);

    if (success && mounted) {
      Get.snackbar(
        '¡Comprado!',
        '${widget.item.displayName} se agregó a tu despensa',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  Future<void> _onRemoveItem() async {
    if (_isRemoving || widget.item.id == null) return;

    setState(() => _isRemoving = true);
    await _animController.forward();
    await widget.controller.removeItem(widget.item.id!);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedOpacity(
        opacity: _isRemoving ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: GestureDetector(
              onTap: _onMarkAsBought,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isChecked
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isChecked
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: _isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
            title: Text(
              widget.item.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: _isChecked ? TextDecoration.lineThrough : null,
                color: _isChecked ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.item.displayQuantity,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón "Comprado"
                TextButton.icon(
                  onPressed: _isRemoving ? null : _onMarkAsBought,
                  icon: Icon(
                    _isChecked
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: _isChecked
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                  label: Text(
                    _isChecked ? '¡Listo!' : 'Comprado',
                    style: TextStyle(
                      color: _isChecked
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Botón eliminar
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: _isRemoving ? null : _onRemoveItem,
                  tooltip: 'Eliminar del carrito',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
