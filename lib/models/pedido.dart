class Canal {
  final int id;
  final String nombre;
  final String? urlIcono;
  final bool activo;
  final String? createdAt;

  Canal({
    required this.id,
    required this.nombre,
    this.urlIcono,
    required this.activo,
    this.createdAt,
  });

  factory Canal.fromJson(Map<String, dynamic> json) {
    return Canal(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      urlIcono: json['url_icono'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}

class EstadoPedido {
  final int id;
  final String nombre;
  final bool activo;
  final String? createdAt;

  EstadoPedido({
    required this.id,
    required this.nombre,
    required this.activo,
    this.createdAt,
  });

  factory EstadoPedido.fromJson(Map<String, dynamic> json) {
    return EstadoPedido(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ItemPedido {
  final int id;
  final int codigoPedido;
  final int? clienteId;
  final int canalId;
  final int estadoId;
  final String fechaPedido;
  final double total;
  final String? notas;
  final String createdAt;
  final String updatedAt;
  final String? nombreCliente;
  final String? telefonoCliente;
  final double subtotalProductos;
  final double totalComisionesFinanciamiento;
  final double totalFactura;
  final double totalComisionesMetodos;
  final double montoNetoRecibido;
  final double costoEnvio;
  final bool necesitaEnvio;
  final String? direccionCliente;
  final dynamic itemCliente;
  final Canal? itemCanal;
  final EstadoPedido? itemEstado;

  ItemPedido({
    required this.id,
    required this.codigoPedido,
    this.clienteId,
    required this.canalId,
    required this.estadoId,
    required this.fechaPedido,
    required this.total,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.nombreCliente,
    this.telefonoCliente,
    required this.subtotalProductos,
    required this.totalComisionesFinanciamiento,
    required this.totalFactura,
    required this.totalComisionesMetodos,
    required this.montoNetoRecibido,
    required this.costoEnvio,
    required this.necesitaEnvio,
    this.direccionCliente,
    this.itemCliente,
    this.itemCanal,
    this.itemEstado,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    Canal? canal;
    if (json['item_canal'] != null) {
      canal = Canal.fromJson(json['item_canal'] as Map<String, dynamic>);
    }

    EstadoPedido? estado;
    if (json['item_estado'] != null) {
      estado = EstadoPedido.fromJson(json['item_estado'] as Map<String, dynamic>);
    }

    return ItemPedido(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num).toInt(),
      codigoPedido: json['codigo_pedido'] is int 
          ? json['codigo_pedido'] as int 
          : (json['codigo_pedido'] as num).toInt(),
      clienteId: json['cliente_id'] != null
          ? (json['cliente_id'] is int 
              ? json['cliente_id'] as int 
              : (json['cliente_id'] as num).toInt())
          : null,
      canalId: json['canal_id'] is int 
          ? json['canal_id'] as int 
          : (json['canal_id'] as num).toInt(),
      estadoId: json['estado_id'] is int 
          ? json['estado_id'] as int 
          : (json['estado_id'] as num).toInt(),
      fechaPedido: json['fecha_pedido'] as String,
      total: (json['total'] as num).toDouble(),
      notas: json['notas'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      nombreCliente: json['nombre_cliente'] as String?,
      telefonoCliente: json['telefono_cliente'] as String?,
      subtotalProductos: (json['subtotal_productos'] as num).toDouble(),
      totalComisionesFinanciamiento: (json['total_comisiones_financiamiento'] as num).toDouble(),
      totalFactura: (json['total_factura'] as num).toDouble(),
      totalComisionesMetodos: (json['total_comisiones_metodos'] as num).toDouble(),
      montoNetoRecibido: (json['monto_neto_recibido'] as num).toDouble(),
      costoEnvio: (json['costo_envio'] as num).toDouble(),
      necesitaEnvio: json['necesita_envio'] as bool? ?? false,
      direccionCliente: json['direccion_cliente'] as String?,
      itemCliente: json['item_cliente'],
      itemCanal: canal,
      itemEstado: estado,
    );
  }
}

class Pedido {
  final String cliente;
  final String codigoPedido;
  final String canal;
  final String fecha;
  final double total;
  final String estado;
  final ItemPedido item;

  Pedido({
    required this.cliente,
    required this.codigoPedido,
    required this.canal,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.item,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      cliente: json['cliente'] as String? ?? '',
      codigoPedido: json['codigopedido'] as String? ?? '',
      canal: json['canal'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      total: (json['total'] as num).toDouble(),
      estado: json['estado'] as String? ?? '',
      item: ItemPedido.fromJson(json['item'] as Map<String, dynamic>),
    );
  }
}

