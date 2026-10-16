const categorias = {
  'bienestar': 'Bienestar',
  'organizacion': 'Organización',
  'aprendizaje': 'Aprendizaje',
};
const frecuencias = {'diaria': 'Diaria', 'semanal': 'Semanal'};
const tipos = {'habito': 'Hábito', 'tarea': 'Tarea'};

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException();
  return value;
}

String jsonText(Map<String, dynamic> json, String key, int min, int max) {
  final value = json[key];
  if (value is! String || value.trim().length < min || value.length > max) {
    throw const FormatException();
  }
  return value;
}

int jsonId(Object? value) {
  if (value is! int || value < 1) throw const FormatException();
  return value;
}

String jsonEnum(
  Map<String, dynamic> json,
  String key,
  Map<String, String> values,
) {
  final value = json[key];
  if (value is! String || !values.containsKey(value)) {
    throw const FormatException();
  }
  return value;
}

void exactKeys(Map<String, dynamic> json, Set<String> keys) {
  if (json.length != keys.length || !keys.containsAll(json.keys)) {
    throw const FormatException();
  }
}

class Usuario {
  const Usuario(this.id, this.email);
  final int id;
  final String email;

  factory Usuario.fromJson(Object? value) {
    final json = jsonObject(value);
    return Usuario(jsonId(json['id']), jsonText(json, 'email', 3, 254));
  }
}

class Acceso {
  const Acceso(this.token, this.usuario);
  final String token;
  final Usuario usuario;

  factory Acceso.fromJson(Object? value) {
    final json = jsonObject(value);
    if (json['token_type'] != 'bearer' ||
        json['expires_in'] is! int ||
        (json['expires_in'] as int) <= 0) {
      throw const FormatException();
    }
    return Acceso(
      jsonText(json, 'access_token', 1, 16384),
      Usuario.fromJson(json['user']),
    );
  }
}

class HabitoDraft {
  const HabitoDraft({
    required this.titulo,
    this.descripcion = '',
    this.categoria = 'bienestar',
    this.frecuencia = 'diaria',
    this.tipo = 'habito',
    this.completado = false,
    this.plantillaId,
  });

  final String titulo, descripcion, categoria, frecuencia, tipo;
  final bool completado;
  final int? plantillaId;

  factory HabitoDraft.fromJson(Map<String, dynamic> json) => HabitoDraft(
    titulo: jsonText(json, 'titulo', 1, 100),
    descripcion: jsonText(json, 'descripcion', 0, 500),
    categoria: jsonEnum(json, 'categoria', categorias),
    frecuencia: jsonEnum(json, 'frecuencia', frecuencias),
    tipo: jsonEnum(json, 'tipo', tipos),
    plantillaId: json['plantilla_id'] == null
        ? null
        : jsonId(json['plantilla_id']),
    completado: switch (json['completado']) {
      null => false,
      bool v => v,
      _ => throw const FormatException(),
    },
  );

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'categoria': categoria,
    'frecuencia': frecuencia,
    'tipo': tipo,
    'completado': completado,
    if (plantillaId != null) 'plantilla_id': plantillaId,
  };
}

class Plantilla {
  const Plantilla(this.id, this.datos);
  final int id;
  final HabitoDraft datos;

  factory Plantilla.fromJson(Object? value) {
    final json = jsonObject(value);
    jsonText(json, 'descripcion', 1, 500);
    final id = jsonId(json['id']);
    return Plantilla(id, HabitoDraft.fromJson({...json, 'plantilla_id': id}));
  }
}

class Habito {
  const Habito(this.id, this.datos);
  final int id;
  final HabitoDraft datos;

  factory Habito.fromJson(Object? value) {
    final json = jsonObject(value);
    if (json['completado'] is! bool) throw const FormatException();
    return Habito(jsonId(json['id']), HabitoDraft.fromJson(json));
  }
}

class RespuestaAsistente {
  const RespuestaAsistente(this.mensaje, [this.propuesta]);
  final String mensaje;
  final HabitoDraft? propuesta;

  factory RespuestaAsistente.fromJson(Object? value) {
    final json = jsonObject(value);
    final mensaje = jsonText(json, 'mensaje', 1, 2000);
    switch (json['tipo']) {
      case 'consejo':
        exactKeys(json, {'tipo', 'mensaje'});
        return RespuestaAsistente(mensaje);
      case 'propuesta':
        exactKeys(json, {'tipo', 'mensaje', 'habito'});
        final habito = jsonObject(json['habito']);
        exactKeys(habito, {
          'titulo',
          'descripcion',
          'categoria',
          'frecuencia',
          'tipo',
        });
        return RespuestaAsistente(mensaje, HabitoDraft.fromJson(habito));
      default:
        throw const FormatException();
    }
  }
}
