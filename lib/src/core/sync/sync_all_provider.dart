import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/productos/presentation/productos_provider.dart';
import '../../features/categorias/presentation/categorias_provider.dart';
import '../../features/clientes/presentation/clientes_provider.dart';
import '../../features/facturas/presentation/facturas_provider.dart';
import '../../features/listas_precios/presentation/listas_precios_provider.dart';
import '../../features/usuarios/presentation/usuarios_provider.dart' as usuarios_mod;
import '../../features/cargues/presentation/cargues_provider.dart';
import '../../features/descuentos/presentation/descuentos_provider.dart';
import '../../features/equipos/presentation/equipos_provider.dart';

final syncAllProvider = Provider<SyncAllService>((ref) => SyncAllService(ref));

class SyncAllService {
  SyncAllService(this._ref);

  final Ref _ref;

  Future<void> syncAll() async {
    await Future.wait([
      _ref.read(productosRepositoryProvider).syncFromServer(),
      _ref.read(categoriasRepositoryProvider).syncFromServer(),
      _ref.read(clientesRepositoryProvider).syncFromServer(),
      _ref.read(facturasRepositoryProvider).syncFromServer(),
      _ref.read(listasPreciosRepositoryProvider).syncFromServer(),
      _ref.read(usuarios_mod.usuariosRepositoryProvider).syncFromServer(),
      _ref.read(carguesRepositoryProvider).syncFromServer(),
      _ref.read(descuentosRepositoryProvider).syncFromServer(),
      _ref.read(equiposRepositoryProvider).syncFromServer(),
    ]);

    _ref.invalidate(productosProvider);
    _ref.invalidate(categoriasProvider);
    _ref.invalidate(clientesProvider);
    _ref.invalidate(facturasProvider);
    _ref.invalidate(listasPreciosProvider);
    _ref.invalidate(usuarios_mod.usuariosProvider);
    _ref.invalidate(carguesProvider);
    _ref.invalidate(descuentosProvider);
    _ref.invalidate(equiposProvider);
  }
}