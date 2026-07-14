import '../entities/recurring_rule_entity.dart';
import '../repositories/recurring_repository.dart';

class GetRecurringRulesUseCase {
  final RecurringRepository _repository;
  GetRecurringRulesUseCase(this._repository);
  Future<List<RecurringRuleEntity>> execute() => _repository.getRules();
}

class CreateRecurringRuleUseCase {
  final RecurringRepository _repository;
  CreateRecurringRuleUseCase(this._repository);
  Future<RecurringRuleEntity> execute(Map<String, dynamic> data) => _repository.createRule(data);
}

class UpdateRecurringRuleUseCase {
  final RecurringRepository _repository;
  UpdateRecurringRuleUseCase(this._repository);
  Future<RecurringRuleEntity> execute(String id, Map<String, dynamic> data) =>
      _repository.updateRule(id, data);
}

class DeleteRecurringRuleUseCase {
  final RecurringRepository _repository;
  DeleteRecurringRuleUseCase(this._repository);
  Future<void> execute(String id) => _repository.deleteRule(id);
}

class ToggleRecurringRuleUseCase {
  final RecurringRepository _repository;
  ToggleRecurringRuleUseCase(this._repository);
  Future<RecurringRuleEntity> execute(String id) => _repository.toggleRule(id);
}

