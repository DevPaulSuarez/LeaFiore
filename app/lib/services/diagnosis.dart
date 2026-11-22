import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Diagnóstico de plantas por foto con Claude (visión).
/// Dart no tiene SDK oficial de Anthropic, así que se usa la API HTTP directamente.
class DiagnosisService {
  static const _model = 'claude-opus-5-5';
  static final _url = Uri.parse('https://api.anthropic.com/v1/messages');

  static const _system =
      'Eres un fitopatólogo y jardinero experto que ayuda a personas sin experiencia a cuidar sus plantas.\n'
      'Analiza la foto (puede ser la planta entera, una hoja o un insecto) y da un diagnóstico claro en español.\n'
      'Si ves un insecto, identifícalo y di si es plaga o beneficioso (p. ej. mariquita).\n'
      'Prioriza tratamientos caseros y seguros (jabón potásico, aceite de neem, aislar la planta, ajustar riego/luz) antes que químicos.\n'
      'Si la foto no es clara, dilo en la descripción, baja la confianza y sugiere qué foto tomar.';

  static const _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': [
      'is_plant', 'plant_guess', 'subject', 'status', 'problem', 'confidence', 'severity',
      'description', 'causes', 'treatment', 'prevention', 'water_advice',
    ],
    'properties': {
      'is_plant': {'type': 'boolean', 'description': 'false si la foto no muestra una planta ni un insecto en una planta'},
      'plant_guess': {'type': 'string', 'description': 'Nombre común en español de la planta, o "Desconocida"'},
      'subject': {'type': 'string', 'enum': ['planta_completa', 'hoja', 'insecto', 'raiz', 'otro']},
      'status': {'type': 'string', 'enum': ['sana', 'atencion', 'enferma']},
      'problem': {'type': 'string', 'description': 'Nombre corto del problema, plaga o enfermedad. "Sin problemas" si está sana.'},
      'confidence': {'type': 'integer', 'description': '0 a 100'},
      'severity': {'type': 'string', 'enum': ['ninguna', 'leve', 'moderada', 'grave']},
      'description': {'type': 'string', 'description': 'Qué se ve en la foto, 1–3 frases'},
      'causes': {'type': 'array', 'items': {'type': 'string'}},
      'treatment': {'type': 'array', 'items': {'type': 'string'}, 'description': 'Pasos concretos y ordenados'},
      'prevention': {'type': 'array', 'items': {'type': 'string'}},
      'water_advice': {'type': 'string', 'description': 'Recomendación de riego para esta planta'},
    },
  };

  static Future<Diagnosis> diagnose({
    required String apiKey,
    required List<int> jpegBytes,
    required ScanMode mode,
    String? plantName,
  }) async {
    final modeText = switch (mode) {
      ScanMode.planta => 'La foto muestra la planta completa. Evalúa su salud general.',
      ScanMode.hoja => 'La foto muestra una o varias hojas de cerca. Busca manchas, hongos, deficiencias o daños.',
      ScanMode.insecto => 'La foto muestra un insecto o plaga. Identifícalo y explica cómo tratarlo.',
    };

    final body = {
      'model': _model,
      'max_tokens': 16000,
      'fallbacks': 'default',
      'output_config': {
        'effort': 'medium',
        'format': {'type': 'json_schema', 'schema': _schema},
      },
      'system': _system,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': base64Encode(jpegBytes)},
            },
            {'type': 'text', 'text': '$modeText${plantName != null ? ' La planta es: $plantName.' : ''}'},
          ],
        },
      ],
    };

    final res = await http
        .post(
          _url,
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2026-10-21',
            'anthropic-beta': 'server-side-fallback-2026-07-01',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(minutes: 3));

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      if (res.statusCode == 401) throw DiagnosisException('Clave de API no válida. Revísala en Perfil.');
      if (res.statusCode == 429) throw DiagnosisException('Demasiadas peticiones. Espera un momento.');
      if (res.statusCode >= 500) throw DiagnosisException('El servicio no está disponible. Inténtalo más tarde.');
      throw DiagnosisException(json['error']?['message'] ?? 'Error ${res.statusCode}');
    }

    final stop = json['stop_reason'];
    if (stop == 'refusal') throw DiagnosisException('No se pudo analizar esta foto. Prueba con otra imagen.');
    if (stop == 'max_tokens') throw DiagnosisException('La respuesta quedó incompleta. Inténtalo de nuevo.');

    final text = (json['content'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((b) => b['type'] == 'text', orElse: () => {})['text'] as String?;
    if (text == null) throw DiagnosisException('Respuesta vacía del servicio.');
    return Diagnosis.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Resultado de ejemplo para probar la app sin clave de API.
  static Diagnosis demo(ScanMode mode) {
    if (mode == ScanMode.insecto) {
      return const Diagnosis(
        isPlant: true, plantGuess: 'Desconocida', status: HealthStatus.atencion,
        problem: 'Cochinilla algodonosa', confidence: 82, severity: 'moderada',
        description: 'Se observan pequeñas masas blancas algodonosas en las axilas de las hojas. (Resultado de demostración)',
        causes: ['Ambiente cálido y seco', 'Planta nueva traída sin cuarentena', 'Exceso de abono nitrogenado'],
        treatment: [
          'Aísla la planta de las demás',
          'Retira las cochinillas con un bastoncillo con alcohol de 70°',
          'Pulveriza jabón potásico (5 ml/L) cada 5–7 días durante 3 semanas',
          'Revisa el envés y las raíces',
        ],
        prevention: ['Revisa las hojas cada semana', 'Pon en cuarentena las plantas nuevas 2 semanas'],
        waterAdvice: 'Mantén el riego habitual; no la pulverices con agua sola mientras tenga plaga.',
      );
    }
    return const Diagnosis(
      isPlant: true, plantGuess: 'Monstera', status: HealthStatus.atencion,
      problem: 'Exceso de riego', confidence: 74, severity: 'leve',
      description: 'Algunas hojas inferiores amarillean con bordes blandos, típico de raíces con demasiada humedad. (Resultado de demostración)',
      causes: ['Riego demasiado frecuente', 'Maceta sin drenaje', 'Poca luz que reduce el consumo de agua'],
      treatment: [
        'Deja secar los 5 cm superiores del sustrato antes de volver a regar',
        'Retira las hojas totalmente amarillas',
        'Comprueba que la maceta drena y vacía el plato',
        'Acércala a una ventana con luz indirecta',
      ],
      prevention: ['Usa el dedo para comprobar la humedad antes de regar', 'Riega menos en invierno'],
      waterAdvice: 'Riega cada 8–10 días, solo cuando el sustrato esté seco en la superficie.',
    );
  }
}

class DiagnosisException implements Exception {
  final String message;
  DiagnosisException(this.message);
  @override
  String toString() => message;
}
