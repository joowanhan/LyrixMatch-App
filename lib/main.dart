// main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'result_page.dart';
import 'quiz_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LyrixMatch",
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/result': (context) => const ResultPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _status;

  Future<void> startQuizFlow() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _status = "URL을 입력하세요.");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "🎵 가사 수집 요청 중...";
    });

    String? docId;

    // 1. /crawl
    try {
      final crawlRes = await http.post(
        Uri.parse("$baseUrl/crawl"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"playlist_url": url}),
      );

      // utf8.decode를 사용하여 한글 깨짐 방지
      final body = utf8.decode(crawlRes.bodyBytes);

      if (crawlRes.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _status = "🧨 /crawl 실패: $body";
        });
        return;
      }

      // 서버로부터 Firestore Document ID 추출
      docId = jsonDecode(body)['doc_id'];
      if (docId == null || docId.isEmpty) {
        throw Exception("doc_id를 받지 못했습니다.");
      }

      setState(() => _status = "🔍 요약/분석 중... (ID: $docId)");
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = "🧨 /crawl 요청 오류: $e";
      });
      return;
    }

    // 2. /quizdata (doc_id 파라미터 추가)
    try {
      final quizRes = await http.get(
        // doc_id를 경로(Path) 파라미터로 전송
        Uri.parse("$baseUrl/quizdata/$docId"),
      );

      final body = utf8.decode(quizRes.bodyBytes);

      if (quizRes.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _status = "🧨 /quizdata 실패: $body";
        });
        return;
      }

      final quizData = List<Map<String, dynamic>>.from(jsonDecode(body));

      if (quizData.isEmpty) {
        setState(() {
          _isLoading = false;
          _status = "😢 분석 결과가 없습니다.";
        });
        return;
      }

      // 퀴즈 페이지로 데이터 전달
      // 수정: QuizPage로 quizData와 docId를 함께 전달
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => QuizPage(
                  quizData: quizData,
                  docId: docId!,
                )),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = "🧨 /quizdata 요청 오류: $e";
      });
      return;
    } finally {
      // 성공/실패와 관계없이 로딩 상태 해제 (단, 페이지 이동 시는 제외)
      if (mounted && Navigator.canPop(context)) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("🎧 LyrixMatch")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration:
                      const InputDecoration(labelText: "Spotify Playlist URL"),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: startQuizFlow,
                        child: const Text("시작"),
                      ),
                if (_status != null) ...[
                  const SizedBox(height: 20),
                  SelectableText(
                    // Text를 SelectableText로 변경
                    _status!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // 가운데 정렬 (선택 사항)
                  ),
                ]
              ],
            ),
          ),
        ),
      );
}
