import 'package:flutter/material.dart';

/// Diálogo para seleccionar una fecha para filtrar facturas
class SelectorFechasDialog extends StatefulWidget {
  final DateTime? fechaSeleccionada;

  const SelectorFechasDialog({
    super.key,
    this.fechaSeleccionada,
  });

  @override
  State<SelectorFechasDialog> createState() => _SelectorFechasDialogState();
}

class _SelectorFechasDialogState extends State<SelectorFechasDialog> {
  DateTime? _fechaTemp;

  @override
  void initState() {
    super.initState();
    _fechaTemp = widget.fechaSeleccionada;
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));

    return AlertDialog(
      title: const Text('Seleccionar fecha'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opción: Todas las fechas
            ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: _fechaTemp == null
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Todas las fechas'),
              trailing: _fechaTemp == null
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _fechaTemp = null;
                });
              },
              selected: _fechaTemp == null,
            ),
            const Divider(),
            // Opción: Hoy
            ListTile(
              leading: Icon(
                Icons.today,
                color: _esMismaFecha(_fechaTemp, hoy)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Hoy'),
              subtitle: Text(_formatearFecha(hoy)),
              trailing: _esMismaFecha(_fechaTemp, hoy)
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _fechaTemp = hoy;
                });
              },
              selected: _esMismaFecha(_fechaTemp, hoy),
            ),
            // Opción: Ayer
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: _esMismaFecha(_fechaTemp, ayer)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Ayer'),
              subtitle: Text(_formatearFecha(ayer)),
              trailing: _esMismaFecha(_fechaTemp, ayer)
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _fechaTemp = ayer;
                });
              },
              selected: _esMismaFecha(_fechaTemp, ayer),
            ),
            const Divider(),
            // Opción: Seleccionar fecha personalizada
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Seleccionar fecha personalizada'),
              subtitle: _fechaTemp != null &&
                      !_esMismaFecha(_fechaTemp, hoy) &&
                      !_esMismaFecha(_fechaTemp, ayer)
                  ? Text(_formatearFecha(_fechaTemp!))
                  : null,
              trailing: _fechaTemp != null &&
                      !_esMismaFecha(_fechaTemp, hoy) &&
                      !_esMismaFecha(_fechaTemp, ayer)
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () async {
                final fechaSeleccionada = await showDatePicker(
                  context: context,
                  initialDate: _fechaTemp ?? ahora,
                  firstDate: DateTime(2020),
                  lastDate: ahora,
                  locale: const Locale('es', 'ES'),
                );
                if (fechaSeleccionada != null) {
                  setState(() {
                    // Normalizar la fecha a medianoche
                    _fechaTemp = DateTime(
                      fechaSeleccionada.year,
                      fechaSeleccionada.month,
                      fechaSeleccionada.day,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_fechaTemp);
          },
          child: const Text('APLICAR'),
        ),
      ],
    );
  }

  /// Compara si dos fechas son el mismo día
  bool _esMismaFecha(DateTime? fecha1, DateTime fecha2) {
    if (fecha1 == null) return false;
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
  }

  /// Formatea una fecha para mostrar
  String _formatearFecha(DateTime fecha) {
    final meses = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

    return '${dias[fecha.weekday % 7]} ${fecha.day} ${meses[fecha.month]} ${fecha.year}';
  }
}