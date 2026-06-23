import 'package:expense_management/features/ai_assistant/data/di/data_providers.dart';
import 'package:expense_management/features/ai_assistant/data/repository_impl/ai_assistant_repository_impl.dart';
import 'package:expense_management/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  final apiService = ref.watch(aiAssistantApiServiceProvider);
  return AiAssistantRepositoryImpl(apiService);
});
