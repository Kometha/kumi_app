import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pedido.dart';
import '../services/venta_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_drawer.dart';

class EstadoVentasScreen extends StatefulWidget {
  const EstadoVentasScreen({super.key});

  @override
  State<EstadoVentasScreen> createState() => _EstadoVentasScreenState();
}

class _EstadoVentasScreenState extends State<EstadoVentasScreen> {
  final VentaService _ventaService = VentaService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Pedido> _pedidos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pedidos = await _ventaService.getVentas();
      setState(() {
        _pedidos = pedidos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar ventas: $e';
        _isLoading = false;
      });
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en proceso':
        return Colors.blue;
      case 'completado':
      case 'completada':
        return Colors.green;
      case 'cancelado':
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(String fecha) {
    try {
      // Intentar parsear diferentes formatos de fecha
      DateTime? dateTime;

      // Formato: "2025-12-10 00:00:00.000000"
      if (fecha.contains(' ')) {
        final parts = fecha.split(' ');
        if (parts.isNotEmpty) {
          dateTime = DateTime.tryParse(parts[0]);
        }
      } else {
        dateTime = DateTime.tryParse(fecha);
      }

      if (dateTime != null) {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
      return fecha;
    } catch (e) {
      return fecha;
    }
  }

  String _formatearMoneda(double cantidad) {
    return NumberFormat.currency(
      symbol: 'L.',
      decimalDigits: 2,
    ).format(cantidad);
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.access_time;
      case 'en proceso':
        return Icons.sync;
      case 'completado':
      case 'completada':
      case 'pagado':
        return Icons.check_circle;
      case 'cancelado':
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _mostrarModalEditarPedido(Pedido pedido) async {
    try {
      // Obtener estados disponibles
      final estados = await _ventaService.getEstadosPedido();

      // Obtener el ID del estado actual del pedido
      final estadoActualId = pedido.item.estadoId;

      // Filtrar estados: excluir el estado actual
      final estadosDisponibles = estados
          .where((estado) => estado.id != estadoActualId)
          .toList();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y botón cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Editar Pedido',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Cliente y monto
                  Text(
                    '${pedido.cliente.isNotEmpty ? pedido.cliente : 'Cliente no especificado'} • ${_formatearMoneda(pedido.total)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  // Título de sección
                  const Text(
                    'Cambiar estado del pedido:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Estado actual (no seleccionable)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(pedido.estado),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pedido.estado} (Actual)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Estados disponibles
                  ...estadosDisponibles.map((estado) {
                    final estadoColor = _getEstadoColor(estado.nombre);
                    final estadoIcon = _getEstadoIcon(estado.nombre);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Actualizar estado
                            final resultado = await _ventaService
                                .actualizarEstadoPedido(
                                  pedidoId: pedido.item.id,
                                  nuevoEstadoId: estado.id,
                                );

                            if (!mounted) return;

                            Navigator.of(dialogContext).pop();

                            if (resultado['success'] == true) {
                              // Actualizar solo este pedido en la lista localmente
                              // sin necesidad de recargar todos los pedidos
                              setState(() {
                                final index = _pedidos.indexWhere(
                                  (p) => p.item.id == pedido.item.id,
                                );
                                if (index != -1) {
                                  // Crear un nuevo objeto Pedido con el estado actualizado
                                  final pedidoActualizado = Pedido(
                                    cliente: pedido.cliente,
                                    codigoPedido: pedido.codigoPedido,
                                    canal: pedido.canal,
                                    fecha: pedido.fecha,
                                    total: pedido.total,
                                    estado: estado.nombre, // Nuevo estado
                                    item: ItemPedido(
                                      id: pedido.item.id,
                                      codigoPedido: pedido.item.codigoPedido,
                                      clienteId: pedido.item.clienteId,
                                      canalId: pedido.item.canalId,
                                      estadoId: estado.id, // Nuevo estado ID
                                      fechaPedido: pedido.item.fechaPedido,
                                      total: pedido.item.total,
                                      notas: pedido.item.notas,
                                      createdAt: pedido.item.createdAt,
                                      updatedAt: pedido.item.updatedAt,
                                      nombreCliente: pedido.item.nombreCliente,
                                      telefonoCliente:
                                          pedido.item.telefonoCliente,
                                      subtotalProductos:
                                          pedido.item.subtotalProductos,
                                      totalComisionesFinanciamiento: pedido
                                          .item
                                          .totalComisionesFinanciamiento,
                                      totalFactura: pedido.item.totalFactura,
                                      totalComisionesMetodos:
                                          pedido.item.totalComisionesMetodos,
                                      montoNetoRecibido:
                                          pedido.item.montoNetoRecibido,
                                      costoEnvio: pedido.item.costoEnvio,
                                      necesitaEnvio: pedido.item.necesitaEnvio,
                                      direccionCliente:
                                          pedido.item.direccionCliente,
                                      itemCliente: pedido.item.itemCliente,
                                      itemCanal: pedido.item.itemCanal,
                                      itemEstado: EstadoPedido(
                                        id: estado.id,
                                        nombre: estado.nombre,
                                        activo: estado.activo,
                                        createdAt: estado.createdAt,
                                      ),
                                    ),
                                  );
                                  _pedidos[index] = pedidoActualizado;
                                }
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    resultado['message'] ??
                                        'Estado actualizado',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: ${resultado['error'] ?? 'Error desconocido'}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: estadoColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(estadoIcon, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                estado.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar estados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Estado de Ventas',
        onReload: _cargarVentas,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AppDrawer(currentRoute: '/estado-ventas'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarVentas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _pedidos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay ventas registradas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Label con cantidad de pedidos
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.grey[100],
                  child: Text(
                    '${_pedidos.length} pedidos totales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                // Lista de pedidos
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarVentas,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pedidos.length,
                      itemBuilder: (context, index) {
                        final pedido = _pedidos[index];
                        final estadoColor = _getEstadoColor(pedido.estado);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              _mostrarModalEditarPedido(pedido);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header con código de pedido y estado
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pedido.codigoPedido,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: estadoColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: estadoColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          pedido.estado,
                                          style: TextStyle(
                                            color: estadoColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Información del cliente
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          pedido.cliente.isNotEmpty
                                              ? pedido.cliente
                                              : 'Cliente no especificado',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Canal de venta
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        pedido.canal,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Fecha
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatearFecha(pedido.fecha),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  // Total
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatearMoneda(pedido.total),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
