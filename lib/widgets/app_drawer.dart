import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/productos_screen.dart';
import '../screens/estado_ventas_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final displayName = user?.nombre ?? user?.username ?? 'Usuario';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header del drawer
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  radius: 30,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                if (user?.username != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user!.username}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          // Opciones del menú
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Productos'),
                  selected: currentRoute == '/productos',
                  selectedTileColor: Colors.grey[200],
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/productos') {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ProductosScreen(),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Estado de Ventas'),
                  selected: currentRoute == '/estado-ventas',
                  selectedTileColor: Colors.grey[200],
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/estado-ventas') {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const EstadoVentasScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Botón de cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              Navigator.pop(context);
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

