import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsuarioViewModel extends ChangeNotifier {
  Map<String, dynamic>? usuario;

  final String baseUrl =
      "https://petcare-backend-three.vercel.app"; // Usa tu IP actual

  Future<String?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return "Los campos no pueden estar vacíos";
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        usuario = json.decode(response.body);
        notifyListeners();
        return null;
      } else {
        return "Email o contraseña incorrectos";
      }
    } catch (e) {
      return "Error al conectar con el servidor";
    }
  }

  Future<String?> crearCuenta(
      String nombre, String email, String password) async {
    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      return "Todos los campos son obligatorios";
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/registrar'),
        headers: {"Content-Type": "application/json"},
        body: json
            .encode({"nombre": nombre, "email": email, "password": password}),
      );
      if (response.statusCode == 201) {
        usuario = json.decode(response.body);
        notifyListeners();
        return null;
      } else {
        return "No se pudo crear la cuenta";
      }
    } catch (e) {
      return "Error al conectar con el servidor";
    }
  }

  void cerrarSesion() {
    usuario = null;
    notifyListeners();
  }

  Future<String?> actualizarPerfil(String nombre, String email) async {
    if (nombre.isEmpty || email.isEmpty) {
      return "Los campos no pueden estar vacíos";
    }
    final userId = usuarioId;
    if (userId == null) return "Usuario no identificado";
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/$userId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"nombre": nombre, "email": email}),
      );
      if (response.statusCode == 200) {
        usuario?['nombre'] = nombre;
        usuario?['email'] = email;
        notifyListeners();
        return null;
      } else {
        final error = json.decode(response.body);
        return error['error'] ?? "Error al actualizar perfil";
      }
    } catch (e) {
      return "Error de conexión";
    }
  }

  // ✅ NUEVO: Guardar token FCM en el backend
  Future<void> guardarTokenFCM(String token) async {
    final userId = usuarioId;
    if (userId == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/usuarios/$userId/fcm-token'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"fcm_token": token}),
      );
    } catch (e) {
      print("Error guardando token FCM: $e");
    }
  }

  // ✅ NUEVO: Método para activar Premium (simula compra)
  Future<String?> comprarPremium() async {
    final userId = usuarioId;
    if (userId == null) return "Usuario no identificado";

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/$userId/premium'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        usuario = json.decode(response.body);
        notifyListeners();
        return null; // Éxito
      } else {
        return "Error al activar premium";
      }
    } catch (e) {
      return "Error de conexión";
    }
  }

  bool get isLoggedIn => usuario != null;
  int? get usuarioId => usuario?['id_usuario'];
  String? get usuarioNombre => usuario?['nombre'];
  String? get usuarioEmail => usuario?['email'];
  bool get esPremium => usuario?['es_premium'] == 1;
}
