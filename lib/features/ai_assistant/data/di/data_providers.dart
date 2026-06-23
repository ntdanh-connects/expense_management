import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/ai_assistant/data/data_source/remote/ai_assistant_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiAssistantApiServiceProvider = Provider<AiAssistantApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AiAssistantApiService(dio);
});
