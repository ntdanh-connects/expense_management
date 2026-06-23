import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'savings_api_service.g.dart';

@RestApi()
abstract class SavingsApiService {
  factory SavingsApiService(Dio dio) = _SavingsApiService;

  @GET('api/savings')
  Future<dynamic> getSavingsGoals();

  @POST('api/savings')
  Future<dynamic> createSavingsGoal(
    @Body() Map<String, dynamic> body,
  );

  @GET('api/savings/{id}')
  Future<dynamic> getSavingsGoalDetail(
    @Path('id') String id,
  );

  @POST('api/savings/{id}/deposit')
  Future<dynamic> depositSavingsGoal(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('api/savings/{id}/withdraw')
  Future<dynamic> withdrawSavingsGoal(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('api/savings/{id}')
  Future<dynamic> deleteSavingsGoal(
    @Path('id') String id,
  );
}
