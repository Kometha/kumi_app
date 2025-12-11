import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class CategoriaService {
  final supabase = Supabase.instance.client;

  /// Obtener todas las categorías activas
  Future<List<Categoria>> getCategoriasActivas() async {
    try {
      final response = await supabase
          .from('categorias')
          .select('id, nombre, descripcion')
          .eq('activo', true);

      final List<dynamic> data = response as List<dynamic>;

      // Transformar los datos al formato Categoria
      final categorias = data
          .map((item) => Categoria.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ [CATEGORIAS] Categorías obtenidas: ${categorias.length}');
      return categorias;
    } catch (error) {
      print('❌ [CATEGORIAS] Error al obtener categorías: $error');
      rethrow;
    }
  }
}
