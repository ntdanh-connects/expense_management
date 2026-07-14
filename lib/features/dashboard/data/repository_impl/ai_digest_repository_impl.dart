import 'package:expense_management/features/dashboard/data/datasource/remote/dashboard_api_service.dart';
import 'package:expense_management/features/dashboard/data/models/ai_digest_dto.dart';
import 'package:expense_management/features/dashboard/domain/repositories/ai_digest_repository.dart';

class AiDigestRepositoryImpl implements AiDigestRepository{
  final DashboardApiService _apiService;
  AiDigestRepositoryImpl(
    this._apiService
  );

  @override
  Future<AiDigestDto> getAiDigest() async{
    final response = await _apiService.getAiDigest();
    return response.data;
  }
}