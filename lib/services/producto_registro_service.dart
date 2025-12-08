import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class ProductoRegistroService {
  final supabase = Supabase.instance.client;
  static const double tasaCambioUSD_HNL = 26.338;

  /// Calcular margen porcentaje
  /// costo: en dólares USD
  /// precioVenta: en lempiras HNL
  double _calcularMargenPorcentaje(double costoUSD, double precioVentaHNL) {
    final costoHNL = costoUSD * tasaCambioUSD_HNL;
    if (costoHNL == 0) return 0;
    return ((precioVentaHNL - costoHNL) / costoHNL) * 100;
  }

  /// Calcular margen absoluto (precio_venta_lempiras - costo_lempiras - IVA del 15%)
  /// costo: en dólares USD
  /// precioVenta: en lempiras HNL
  double _calcularMargenAbsoluto(double costoUSD, double precioVentaHNL) {
    final costoHNL = costoUSD * tasaCambioUSD_HNL;
    final iva = precioVentaHNL * 0.15;
    return precioVentaHNL - costoHNL - iva;
  }

  /// Registrar un nuevo producto con inventario y precio
  Future<Map<String, dynamic>> registrarProducto({
    required String nombre,
    String? descripcion,
    String? codigoProducto,
    required int categoriaId,
    String? imagenUrl,
    required int cantidad,
    required double costoUnitario,
    required double precioVenta,
  }) async {
    int? productoId;
    
    try {
      // PASO 1: Insertar producto y ESPERAR a que se complete
      print('🔄 [PRODUCTO] Iniciando creación de producto...');
      final productoResponse = await supabase.from('productos').insert({
        'nombre': nombre,
        'descripcion': descripcion,
        'numero_codigo_barra': codigoProducto,
        'categoria_id': categoriaId,
        'imagen_url': imagenUrl,
        'activo': true,
      }).select();

      if (productoResponse == null || productoResponse.isEmpty) {
        throw Exception('No se recibió respuesta del servidor al crear el producto');
      }

      // Obtener ID del producto (puede ser int o bigint)
      final productoIdRaw = productoResponse.first['id'];
      productoId = productoIdRaw is int 
          ? productoIdRaw 
          : (productoIdRaw as num).toInt();

      print('✅ [PRODUCTO] Producto creado con ID: $productoId');
      print('⏳ [PRODUCTO] Esperando confirmación antes de continuar...');

      // Esperar un momento para asegurar que el producto esté completamente creado
      await Future.delayed(const Duration(milliseconds: 500));

      // PASO 2: Insertar inventario SOLO DESPUÉS de que el producto esté creado
      print('🔄 [INVENTARIO] Creando inventario para producto $productoId...');
      print('📊 [INVENTARIO] Datos: producto_id=$productoId, stock_actual=$cantidad, stock_minimo=0');
      
      final inventarioResponse = await supabase.from('inventario').insert({
        'producto_id': productoId,
        'stock_actual': cantidad,
        'stock_minimo': 0,
      }).select();

      if (inventarioResponse == null || inventarioResponse.isEmpty) {
        print('❌ [INVENTARIO] No se recibió respuesta al crear inventario');
        throw Exception('Error: No se pudo crear el inventario. Respuesta vacía.');
      }

      print('✅ [INVENTARIO] Inventario creado correctamente: ${inventarioResponse.first}');

      // PASO 3: Calcular márgenes y costo en lempiras
      final margenPorcentaje = _calcularMargenPorcentaje(costoUnitario, precioVenta);
      final margenAbsoluto = _calcularMargenAbsoluto(costoUnitario, precioVenta);
      final costoLempiras = costoUnitario * tasaCambioUSD_HNL;

      // Formatear márgenes a 2 decimales
      final margenPorcentajeFormateado = double.parse(margenPorcentaje.toStringAsFixed(2));
      final margenAbsolutoFormateado = double.parse(margenAbsoluto.toStringAsFixed(2));
      final costoLempirasFormateado = double.parse(costoLempiras.toStringAsFixed(2));

      print('💰 [PRECIOS] Cálculos realizados:');
      print('   - Costo unitario (USD): \$${costoUnitario.toStringAsFixed(2)}');
      print('   - Tasa de cambio: $tasaCambioUSD_HNL');
      print('   - Costo en lempiras: L.${costoLempirasFormateado.toStringAsFixed(2)}');
      print('   - Precio de venta (HNL): L.${precioVenta.toStringAsFixed(2)}');
      print('   - Margen porcentaje: ${margenPorcentajeFormateado.toStringAsFixed(2)}%');
      print('   - Margen absoluto: L.${margenAbsolutoFormateado.toStringAsFixed(2)}');

      // PASO 4: Insertar precio SOLO DESPUÉS de que el inventario esté creado
      print('🔄 [PRECIOS] Creando precio para producto $productoId...');
      print('📊 [PRECIOS] Datos a insertar:');
      print('   - producto_id: $productoId');
      print('   - costo: $costoUnitario (USD)');
      print('   - costo_lempiras: $costoLempirasFormateado (HNL)');
      print('   - precio_venta_lempiras: $precioVenta (HNL)');
      print('   - margen_porcentaje: $margenPorcentajeFormateado');
      print('   - margen_absoluto: $margenAbsolutoFormateado');
      
      final precioResponse = await supabase.from('precios').insert({
        'producto_id': productoId,
        'costo': costoUnitario,
        'costo_lempiras': costoLempirasFormateado,
        'precio_venta_lempiras': precioVenta,
        'margen_porcentaje': margenPorcentajeFormateado,
        'margen_absoluto': margenAbsolutoFormateado,
        'activo': true,
      }).select();

      if (precioResponse == null || precioResponse.isEmpty) {
        print('❌ [PRECIOS] No se recibió respuesta al crear precio');
        throw Exception('Error: No se pudo crear el precio. Respuesta vacía.');
      }

      print('✅ [PRECIOS] Precio creado correctamente: ${precioResponse.first}');
      print('✅✅✅ [PRODUCTO] Proceso completo: Producto $productoId registrado con inventario y precio');

      return {
        'success': true,
        'data': productoResponse.first,
      };
    } catch (e, stackTrace) {
      print('❌❌❌ [PRODUCTO] Error completo al registrar producto:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      if (productoId != null) {
        print('   ⚠️ Producto $productoId fue creado pero puede tener datos incompletos');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

