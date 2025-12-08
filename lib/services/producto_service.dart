import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class ProductoService {
  final supabase = Supabase.instance.client;

  /// Obtener todos los productos activos con sus relaciones
  Future<List<Producto>> getProductos() async {
    try {
      final response = await supabase
          .from('productos')
          .select('''
            id,
            imagen_url,
            nombre,
            codigo_producto,
            categoria_id,
            descripcion,
            categorias(id, nombre, descripcion),
            inventario(stock_actual, stock_minimo),
            precios(costo, precio_venta_lempiras, margen_porcentaje, margen_absoluto, activo),
            activo
          ''')
          .eq('activo', true);

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      
      // Transformar los datos al formato Producto
      final productos = data
          .map((item) => Producto.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ [PRODUCTOS] Productos obtenidos: ${productos.length}');
      return productos;
    } catch (error) {
      print('❌ [PRODUCTOS] Error al obtener productos: $error');
      rethrow;
    }
  }

  /// Eliminar producto (soft delete - actualizar activo a false)
  Future<Map<String, dynamic>> eliminarProducto(int productoId) async {
    try {
      final response = await supabase
          .from('productos')
          .update({'activo': false})
          .eq('id', productoId)
          .select();

      if (response == null || response.isEmpty) {
        return {
          'success': false,
          'error': 'No se recibió respuesta del servidor',
        };
      }

      print('✅ [PRODUCTOS] Producto $productoId eliminado (soft delete)');
      return {
        'success': true,
        'message': 'Producto eliminado correctamente',
      };
    } catch (error) {
      print('❌ [PRODUCTOS] Error al eliminar producto: $error');
      return {
        'success': false,
        'error': error.toString(),
      };
    }
  }
}

