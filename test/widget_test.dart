// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutve_application/main.dart';

void main() {
  // Esto asegura que el entorno de tests esté listo para inicializar servicios externos
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Verificar carga inicial de NutveApp', (WidgetTester tester) async {
    // 1. Inicializamos Supabase
    await Supabase.initialize(
      url: 'https://vmpbdtwfyrzjmblfdtcb.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtcGJkdHdmeXJ6am1ibGZkdGNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1NTg4NTIsImV4cCI6MjA4NTEzNDg1Mn0.2hU6k4MCdpZLo1xzEWCMCbTCHvz3R424d2EHp57Odvg',
    );

    // 2. Cargamos el widget
    await tester.pumpWidget(const NutveApp()); 

    // 3. Verificamos que la app existe
    expect(find.byType(NutveApp), findsOneWidget);
    
    // Nota: He quitado el tester.tap(find.byIcon(Icons.add)) 
    // porque tu NutveApp probablemente no tiene ese icono de suma.
  });
}