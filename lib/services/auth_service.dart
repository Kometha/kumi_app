import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final supabase = Supabase.instance.client;
  app_models.User? _currentUser;
  String? _token;

  app_models.User? get currentUser => _currentUser;
  String? get token => _token;

  // Generar hash MD5 de la contraseña
  String _generateMD5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Verificar si una cadena es un hash MD5 (32 caracteres hexadecimales)
  bool _isMD5Hash(String input) {
    return RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(input);
  }

  // Verificar contraseña comparando MD5
  bool _verifyPassword(String password, String passwordHash) {
    String passwordToCompare;

    // Si la contraseña ingresada ya es un hash MD5, usarla directamente
    // Si no, generar el MD5 de la contraseña
    if (_isMD5Hash(password)) {
      passwordToCompare = password;
    } else {
      passwordToCompare = _generateMD5(password);
    }

    return passwordToCompare.toLowerCase() == passwordHash.toLowerCase();
  }

  // Realizar login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // 1. Buscar usuario por username
      final response = await supabase
          .from('usuarios')
          .select('*')
          .eq('username', username)
          .eq('activo', true)
          .maybeSingle();

      // Si no se encuentra el usuario
      if (response == null) {
        return {
          'success': false,
          'error': 'Credenciales inválidas',
          'debug': 'Usuario no encontrado o inactivo',
        };
      }

      final userData = response;

      // 2. Verificar contraseña usando MD5
      final passwordHash = userData['password_hash'] as String?;

      if (passwordHash == null) {
        return {
          'success': false,
          'error': 'Credenciales inválidas',
          'debug': 'password_hash es null en la base de datos',
        };
      }

      // Preparar contraseña para comparación
      String passwordToCompare;
      bool isInputMD5 = _isMD5Hash(password);

      if (isInputMD5) {
        passwordToCompare = password;
      } else {
        passwordToCompare = _generateMD5(password);
      }

      // Comparar contraseñas
      final passwordMatch =
          passwordToCompare.toLowerCase() == passwordHash.toLowerCase();

      if (!passwordMatch) {
        return {
          'success': false,
          'error': 'Credenciales inválidas',
          'debug': {
            'username': username,
            'password_input_length': password.length,
            'password_is_md5': isInputMD5,
            'password_to_compare': passwordToCompare,
            'password_hash_from_db': passwordHash,
            'passwords_match': passwordMatch,
          },
        };
      }

      // 3. Crear objeto User
      app_models.User user;
      try {
        user = app_models.User.fromJson(userData);
      } catch (e, stackTrace) {
        return {
          'success': false,
          'error': 'Error al procesar datos del usuario',
          'debug': {
            'exception': e.toString(),
            'stackTrace': stackTrace.toString(),
            'userData_keys': userData.keys.toList(),
            'userData_id_type': userData['id'].runtimeType.toString(),
            'userData_id_value': userData['id'].toString(),
            'userData_created_at_type': userData['created_at'].runtimeType
                .toString(),
            'userData_created_at_value': userData['created_at'].toString(),
          },
        };
      }

      // 4. Actualizar último login (opcional, si tienes esta columna)
      try {
        await supabase
            .from('usuarios')
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', user.id);
      } catch (e) {
        // Si la columna no existe, ignorar el error
      }

      // 5. Guardar sesión
      _currentUser = user;
      await _saveSession(user);

      return {
        'success': true,
        'user': user,
        'message': 'Sesión iniciada correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al iniciar sesión',
        'debug': 'Excepción: ${e.toString()}',
      };
    }
  }

  // Guardar sesión en SharedPreferences
  Future<void> _saveSession(app_models.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  // Cargar sesión guardada
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = app_models.User.fromJson(userMap);
      }
    } catch (e) {
      _currentUser = null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }

  // Verificar si hay sesión activa
  bool get isLoggedIn => _currentUser != null;
}
