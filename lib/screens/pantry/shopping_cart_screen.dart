import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/shopping_controller.dart';
import '../../models/shopping_list_item.dart';
import '../../utils/app_colors.dart';

/// Pantalla del Carrito de Compras.
/// Muestra los ingredientes faltantes y permite marcarlos como comprados.
class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShoppingController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Carrito de Compras',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            tooltip: 'Limpiar carrito',
            onPressed: () => _confirmClearCart(context, controller, isDark),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.nutveSelectionGreen),
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
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes ingredientes pendientes',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los ingredientes faltantes de tus recetas\naparecerán aquí',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.nutveSelectionGreen,
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

  void _confirmClearCart(
    BuildContext context,
    ShoppingController controller,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Limpiar carrito',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          '¿Estás seguro? Esto eliminará todos los ingredientes pendientes del carrito.',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
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
        backgroundColor: AppColors.nutveSelectionGreen,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedOpacity(
        opacity: _isRemoving ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
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
                      ? AppColors.nutveSelectionGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: _isChecked
                        ? AppColors.nutveSelectionGreen
                        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
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
                color: _isChecked
                    ? Colors.grey
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.item.displayQuantity,
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey,
                  fontSize: 14,
                ),
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
                        ? AppColors.nutveSelectionGreen
                        : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    size: 20,
                  ),
                  label: Text(
                    _isChecked ? '¡Listo!' : 'Comprado',
                    style: TextStyle(
                      color: _isChecked
                          ? AppColors.nutveSelectionGreen
                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Botón eliminar
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
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
