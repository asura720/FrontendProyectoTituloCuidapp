import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/medication_provider.dart';
import 'home_screen.dart';
import 'medications_screen.dart';
import 'controls_screen.dart';
import 'map_screen.dart';
import 'vinculacion_screen.dart';
import 'scanner_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<MedicationProvider>().loadMedications(auth.currentUser!.id);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // La pestaña Cuidador solo aparece si el usuario activó la función
    // (o si ya es titular con pacientes a cargo).
    final user = context.watch<AuthProvider>().currentUser;
    final showCuidador =
        user?.caregiverEnabled == true || user?.role == 'TITULAR';

    final screens = <Widget>[
      const HomeScreen(),
      const MedicationsScreen(),
      const ControlsScreen(),
      const MapScreen(),
      if (showCuidador) const VinculacionScreen(),
      const ScannerScreen(),
      const ProfileScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.medication_outlined),
        label: 'Medicinas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        label: 'Controles',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        label: 'Cerca',
      ),
      if (showCuidador)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Cuidador',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.camera_alt_outlined),
        label: 'Escáner',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];

    // Evitar índice fuera de rango si la lista cambió de tamaño
    final index = _selectedIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A56DB),
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Colors.white,
        elevation: 12,
        currentIndex: index,
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: items,
      ),
    );
  }
}
