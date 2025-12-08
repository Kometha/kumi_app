class Categoria {
  final int id;
  final String? nombre;
  final String? descripcion;

  Categoria({
    required this.id,
    this.nombre,
    this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num).toInt(),
      nombre: json['nombre'] as String?,
      descripcion: json['descripcion'] as String?,
    );
  }
}

class Inventario {
  final int? stockActual;
  final int? stockMinimo;

  Inventario({
    this.stockActual,
    this.stockMinimo,
  });

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      stockActual: json['stock_actual'] != null 
          ? (json['stock_actual'] is int 
              ? json['stock_actual'] as int 
              : (json['stock_actual'] as num).toInt())
          : null,
      stockMinimo: json['stock_minimo'] != null
          ? (json['stock_minimo'] is int 
              ? json['stock_minimo'] as int 
              : (json['stock_minimo'] as num).toInt())
          : null,
    );
  }
}

class Precio {
  final double costo;
  final double precioVenta;
  final double margenPorcentaje;
  final double margenAbsoluto;
  final bool activo;

  Precio({
    required this.costo,
    required this.precioVenta,
    required this.margenPorcentaje,
    required this.margenAbsoluto,
    required this.activo,
  });

  factory Precio.fromJson(Map<String, dynamic> json) {
    return Precio(
      costo: (json['costo'] as num).toDouble(),
      precioVenta: (json['precio_venta_lempiras'] as num).toDouble(),
      margenPorcentaje: (json['margen_porcentaje'] as num).toDouble(),
      margenAbsoluto: (json['margen_absoluto'] as num).toDouble(),
      activo: json['activo'] as bool? ?? true,
    );
  }
}

class Producto {
  final int id;
  final String? codigoProducto;
  final String? nombre;
  final String? descripcion;
  final String? imagenUrl;
  final Categoria? categoria;
  final Inventario? inventario;
  final Precio? precio;
  final bool activo;

  Producto({
    required this.id,
    this.codigoProducto,
    this.nombre,
    this.descripcion,
    this.imagenUrl,
    this.categoria,
    this.inventario,
    this.precio,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    // Manejar categoría que puede venir como objeto o null
    Categoria? categoria;
    if (json['categorias'] != null) {
      if (json['categorias'] is List && (json['categorias'] as List).isNotEmpty) {
        categoria = Categoria.fromJson((json['categorias'] as List).first);
      } else if (json['categorias'] is Map) {
        categoria = Categoria.fromJson(json['categorias'] as Map<String, dynamic>);
      }
    }

    // Manejar inventario que puede venir como lista o objeto
    Inventario? inventario;
    if (json['inventario'] != null) {
      if (json['inventario'] is List && (json['inventario'] as List).isNotEmpty) {
        inventario = Inventario.fromJson((json['inventario'] as List).first);
      } else if (json['inventario'] is Map) {
        inventario = Inventario.fromJson(json['inventario'] as Map<String, dynamic>);
      }
    }

    // Manejar precios - filtrar solo los activos
    Precio? precio;
    if (json['precios'] != null) {
      List<dynamic> preciosList = [];
      if (json['precios'] is List) {
        preciosList = json['precios'] as List;
      } else if (json['precios'] is Map) {
        preciosList = [json['precios']];
      }
      
      // Filtrar solo precios activos
      final preciosActivos = preciosList
          .where((p) => p['activo'] == true)
          .toList();
      
      if (preciosActivos.isNotEmpty) {
        precio = Precio.fromJson(preciosActivos.first);
      }
    }

    return Producto(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num).toInt(),
      codigoProducto: json['codigo_producto'] as String?,
      nombre: json['nombre'] as String?,
      descripcion: json['descripcion'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      categoria: categoria,
      inventario: inventario,
      precio: precio,
      activo: json['activo'] as bool? ?? true,
    );
  }
}

