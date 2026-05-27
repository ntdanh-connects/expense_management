// import 'package:dio/dio.dart';
// import 'package:expense_management/core/error/app_exception.dart';
// import 'package:expense_management/core/network/network_exception_mapper.dart';
// import 'package:expense_management/features/auth/data/mappers/auth_mapper.dart';
// import '../../domain/repositories/user_repository.dart';
// import '../datasource/remote/user_api_service.dart';
// import 'package:expense_management/features/auth/domain/entities/user_entity.dart';

// class UserRepositoryImpl implements UserRepository {
//   final UserApiService _userApiService;

//   UserRepositoryImpl(this._userApiService);

//   @override
//   Future<UserEntity> updateProfile({required String fullName}) async {
//     try {
//       // 1. Gọi API cập nhật dữ liệu phía Backend
//       final responseDto = await _userApiService.updateProfile(fullName);
      
//       // 2. Chuyển đổi DTO nhận được thành UserEntity sạch thông qua Mapper có sẵn của bạn
//       return AuthMapper.toUserEntity(responseDto.data);
//     } on DioException catch (e) {
//       throw AppException(e.toNetworkFailure());
//     }
//   }
// }

import 'package:expense_management/features/auth/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/user_repository.dart';

class MockUserRepositoryImpl implements UserRepository {
  final Ref _ref;

  MockUserRepositoryImpl(this._ref);

  @override
  Future<UserEntity> updateProfile({required String fullName}) async {
    // 1. Giả lập độ trễ mạng mất 1.5 giây để UI hiện trạng thái Loading xoay tròn
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Lấy thông tin User hiện tại đang lưu trong AuthNotifier
    final authState = _ref.read(authNotifierProvider);
    
    UserEntity? currentUser;
    authState.maybeWhen(
      authenticated: (user) => currentUser = user,
      orElse: () => null,
    );

    if (currentUser == null) {
      throw Exception("Không tìm thấy thông tin người dùng hiện tại để cập nhật.");
    }

    // 3. Sử dụng hàm copyWith từ Freezed để tạo ra đối tượng UserEntity mới với tên vừa sửa
    final updatedUser = currentUser!.copyWith(fullName: fullName);

    return updatedUser;
  }
}