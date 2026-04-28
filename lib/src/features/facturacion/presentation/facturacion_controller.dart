import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../productos/domain/producto.dart';
import '../../listas_precios/data/listas_precios_repository.dart';
import '../../descuentos/presentation/descuentos_provider.dart';
import '../data/facturacion_repository.dart';
import '../domain/factura_item.dart';
import '../domain/factura_state.dart';

final facturacionControllerProvider =
    StateNotifierProvider<FacturacionController, FacturaState>((ref) {
  final authState = ref.watch(authControllerProvider);
  return FacturacionController(
    FacturacionRepository(Env.apiBaseUrl, authState.token),
    ref,
  );
});

class FacturacionController extends StateNotifier<FacturaState> {
  FacturacionController(this._repository, this._ref) : super(FacturaState());

  final FacturacionRepository _repository;
  final Ref _ref;

  Future<void> agregarProducto(Producto producto) async {
    final items = List<FacturaItem>.from(state.items);

    // Buscar si el producto ya está en la factura
    final index = items.indexWhere((item) => item.producto.id == producto.id);

    if (index >= 0) {
      // Si ya existe, incrementar cantidad
      items[index] = items[index].copyWith(cantidad: items[index].cantidad + 1);
      state = state.copyWith(items: items);
    } else {
      // Obtener el precio correcto según la lista del usuario
      final authState = _ref.read(authControllerProvider);
      final listaPreciosId = authState.listaPreciosId;

      try {
        final preciosRepo = ListasPreciosRepository(Env.apiBaseUrl);
        final precioUnitario = await preciosRepo.getPrecioProductoPorLista(
          productoId: producto.id,
          listaId: listaPreciosId,
        );

        // Agregar el producto con el precio correcto
        items.add(FacturaItem(
          producto: producto,
          cantidad: 1,
          precioUnitario: precioUnitario,
        ));

        state = state.copyWith(items: items);
      } catch (e) {
        // En caso de error, usar el precio del producto como fallback
        items.add(FacturaItem(
          producto: producto,
          cantidad: 1,
          precioUnitario: producto.precio,
        ));
        state = state.copyWith(items: items);
      }
    }
  }

  void removerProducto(int productoId) {
    final items = List<FacturaItem>.from(state.items);
    items.removeWhere((item) => item.producto.id == productoId);
    state = state.copyWith(items: items);
  }

  void actualizarCantidad(int productoId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      removerProducto(productoId);
      return;
    }

    final items = List<FacturaItem>.from(state.items);
    final index = items.indexWhere((item) => item.producto.id == productoId);

    if (index >= 0) {
      items[index] = items[index].copyWith(cantidad: nuevaCantidad);
      state = state.copyWith(items: items);
    }
  }

  void incrementarCantidad(int productoId) {
    final items = List<FacturaItem>.from(state.items);
    final index = items.indexWhere((item) => item.producto.id == productoId);

    if (index >= 0) {
      items[index] = items[index].copyWith(cantidad: items[index].cantidad + 1);
      state = state.copyWith(items: items);
    }
  }

  void decrementarCantidad(int productoId) {
    final items = List<FacturaItem>.from(state.items);
    final index = items.indexWhere((item) => item.producto.id == productoId);

    if (index >= 0) {
      if (items[index].cantidad > 1) {
        items[index] = items[index].copyWith(cantidad: items[index].cantidad - 1);
        state = state.copyWith(items: items);
      } else {
        removerProducto(productoId);
      }
    }
  }

  void limpiarFactura() {
    state = FacturaState();
  }

  Future<Map<String, dynamic>?> guardarFactura() async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'No hay productos en la factura');
      return null;
    }

    // Si no hay cliente seleccionado, usar el cliente con ID 1 por defecto
    final clienteId = state.clienteId ?? 1;

    final authState = _ref.read(authControllerProvider);
    final usuarioId = authState.userId;

    if (usuarioId == null) {
      state = state.copyWith(error: 'Usuario no autenticado');
      return null;
    }

    // Actualizar el estado con el cliente ID antes de guardar
    if (state.clienteId == null) {
      state = state.copyWith(clienteId: clienteId);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Obtener el porcentaje del descuento si hay descuento seleccionado
      double porcentajeDescuento = 0.0;
      if (state.descuentoId != null) {
        final descuentosAsync = _ref.read(descuentosProvider);
        final descuentosValue = descuentosAsync.value;

        if (descuentosValue != null && descuentosValue.isNotEmpty) {
          try {
            final descuento = descuentosValue.firstWhere(
              (d) => d.id == state.descuentoId,
            );
            porcentajeDescuento = descuento.porcentaje;
          } catch (e) {
            print('[FacturacionController] Descuento no encontrado: ${state.descuentoId}');
            // Si no se encuentra el descuento, usar 0.0
          }
        }
      }

      final facturaData = state.toJson(usuarioId, porcentajeDescuento: porcentajeDescuento);
      final response = await _repository.crearFactura(facturaData);

      // Limpiar factura después de guardar exitosamente
      state = FacturaState();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void setCliente(int? clienteId) {
    state = state.copyWith(clienteId: clienteId);
  }

  void setDescuento(int? descuentoId) {
    state = state.copyWith(descuentoId: descuentoId);
  }

  void actualizarComentario(int productoId, String comentario) {
    final items = List<FacturaItem>.from(state.items);
    final index = items.indexWhere((item) => item.producto.id == productoId);

    if (index >= 0) {
      items[index] = items[index].copyWith(comentario: comentario);
      state = state.copyWith(items: items);
    }
  }

  void restaurarFacturaDesdeGuardada(FacturaState facturaState) {
    state = facturaState;
  }
}