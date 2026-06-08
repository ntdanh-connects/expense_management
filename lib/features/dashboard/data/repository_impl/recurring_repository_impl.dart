import 'package:dio/dio.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/dashboard/data/datasource/remote/recurring_api_service.dart';
import 'package:expense_management/features/dashboard/data/mappers/recurring_mapper.dart';
import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringApiService _apiService;

  RecurringRepositoryImpl(this._apiService);

  @override
  Future<List<RecurringRuleEntity>> getRules() async {
    try {
      final response = await _apiService.getRules();
      return response.data.map((dto) => RecurringMapper.toEntity(dto)).toList();
    } on DioException catch (e) {
      AppLogger.error('🚨 [Recurring] getRules error: ${e.message}', tag: 'Recurring');
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<RecurringRuleEntity> createRule(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createRule(data);
      return RecurringMapper.toEntity(response.data);
    } on DioException catch (e) {
      AppLogger.error('[Recurring] createRule error: ${e.message}', tag: 'Recurring');
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<RecurringRuleEntity> updateRule(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateRule(id, data);
      return RecurringMapper.toEntity(response.data);
    } on DioException catch (e) {
      AppLogger.error('🚨 [Recurring] updateRule error: ${e.message}', tag: 'Recurring');
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<void> deleteRule(String id) async {
    try {
      await _apiService.deleteRule(id);
    } on DioException catch (e) {
      AppLogger.error('🚨 [Recurring] deleteRule error: ${e.message}', tag: 'Recurring');
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<RecurringRuleEntity> toggleRule(String id) async {
    try {
      final response = await _apiService.toggleRule(id);
      return RecurringMapper.toEntity(response.data);
    } on DioException catch (e) {
      AppLogger.error('🚨 [Recurring] toggleRule error: ${e.message}', tag: 'Recurring');
      throw AppException(e.toNetworkFailure());
    }
  }
}