import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importaciones de tus archivos (Asegúrate que las rutas sean correctas)
import 'providers/medication_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_nav_screen.dart';
import 'screens/login_screen.dart';
import 'services/push_service.dart';

void main() async {
  // Aseguramos que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos el formateo de fechas en español
  await initializeDateFormatting('es', null);

  // Inicializamos las notificaciones push (tolerante: no rompe si no hay config)
  await PushService.initialize();

  runApp(
    // El MultiProvider envuelve toda la app para que los datos fluyan
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
      ],
      child: const CuidApp(),
    ),
  );
}

class CuidApp extends StatelessWidget {
  const CuidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CuidApp',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),

      // Configuración del tema visual basado en diseño Figma
      theme: ThemeData(
        useMaterial3: true,

        // Aplicamos la fuente para legibilidad de adultos mayores
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),

        // Paleta de colores según Figma
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF030213), // Negro oscuro
          secondary: Color(0xFFe9ebef), // Gris para accent
          tertiary: Color(0xFFececf0), // Gris para muted
          surface: Color(0xFFf3f3f5), // Gris para inputs
          surfaceContainer: Color(0xFFffffff), // Blanco para contenedores
          error: Color(0xFFd4183d), // Rojo destructivo
          onPrimary: Color(0xFFffffff), // Texto sobre primary
          onSecondary: Color(0xFF030213), // Texto sobre secondary
          onTertiary: Color(0xFF030213), // Texto sobre tertiary
          onSurface: Color(0xFF030213), // Texto sobre surface
          onError: Color(0xFFffffff), // Texto sobre error
        ),

        // Estilo global para los AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A56DB),
          foregroundColor: Color(0xFFffffff),
          elevation: 0,
        ),

        // Estilo para botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF030213),
            foregroundColor: const Color(0xFFffffff),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Estilo para inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFf3f3f5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFececf0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFececf0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF030213), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),

      // El punto de entrada decide basado en el estado de autenticación
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isLoggedIn
              ? const MainNavScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
