class HttpMiddleware {
  HttpMiddleware({String? Function()? tokenProvider})
    : _tokenProvider = tokenProvider;

  final String? Function()? _tokenProvider;

  Map<String, String> apply({Map<String, String>? headers}) {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      mergedHeaders['Authorization'] = 'Bearer $token';
    }

    return mergedHeaders;
  }
}
