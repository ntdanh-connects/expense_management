import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:expense_management/core/utils/app_logger.dart';

class SocialAuthService {
  /// Thực hiện đăng nhập Google bằng GoogleSignIn SDK và trả về ID Token
  static Future<String> signInWithGoogle() async {
    AppLogger.info("🌐 [Google-Auth] Bắt đầu kích hoạt Google SDK...", tag: "OAuth");
    await GoogleSignIn.instance.initialize();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception("Không lấy được ID Token từ Google SDK.");
    }
    return idToken;
  }

  /// Thực hiện đăng nhập GitHub bằng FlutterWebAuth2 và trả về authorization code
  static Future<String> signInWithGitHub() async {
    AppLogger.info("🌐 [GitHub-Auth] Bắt đầu kích hoạt GitHub Web Auth...", tag: "OAuth");
    const clientId = "Ov23li1qcJFgeObxfdNl"; 
    const redirectUri = "expmgmt://auth";
    const authUrl = "https://github.com/login/oauth/authorize?client_id=$clientId&scope=user:email&redirect_uri=$redirectUri";
    
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: "expmgmt",
    );
    
    final Uri uri = Uri.parse(result);
    final code = uri.queryParameters['code'];
    
    if (code == null) {
      throw Exception("Không tìm thấy authorization code từ GitHub callback.");
    }
    return code;
  }
}
