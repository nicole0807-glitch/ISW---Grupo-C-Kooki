import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminReportsController extends GetxController {
  final AdminService _adminService = AdminService();

  var reports = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      isLoading.value = true;
      final data = await _adminService.getReportedRecipes();
      reports.assignAll(data);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los reportes',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> dismissReport(dynamic reportId) async {
    try {
      isLoading.value = true;
      await _adminService.dismissReport(reportId);
      reports.removeWhere((r) => r['id'] == reportId);
      Get.snackbar('Éxito', 'Reporte descartado');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo descartar el reporte');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> banRecipe(Map<String, dynamic> report) async {
    try {
      isLoading.value = true;
      await _adminService.banRecipe(
        report['recipe_id'],
        report['is_community'],
        report['id'],
      );
      reports.removeWhere((r) => r['id'] == report['id']);
      Get.snackbar('Éxito', 'Receta eliminada y reporte cerrado');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la receta: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
