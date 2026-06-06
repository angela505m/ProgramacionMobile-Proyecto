import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart'; // ✅ IMPORTANTE
import '../model/recordatorio.dart';
import '../services/notification_service.dart';

// ✅ Función top-level que se ejecuta cuando suena la alarma (app cerrada)
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationService notif = NotificationService();
  await notif.init();
  await notif.showNow(
    id: id,
    title: 'Recordatorio de PetCare',
    body: 'Es hora de revisar a tu mascota',
  );
}

class RecordatorioViewModel extends ChangeNotifier {
  final Map<int, List<Recordatorio>> _recordatoriosPorMascota = {};
  final NotificationService _notifications = NotificationService();

  List<Recordatorio> getRecordatorios(int idMascota) {
    return _recordatoriosPorMascota[idMascota] ?? [];
  }

  final String baseUrl = "https://petcare-backend-three.vercel.app";

  Future<bool> _notificacionesGlobalActivadas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificaciones_global') ?? true;
  }

  List<String> _diasStringToList(String dias) {
    final mapDias = {
      'Lunes': 'Monday',
      'Martes': 'Tuesday',
      'Miércoles': 'Wednesday',
      'Jueves': 'Thursday',
      'Viernes': 'Friday',
      'Sábado': 'Saturday',
      'Domingo': 'Sunday',
    };
    final List<String> result = [];
    final partes = dias.split(',');
    for (var p in partes) {
      if (mapDias.containsKey(p)) {
        result.add(mapDias[p]!);
      }
    }
    return result;
  }

  String _weekdayToString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Programar alarma nativa (funciona con app cerrada)
  Future<void> _scheduleRecordatorio(Recordatorio r) async {
    if (!(await _notificacionesGlobalActivadas())) return;
    if (!r.activo) return;

    await AndroidAlarmManager.cancel(r.id);

    final horaParts = r.hora.split(':');
    final targetHour = int.parse(horaParts[0]);
    final targetMinute = int.parse(horaParts[1]);

    final diasList = _diasStringToList(r.dias);
    if (diasList.isEmpty) return;

    final now = DateTime.now();
    DateTime? targetDate;

    for (int i = 0; i <= 7; i++) {
      final testDate = now.add(Duration(days: i));
      final weekdayName = _weekdayToString(testDate.weekday);
      if (diasList.contains(weekdayName)) {
        targetDate = DateTime(
          testDate.year,
          testDate.month,
          testDate.day,
          targetHour,
          targetMinute,
        );
        if (targetDate.isAfter(now)) break;
      }
    }

    if (targetDate == null) return;
    final DateTime fechaProgramada = targetDate;
    final Duration delay = fechaProgramada.difference(DateTime.now());
    if (delay <= Duration.zero) return;

    await AndroidAlarmManager.oneShot(
      delay,
      r.id,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> _cancelRecordatorio(int id) async {
    await AndroidAlarmManager.cancel(id);
    await _notifications.cancel(id);
  }

  Future<void> actualizarEstadoGlobal() async {
    final globalActivo = await _notificacionesGlobalActivadas();
    if (!globalActivo) {
      for (var lista in _recordatoriosPorMascota.values) {
        for (var r in lista) {
          await AndroidAlarmManager.cancel(r.id);
          await _notifications.cancel(r.id);
        }
      }
    } else {
      for (var lista in _recordatoriosPorMascota.values) {
        for (var r in lista) {
          if (r.activo) await _scheduleRecordatorio(r);
        }
      }
    }
    notifyListeners();
  }

  // ========== MÉTODOS DE CARGA Y CRUD (sin cambios) ==========
  Future<void> cargarRecordatoriosPorMascota(int idMascota) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/recordatorios?mascota=$idMascota'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final recordatorios =
            data.map((json) => Recordatorio.fromJson(json)).toList();
        _recordatoriosPorMascota[idMascota] = recordatorios;
        for (var r in recordatorios) {
          if (r.activo) await _scheduleRecordatorio(r);
        }
        notifyListeners();
      } else {
        _recordatoriosPorMascota[idMascota] = [];
        notifyListeners();
      }
    } catch (e) {
      _recordatoriosPorMascota[idMascota] = [];
      notifyListeners();
    }
  }

  Future<void> agregarRecordatorio(
      int idMascota, String tipo, String hora, String dias) async {
    final recordatorio = {
      'id_mascota': idMascota,
      'tipo': tipo,
      'hora': hora,
      'dias': dias,
      'activo': true,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/recordatorios'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(recordatorio),
    );
    if (response.statusCode == 201) {
      final nuevo = Recordatorio.fromJson(json.decode(response.body));
      final lista = _recordatoriosPorMascota[idMascota] ?? [];
      lista.add(nuevo);
      _recordatoriosPorMascota[idMascota] = lista;
      await _scheduleRecordatorio(nuevo);
      notifyListeners();
    }
  }

  Future<void> toggleRecordatorio(
      int idMascota, int idRecordatorio, bool activo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/recordatorios/$idRecordatorio'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'activo': activo}),
    );
    if (response.statusCode == 200) {
      final lista = _recordatoriosPorMascota[idMascota];
      if (lista != null) {
        final index = lista.indexWhere((r) => r.id == idRecordatorio);
        if (index != -1) {
          lista[index].activo = activo;
          _recordatoriosPorMascota[idMascota] = lista;
          if (activo)
            await _scheduleRecordatorio(lista[index]);
          else
            await _cancelRecordatorio(idRecordatorio);
          notifyListeners();
        }
      }
    }
  }

  Future<void> actualizarRecordatorio(int idMascota, int idRecordatorio,
      String tipo, String hora, String dias, bool activo) async {
    final recordatorio = {
      'tipo': tipo,
      'hora': hora,
      'dias': dias,
      'activo': activo,
    };
    final response = await http.put(
      Uri.parse('$baseUrl/recordatorios/$idRecordatorio'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(recordatorio),
    );
    if (response.statusCode == 200) {
      final actualizado = Recordatorio.fromJson(json.decode(response.body));
      final lista = _recordatoriosPorMascota[idMascota];
      if (lista != null) {
        final index = lista.indexWhere((r) => r.id == idRecordatorio);
        if (index != -1) {
          lista[index] = actualizado;
          _recordatoriosPorMascota[idMascota] = lista;
          await _cancelRecordatorio(idRecordatorio);
          if (activo) await _scheduleRecordatorio(actualizado);
          notifyListeners();
        }
      }
    } else {
      throw Exception("No se pudo actualizar el recordatorio");
    }
  }

  Future<void> eliminarRecordatorio(int idMascota, int idRecordatorio) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/recordatorios/$idRecordatorio'));
    if (response.statusCode == 200) {
      final lista = _recordatoriosPorMascota[idMascota];
      if (lista != null) {
        lista.removeWhere((r) => r.id == idRecordatorio);
        _recordatoriosPorMascota[idMascota] = lista;
        await _cancelRecordatorio(idRecordatorio);
        notifyListeners();
      }
    }
  }

  void limpiarRecordatorios() {
    for (var lista in _recordatoriosPorMascota.values) {
      for (var r in lista) {
        AndroidAlarmManager.cancel(r.id);
        _notifications.cancel(r.id);
      }
    }
    _recordatoriosPorMascota.clear();
    notifyListeners();
  }
}
