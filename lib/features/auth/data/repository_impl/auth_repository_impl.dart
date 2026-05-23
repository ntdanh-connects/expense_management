

import 'package:dio/dio.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:expense_management/features/auth/data/datasource/remote/auth_api_service.dart';
import 'package:expense_management/features/auth/data/mappers/auth_mapper.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart';
import 'package:expense_management/features/auth/data/models/login_request_dto.dart';
import 'package:expense_management/features/auth/data/models/register_request_dto.dart';
import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import 'package:expense_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepositoryImpl implements AuthRepository{
  final AuthApiService _authApiService;
  final SecureStorageService _secureStorageService;

  AuthRepositoryImpl(this._authApiService,this._secureStorageService);

  @override
  Future<UserEntity> loginWithEmailPassword(String email, String password) async{
    try{
      final requestParams = LoginRequestDto(email: email, password: password);

    final dto = await _authApiService.login(requestParams);

    await _secureStorageService.save(key: AppConstant.accessToken, value: dto.accessToken);
    await _secureStorageService.save(key: AppConstant.refreshToken, value: dto.refreshToken);

    return AuthMapper.toUserEntity(dto.data);
    }on DioException catch(e){
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<dynamic> registerWithEmail(String fullName, String email, String password) async{
    try{
    final requestParams = RegisterRequestDto(fullName: fullName, email: email, password: password,passwordConfirmation: password);
    final response = await _authApiService.register(requestParams);
    return response.message;
    }on DioException catch (e){
      throw AppException(e.toNetworkFailure());
    }
  }

}