import 'package:flutter/foundation.dart'
    show kIsWeb; // 현재 실행되는 플랫폼을 감지하여 baseUrl을 동적으로 다르게 설정하도록 수정

const bool isProd = true;
// const bool isProd = false;

// 프로덕션 URL
const String _prodUrl = 'https://lyrics-api-608819913525.us-central1.run.app';
// 로컬 URL을 플랫폼별로 정의
const String _localWebUrl = 'http://localhost:8080';
const String _localMobileUrl = 'http://10.0.2.2:8080';

// 앱의 baseUrl을 결정하는 함수
String getBaseUrl() {
  if (isProd) {
    return _prodUrl;
  } else {
    // kIsWeb은 컴파일 타임에 결정되는 상수
    if (kIsWeb) {
      // 현재 플랫폼이 웹(Chrome)이면
      return _localWebUrl;
      // Web 앱은 아직 호스팅 하지 않았으므로 추후 호스팅 시 GCS 버킷에 CORS 정책 적용해야힘
    } else {
      // 현재 플랫폼이 웹이 아니면 (모바일이면)
      return _localMobileUrl;
    }
  }
}

// main.dart에서 사용할 최종 baseUrl
// (const가 아닌 final로 변경. 함수 호출 결과이므로)
final String baseUrl = getBaseUrl();
