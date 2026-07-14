import 'package:expense_management/features/dashboard/data/models/ai_digest_dto.dart';

abstract class AiDigestRepository {
  Future<AiDigestDto> getAiDigest();
}