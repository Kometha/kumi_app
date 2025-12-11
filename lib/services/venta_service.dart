import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido.dart';

class VentaService {
  final supabase = Supabase.instance.client;

  /// Obtener todas las ventas/pedidos desde la vista vw_pedidos
  Future<List<Pedido>> getVentas() async {
    try {
      // Intentar acceder a la vista usando el nombre completo con schema
      // Si esto no funciona, intentaremos sin el schema
      dynamic response;

      try {
        // Primero intentar con schema explícito
        response = await supabase
            .schema('ventas')
            .from('vw_pedidos')
            .select('*');
      } catch (e) {
        // Si falla, intentar acceder directamente (puede estar en schema público o ser accesible)
        print('⚠️ [VENTAS] Intentando acceso directo a vw_pedidos...');
        response = await supabase.from('vw_pedidos').select('*');
      }

      final List<dynamic> data = response as List<dynamic>;

      // Transformar los datos al formato Pedido
      final pedidos = data
          .map((item) => Pedido.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ [VENTAS] Pedidos obtenidos: ${pedidos.length}');
      return pedidos;
    } catch (error) {
      print('❌ [VENTAS] Error al obtener ventas: $error');
      rethrow;
    }
  }

  /// Obtener todos los estados de pedido activos desde ventas.estados_pedido
  Future<List<EstadoPedido>> getEstadosPedido() async {
    try {
      dynamic response;

      try {
        // Intentar con schema explícito
        response = await supabase
            .schema('ventas')
            .from('estados_pedido')
            .select('id, nombre, activo, created_at')
            .eq('activo', true)
            .order('id');
      } catch (e) {
        // Si falla, intentar acceso directo
        print('⚠️ [VENTAS] Intentando acceso directo a estados_pedido...');
        response = await supabase
            .from('estados_pedido')
            .select('id, nombre, activo, created_at')
            .eq('activo', true)
            .order('id');
      }

      final List<dynamic> data = response as List<dynamic>;

      final estados = data
          .map((item) => EstadoPedido.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ [VENTAS] Estados obtenidos: ${estados.length}');
      return estados;
    } catch (error) {
      print('❌ [VENTAS] Error al obtener estados: $error');
      rethrow;
    }
  }

  /// Actualizar el estado de un pedido
  Future<Map<String, dynamic>> actualizarEstadoPedido({
    required int pedidoId,
    required int nuevoEstadoId,
  }) async {
    try {
      // Usar siempre el schema ventas para la tabla pedidos
      final response = await supabase
          .schema('ventas')
          .from('pedidos')
          .update({'estado_id': nuevoEstadoId})
          .eq('id', pedidoId)
          .select();

      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'No se recibió respuesta del servidor',
        };
      }

      print('✅ [VENTAS] Estado del pedido $pedidoId actualizado');
      return {'success': true, 'message': 'Estado actualizado correctamente'};
    } catch (error) {
      print('❌ [VENTAS] Error al actualizar estado: $error');

      // Mensaje de error más descriptivo
      String errorMessage = 'Error al actualizar el estado del pedido.';
      if (error.toString().contains('permission denied') ||
          error.toString().contains('42501')) {
        errorMessage =
            'Error de permisos. Ejecuta estos comandos SQL en Supabase:\n\n'
            'GRANT USAGE ON SCHEMA ventas TO anon, authenticated, service_role;\n'
            'GRANT ALL ON ventas.pedidos TO anon, authenticated, service_role;';
      }

      return {'success': false, 'error': errorMessage};
    }
  }
}
