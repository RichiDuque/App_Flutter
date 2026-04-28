import 'package:flutter/foundation.dart';

@immutable
class CarguesFilters {
  final String? usuariosIds;
  final String? fechaInicio;
  final String? fechaFin;

  const CarguesFilters({
    this.usuariosIds,
    this.fechaInicio,
    this.fechaFin,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarguesFilters &&
        other.usuariosIds == usuariosIds &&
        other.fechaInicio == fechaInicio &&
        other.fechaFin == fechaFin;
  }

  @override
  int get hashCode => Object.hash(usuariosIds, fechaInicio, fechaFin);
}