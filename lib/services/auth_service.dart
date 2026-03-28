class AuthService {
  static String? accessToken;

  static void setToken(String token) {
    accessToken = token;
  }

  static String? getToken() {
    return accessToken;
  }

  static void logout() {
    accessToken = null;
  }
}