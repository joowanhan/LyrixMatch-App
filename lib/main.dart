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
  // final TextEditingController _deeplController = TextEditingController();
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
      _status = "🎵 가사 크롤링 중...";
    });

    // debugging - ⚠️ JSON 데이터를 출력
    final requestBody = jsonEncode({"playlist_url": url});
    print("!!!! Sending to /crawl: $requestBody");

    // 1. /crawl
    final crawlRes = await http.post(
      Uri.parse("$baseUrl/crawl"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"playlist_url": url}),
    );

    if (crawlRes.statusCode != 200) {
      setState(() {
        _isLoading = false;
        _status = "🧨 /crawl 실패: ${crawlRes.body}";
      });
      return;
    }

    setState(() => _status = "🔍 요약/분석 중...");

    // 2. /quizdata
    final quizRes = await http.get(
      Uri.parse("$baseUrl/quizdata"),
    );

    if (quizRes.statusCode != 200) {
      setState(() {
        _isLoading = false;
        _status = "🧨 /quizdata 실패: ${quizRes.body}";
      });
      return;
    }

    final quizData = List<Map<String, dynamic>>.from(jsonDecode(quizRes.body));

    if (quizData.isEmpty) {
      setState(() {
        _isLoading = false;
        _status = "😢 분석 결과가 없습니다.";
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizPage(quizData: quizData)),
    );
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
                  Text(_status!, style: const TextStyle(fontSize: 16)),
                ]
              ],
            ),
          ),
        ),
      );
}
