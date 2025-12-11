import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onReload;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onReload,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          if (scaffoldKey?.currentState != null) {
            scaffoldKey!.currentState!.openDrawer();
          } else {
            Scaffold.of(context).openDrawer();
          }
        },
      ),
      title: Text(title),
      centerTitle: true,
      actions: onReload != null
          ? [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: onReload,
                tooltip: 'Actualizar',
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

