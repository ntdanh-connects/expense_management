import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'ai_assistant_api_service.g.dart';

@RestApi()
abstract class AiAssistantApiService {
  factory AiAssistantApiService(Dio dio) = _AiAssistantApiService;

  @GET('api/ai-conversations')
  Future<dynamic> getConversations();

  @DELETE('api/ai-conversations/{id}')
  Future<dynamic> deleteConversation(@Path('id') String id);

  @PUT('api/ai-conversations/{id}')
  Future<dynamic> renameConversation(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('api/ai-chat')
  Future<dynamic> sendChatMessage(@Body() Map<String, dynamic> body);

  @GET('api/ai-conversations/{id}/messages')
  Future<dynamic> getConversationMessages(@Path('id') String id);
}
