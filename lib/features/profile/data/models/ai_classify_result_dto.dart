import 'package:json_annotation/json_annotation.dart';

part 'ai_classify_result_dto.g.dart';

@JsonSerializable()
class AiClassifyResultDto {
  @JsonKey(name: 'category_id')
  final String? categoryId;

  AiClassifyResultDto({
    this.categoryId,
  });

  factory AiClassifyResultDto.fromJson(Map<String, dynamic> json) => _$AiClassifyResultDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AiClassifyResultDtoToJson(this);
}
