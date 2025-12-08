import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/producto.dart';
import '../services/categoria_service.dart';
import '../services/storage_service.dart';
import '../services/producto_registro_service.dart';

class RegistroProductoScreen extends StatefulWidget {
  const RegistroProductoScreen({super.key});

  @override
  State<RegistroProductoScreen> createState() => _RegistroProductoScreenState();
}

class _RegistroProductoScreenState extends State<RegistroProductoScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _codigoProductoController = TextEditingController();
  final _categoriaService = CategoriaService();
  final _storageService = StorageService();
  final _productoRegistroService = ProductoRegistroService();
  
  int _pasoActual = 1;
  bool _guardandoProducto = false;
  final int _totalPasos = 5;
  Categoria? _categoriaSeleccionada;
  List<Categoria> _categorias = [];
  bool _cargandoCategorias = false;
  
  // Paso 3: Cantidad
  int _cantidad = 10;
  final List<int> _opcionesCantidad = [1, 2, 3, 5, 10, 20];
  
  // Paso 4: Costo
  final _costoUnitarioController = TextEditingController(text: '0.00');
  final _precioVentaController = TextEditingController(text: '0.00');
  
  // Paso 5: Foto
  File? _imagenProducto;
  Uint8List? _imagenBytes;
  String? _imagenExtension; // Guardar extensión para web
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (_pasoActual == 2) {
      _cargarCategorias();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _codigoProductoController.dispose();
    _costoUnitarioController.dispose();
    _precioVentaController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _cargandoCategorias = true;
    });

    try {
      final categorias = await _categoriaService.getCategoriasActivas();
      setState(() {
        _categorias = categorias;
        _cargandoCategorias = false;
      });
    } catch (e) {
      setState(() {
        _cargandoCategorias = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }

  Future<void> _continuar() async {
    // Validar paso actual antes de continuar
    if (_pasoActual == 1) {
      // Validar que el nombre no esté vacío
      if (_nombreController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa un nombre')),
        );
        return;
      }
      // Cargar categorías antes de pasar al paso 2
      _cargarCategorias();
    } else if (_pasoActual == 2) {
      // Validar que se haya seleccionado una categoría
      if (_categoriaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una categoría')),
        );
        return;
      }
    } else if (_pasoActual == 3) {
      // Validar que la cantidad sea mayor a 0
      if (_cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una cantidad válida')),
        );
        return;
      }
    } else if (_pasoActual == 4) {
      // Validar que los precios sean válidos
      final costoUnitario = double.tryParse(_costoUnitarioController.text);
      final precioVenta = double.tryParse(_precioVentaController.text);
      
      if (costoUnitario == null || costoUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa un costo unitario válido')),
        );
        return;
      }
      
      if (precioVenta == null || precioVenta <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa un precio de venta válido')),
        );
        return;
      }
    }

    if (_pasoActual < _totalPasos) {
      setState(() {
        _pasoActual++;
        // Cargar categorías si vamos al paso 2
        if (_pasoActual == 2 && _categorias.isEmpty) {
          _cargarCategorias();
        }
      });
    } else {
      // Paso 5: Guardar producto
      await _guardarProducto();
    }
  }

  void _anterior() {
    if (_pasoActual > 1) {
      setState(() {
        _pasoActual--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _pasoActual >= 2 && _pasoActual <= 4 ? Colors.grey[900] : Colors.white,
        foregroundColor: _pasoActual >= 2 && _pasoActual <= 4 ? Colors.white : Colors.black87,
        elevation: 0,
        title: Text(_getTituloPaso()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Paso $_pasoActual/$_totalPasos',
                style: TextStyle(
                  color: _pasoActual >= 2 && _pasoActual <= 5 ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
        bottom: _pasoActual >= 2 && _pasoActual <= 5
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: Container(
                  height: 4,
                  color: Colors.grey[800],
                  child: FractionallySizedBox(
                    widthFactor: _pasoActual / _totalPasos,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContenidoPaso(),
            ),
          ),
          // Botón de acción fijo en la parte inferior
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
              child: Row(
                children: [
                  if (_pasoActual > 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _anterior,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 18),
                            SizedBox(width: 4),
                            Text('Atrás'),
                          ],
                        ),
                      ),
                    ),
                  if (_pasoActual > 1) const SizedBox(width: 16),
                  Expanded(
                    flex: _pasoActual > 1 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _guardandoProducto ? null : _continuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: _guardandoProducto
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_pasoActual == _totalPasos) ...[
                                  const Icon(Icons.check, size: 20),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _pasoActual < _totalPasos ? 'Continuar' : 'Registrar Producto',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_pasoActual < _totalPasos) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoPaso() {
    switch (_pasoActual) {
      case 1:
        return _buildPaso1();
      case 2:
        return _buildPaso2();
      case 3:
        return _buildPaso3();
      case 4:
        return _buildPaso4();
      case 5:
        return _buildPaso5();
      default:
        return _buildPaso1();
    }
  }

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verifica o edita el nombre y descripción',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        // Campo Código de Producto
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Código de Producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codigoProductoController,
              decoration: InputDecoration(
                hintText: 'Ej: PROD-001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Campo Nombre
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                hintText: 'Ej: Sofá Moderno 3 Plazas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Campo Descripción
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe el producto, su estado, características, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona categoría',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Campo Categoría
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _mostrarSelectorCategorias,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _categoriaSeleccionada?.nombre ?? 'Toca para seleccionar',
                        style: TextStyle(
                          color: _categoriaSeleccionada != null
                              ? Colors.black87
                              : Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _mostrarSelectorCategorias() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seleccionar Categoría',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (_cargandoCategorias)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_categorias.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No hay categorías disponibles'),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];
                      final isSelected = _categoriaSeleccionada?.id == categoria.id;
                      
                      return ListTile(
                        title: Text(
                          categoria.nombre ?? 'Sin nombre',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _categoriaSeleccionada = categoria;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaso3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cuántas unidades tienes?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Campo Unidades (display grande)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unidades',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$_cantidad',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Botones de cantidad
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _opcionesCantidad.length,
              itemBuilder: (context, index) {
                final cantidad = _opcionesCantidad[index];
                final isSelected = _cantidad == cantidad;
                
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cantidad = cantidad;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.black : Colors.white,
                    foregroundColor: isSelected ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '$cantidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaso4() {
    const double tasaCambioUSD_HNL = 26.338;
    
    // Calcular conversión a lempiras cuando cambia el costo
    double costoEnDolares = double.tryParse(_costoUnitarioController.text) ?? 0.0;
    double costoEnLempiras = costoEnDolares * tasaCambioUSD_HNL;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio de compra o referencia',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        // Campo Costo unitario (en dólares)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Costo unitario (USD)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _costoUnitarioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {}); // Actualizar conversión cuando cambia el valor
              },
              decoration: InputDecoration(
                prefixText: '\$',
                prefixStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            if (costoEnDolares > 0) ...[
              const SizedBox(height: 4),
              Text(
                '≈ L. ${costoEnLempiras.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        // Campo Precio de venta (en lempiras)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precio de venta (Lempiras)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _precioVentaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {}); // Actualizar margen cuando cambia el precio
              },
              decoration: InputDecoration(
                prefixText: 'L. ',
                prefixStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            // Badge de margen de ganancia bruto
            if (costoEnDolares > 0) ...[
              Builder(
                builder: (context) {
                  final precioVenta = double.tryParse(_precioVentaController.text) ?? 0.0;
                  double margenBruto = 0.0;
                  
                  if (costoEnLempiras > 0 && precioVenta > 0) {
                    margenBruto = ((precioVenta - costoEnLempiras) / costoEnLempiras) * 100;
                  }
                  
                  if (margenBruto > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 18,
                              color: Colors.grey[800],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Margen de ganancia (bruto): ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${margenBruto.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _getTituloPaso() {
    switch (_pasoActual) {
      case 2:
        return 'Categorización';
      case 3:
        return 'Cantidad';
      case 4:
        return 'Costo';
      case 5:
        return 'Resumen';
      default:
        return 'Ingreso de Producto';
    }
  }

  Widget _buildPaso5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de Fotografía
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fotografía del producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(Opcional)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _mostrarOpcionesFoto,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: (_imagenProducto != null || _imagenBytes != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: kIsWeb && _imagenBytes != null
                            ? Image.memory(
                                _imagenBytes!,
                                fit: BoxFit.cover,
                              )
                            : _imagenProducto != null
                                ? Image.file(
                                    _imagenProducto!,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.shrink(),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agregar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_imagenProducto != null || _imagenBytes != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _imagenProducto = null;
                    _imagenBytes = null;
                    _imagenExtension = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar foto'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        // Sección de Resumen
        const Text(
          'Resumen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResumenItem(
                'Producto:',
                _nombreController.text.trim().isNotEmpty
                    ? _nombreController.text.trim()
                    : 'No especificado',
              ),
              const SizedBox(height: 12),
              if (_codigoProductoController.text.trim().isNotEmpty)
                _buildResumenItem(
                  'Código:',
                  _codigoProductoController.text.trim(),
                ),
              if (_codigoProductoController.text.trim().isNotEmpty)
                const SizedBox(height: 12),
              _buildResumenItem(
                'Descripción:',
                _descripcionController.text.trim().isNotEmpty
                    ? (_descripcionController.text.trim().length > 30
                        ? '${_descripcionController.text.trim().substring(0, 30)}...'
                        : _descripcionController.text.trim())
                    : 'No especificada',
              ),
              const SizedBox(height: 12),
              _buildResumenItem(
                'Categoría:',
                _categoriaSeleccionada?.nombre ?? 'No seleccionada',
              ),
              const SizedBox(height: 12),
              _buildResumenItem(
                'Cantidad:',
                '$_cantidad unidades',
              ),
              const SizedBox(height: 12),
              _buildResumenItem(
                'Costo unitario:',
                '\$${_costoUnitarioController.text} USD',
              ),
              const SizedBox(height: 12),
              _buildResumenItem(
                'Precio de venta:',
                'L. ${_precioVentaController.text}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Abrir galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Abrir cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        if (kIsWeb) {
          // En web, leer los bytes directamente
          final bytes = await image.readAsBytes();
          // Obtener extensión del nombre del archivo
          String extension = 'jpg'; // Por defecto
          final fileName = image.name;
          final parts = fileName.split('.');
          if (parts.length > 1) {
            extension = parts.last.toLowerCase();
          }
          setState(() {
            _imagenBytes = bytes;
            _imagenExtension = extension;
            _imagenProducto = null;
          });
        } else {
          // En móvil, usar File
          setState(() {
            _imagenProducto = File(image.path);
            _imagenBytes = null;
            _imagenExtension = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
          ),
        );
      }
    }
  }

  Future<void> _guardarProducto() async {
    if (_guardandoProducto) return;

    setState(() {
      _guardandoProducto = true;
    });

    try {
      String? imagenUrl;

      // Paso 1: Subir imagen si existe
      if (_imagenProducto != null || _imagenBytes != null) {
        try {
          if (kIsWeb && _imagenBytes != null) {
            // En web, usar bytes directamente
            final extension = _imagenExtension ?? 'jpg';
            imagenUrl = await _storageService.uploadImageBytes(_imagenBytes!, extension);
          } else if (_imagenProducto != null) {
            // En móvil, usar File
            imagenUrl = await _storageService.uploadImage(_imagenProducto!);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir imagen: $e'),
                backgroundColor: Colors.grey[800],
              ),
            );
          }
          // Continuar sin imagen si falla la subida
        }
      }

      // Paso 2: Obtener valores numéricos
      final costoUnitario = double.tryParse(_costoUnitarioController.text) ?? 0.0;
      final precioVenta = double.tryParse(_precioVentaController.text) ?? 0.0;

      // Paso 3: Registrar producto con inventario y precio
      final resultado = await _productoRegistroService.registrarProducto(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        codigoProducto: _codigoProductoController.text.trim().isEmpty
            ? null
            : _codigoProductoController.text.trim(),
        categoriaId: _categoriaSeleccionada!.id,
        imagenUrl: imagenUrl,
        cantidad: _cantidad,
        costoUnitario: costoUnitario,
        precioVenta: precioVenta,
      );

      if (mounted) {
        if (resultado['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto registrado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar éxito
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar producto: ${resultado['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardandoProducto = false;
        });
      }
    }
  }
}

