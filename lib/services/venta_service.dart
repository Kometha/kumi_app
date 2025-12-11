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
        response = await supabase
            .from('vw_pedidos')
            .select('*');
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
}

