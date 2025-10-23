// quiz_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> quizData;
  final String docId;

  const QuizPage({super.key, required this.quizData, required this.docId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // _isLoading 상태 변수 제거 (showDialog로 로딩 처리)
  int currentIndex = 0;
  int correctCount = 0;
  TextEditingController answerController = TextEditingController();

  void checkAnswer() {
    String userAnswer = answerController.text.trim().toLowerCase();
    String correctAnswer =
        widget.quizData[currentIndex]['title'].toString().trim().toLowerCase();

    bool isCorrect = userAnswer == correctAnswer;
    if (isCorrect) {
      setState(() => correctCount++);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? '정답!' : '오답'),
        content: Text(isCorrect
            ? '정답입니다.'
            : '틀렸습니다. 정답은 "${widget.quizData[currentIndex]['title']}"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              nextQuiz();
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  void nextQuiz() {
    if (currentIndex < widget.quizData.length - 1) {
      setState(() {
        currentIndex++;
        answerController.clear();
      });
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: {
          'correct': correctCount,
          'total': widget.quizData.length,
        },
      );
    }
  }

  void showWordCloud(String title) async {
    // 로딩 다이얼로그 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // URL을 서버 엔드포인트에 맞게 수정
      // Uri.encodeComponent로 제목의 공백 등 특수문자 처리
      final response = await http.get(
        Uri.parse(
            '$baseUrl/wordcloud/${widget.docId}/${Uri.encodeComponent(title)}'),
      );

      Navigator.pop(context); // 로딩 인디케이터 닫기

      if (response.statusCode == 200) {
        // 서버 응답 키(wordcloud_url)에 맞게 JSON 파싱
        final String imageUrl = jsonDecode(response.body)['wordcloud_url'];

        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'wordcloud',
                    child: Image.network(
                      imageUrl, // GCS Public URL 직접 사용
                      fit: BoxFit.cover,
                      // 로딩 중/에러 발생 시 처리
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("닫기"),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        print("워드클라우드 요청 실패: ${response.body}");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("에러"),
            content: const Text("워드클라우드를 불러올 수 없습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // 로딩 인디케이터 닫기
      }
      print("워드클라우드 요청 중 오류 발생: $e");
    }
    // 'finally' 블록과 _isLoading 상태 관리는 로딩 다이얼로그 방식으로 대체되었으므로 제거
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quizData[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎧 LyrixMatch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // 스크롤 가능하도록 SingleChildScrollView 추가
          child: Column(
            children: [
              Text('문제 ${currentIndex + 1} / ${widget.quizData.length}',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              ...quiz['summary']
                  .split('\n')
                  .map<Widget>((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(line, style: const TextStyle(fontSize: 16)),
                      ))
                  .toList(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                children: (quiz['keywords'] as List) // 타입 명시
                    .map<Widget>((kw) => Chip(label: Text(kw.toString())))
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: '노래 제목 입력',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: checkAnswer,
                child: const Text('정답 제출'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => showWordCloud(quiz['title']),
                child: const Text('힌트(워드클라우드) 보기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
