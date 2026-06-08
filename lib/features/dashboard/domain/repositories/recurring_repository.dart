import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';

abstract class RecurringRepository {
  Future<List<RecurringRuleEntity>> getRules();
  Future<RecurringRuleEntity> createRule(Map<String, dynamic> data);
  Future<RecurringRuleEntity> updateRule(String id, Map<String, dynamic> data);
  Future<void> deleteRule(String id);
  Future<RecurringRuleEntity> toggleRule(String id);
}