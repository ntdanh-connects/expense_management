import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/transaction/data/datasource/remote/transaction_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionApiServiceProvider = Provider<TransactionApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TransactionApiService(dio);
});
