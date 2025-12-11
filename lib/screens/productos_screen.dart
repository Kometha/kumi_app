import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'registro_producto_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _productoService = ProductoService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Producto> _productos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productos = await _productoService.getProductos();
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar productos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarProducto(int productoId) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si el usuario confirmó, proceder con la eliminación
    if (confirmar == true) {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Eliminando producto...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final resultado = await _productoService.eliminarProducto(productoId);

      if (mounted) {
        if (resultado['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Recargar productos para que el eliminado ya no aparezca
          _cargarProductos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar producto: ${resultado['error']}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Productos',
        onReload: _cargarProductos,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AppDrawer(currentRoute: '/productos'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarProductos,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _productos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay productos disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarProductos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _productos.length,
                            itemBuilder: (context, index) {
                              final producto = _productos[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ProductoCard(
                                  producto: producto,
                                  onEliminar: () =>
                                      _eliminarProducto(producto.id),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                // Botón Registrar fijo en la parte inferior (solo si no está cargando)
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistroProductoScreen(),
                              ),
                            ).then((_) {
                              // Recargar productos después de registrar
                              _cargarProductos();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Registrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onEliminar;

  const _ProductoCard({required this.producto, required this.onEliminar});

  String _formatearPrecio(double precio) {
    return 'L. ${precio.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del producto
                Text(
                  producto.nombre ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Categoría
                if (producto.categoria != null &&
                    producto.categoria!.nombre != null)
                  Text(
                    producto.categoria!.nombre!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                // Descripción
                if (producto.descripcion != null &&
                    producto.descripcion!.isNotEmpty)
                  Text(
                    producto.descripcion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),
                // Stock y Precio
                Row(
                  children: [
                    // Stock con icono de caja
                    if (producto.inventario?.stockActual != null)
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${producto.inventario!.stockActual} unidades',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Precio con icono de dinero
                    if (producto.precio != null)
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatearPrecio(producto.precio!.precioVenta),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Botón de eliminar en la esquina superior derecha
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(4),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: onEliminar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
