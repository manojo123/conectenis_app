import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => message;

  static ApiException fromDio(DioException error, {String? fallbackMessage}) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final fieldErrors = _parseFieldErrors(data['errors']);
      final message = _firstFieldMessage(fieldErrors) ??
          data['message'] as String? ??
          fallbackMessage ??
          _defaultMessage(status);

      return ApiException(
        message,
        statusCode: status,
        fieldErrors: fieldErrors,
      );
    }

    final connectionMessage = _connectionMessage(error);
    return ApiException(
      connectionMessage ?? fallbackMessage ?? _defaultMessage(status),
      statusCode: status,
    );
  }

  static String? _connectionMessage(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Não foi possível conectar à API. Verifique se o Laravel Sail está rodando (porta 80) e o endereço em .env.';
    }
    return null;
  }

  static Map<String, List<String>>? _parseFieldErrors(dynamic errors) {
    if (errors is! Map) return null;
    return errors.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((e) => e.toString()).toList()
            : [value.toString()],
      ),
    );
  }

  static String? _firstFieldMessage(Map<String, List<String>>? fieldErrors) {
    if (fieldErrors == null || fieldErrors.isEmpty) return null;
    for (final messages in fieldErrors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }

  static String _defaultMessage(int? status) {
    return switch (status) {
      401 => 'Não autorizado. Faça login novamente.',
      403 => 'Acesso negado.',
      404 => 'Recurso não encontrado.',
      422 => 'Dados inválidos. Verifique os campos.',
      _ => 'Erro de comunicação com o servidor.',
    };
  }
}
