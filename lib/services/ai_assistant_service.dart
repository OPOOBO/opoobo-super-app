import 'package:dio/dio.dart';
import '../core/dio_factory.dart';

class AiChatMessage {
  final String role;
  final String content;

  const AiChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiChatAction {
  final String type;
  final String? moduleName;
  final String? query;
  final String label;

  const AiChatAction({
    required this.type,
    required this.label,
    this.moduleName,
    this.query,
  });

  factory AiChatAction.fromJson(Map<String, dynamic> json) {
    return AiChatAction(
      type: (json['type'] ?? '').toString(),
      moduleName: json['moduleName']?.toString() ?? json['module_name']?.toString(),
      query: json['query']?.toString(),
      label: (json['label'] ?? 'Open').toString(),
    );
  }
}

class AiChatResponse {
  final String reply;
  final List<AiChatAction> actions;

  const AiChatResponse({required this.reply, this.actions = const []});
}

class AiAssistantService {
  final Dio _dio;

  AiAssistantService() : _dio = DioFactory.create();

  Future<AiChatResponse> chat(List<AiChatMessage> messages) async {
    try {
      final res = await _dio.post(
        '/ai/chat',
        data: {'messages': messages.map((m) => m.toJson()).toList()},
      );
      final body = res.data;
      if (body is! Map || body['success'] != true) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: body is Map
              ? (body['message']?.toString() ?? 'Assistant unavailable')
              : 'Assistant unavailable',
        );
      }
      final data = body['data'];
      if (data is! Map) {
        return const AiChatResponse(reply: 'No response from assistant.');
      }
      final actionsRaw = data['actions'];
      final actions = <AiChatAction>[];
      if (actionsRaw is List) {
        for (final item in actionsRaw) {
          if (item is Map) {
            actions.add(
              AiChatAction.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      return AiChatResponse(
        reply: (data['reply'] ?? '').toString(),
        actions: actions,
      );
    } on DioException {
      rethrow;
    } catch (_) {
      throw DioException(
        requestOptions: RequestOptions(path: '/ai/chat'),
        message: 'Could not reach the assistant.',
      );
    }
  }

  Future<ProductScanResult> scanProduct(String filePath) async {
    try {
      final res = await _dio.post(
        '/ai/scan',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(filePath, filename: 'scan.jpg'),
        }),
      );
      final body = res.data;
      if (body is! Map || body['success'] != true || body['data'] is! Map) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: body is Map
              ? (body['message']?.toString() ?? 'Product description is unavailable.')
              : 'Product description is unavailable.',
        );
      }
      return ProductScanResult.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: data['message'].toString(),
        );
      }
      rethrow;
    }
  }
}

class ProductScanResult {
  final String name;
  final String description;
  final String priceNote;

  const ProductScanResult({
    required this.name,
    required this.description,
    required this.priceNote,
  });

  factory ProductScanResult.fromJson(Map<String, dynamic> json) {
    return ProductScanResult(
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priceNote: (json['price_note'] ?? '').toString(),
    );
  }
}
