import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'services/api_service.dart';
import 'models/word_model.dart';

void main() {
  runApp(const AntigravityApp());
}

class AntigravityApp extends StatelessWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity Dictionary',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const DictionaryHome(),
    );
  }
}

class DictionaryHome extends StatefulWidget {
  const DictionaryHome({super.key});

  @override
  State<DictionaryHome> createState() => _DictionaryHomeState();
}

class _DictionaryHomeState extends State<DictionaryHome> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final ApiService _apiService = ApiService();
  
  // 검색 결과 상태 변수
  String _searchedWord = "";
  bool _isEnglish = true;
  bool _hasResult = false;
  bool _isLoading = false;

  DictionaryResult _result = DictionaryResult();

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _searchedWord = query;
      // 한글 포함 여부로 언어 감지
      _isEnglish = !RegExp(r'[가-h]').hasMatch(query); 
    });

    try {
      DictionaryResult result;
      if (_isEnglish) {
        result = await _apiService.searchEnglish(query);
      } else {
        result = await _apiService.searchKorean(query);
      }

      setState(() {
        _result = result;
        _hasResult = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    // 1. Try playing audio URL from API first
    if (_result.audioUrl != null && _result.audioUrl!.isNotEmpty) {
      try {
        // Just use TTS for now as AudioPlayer requires extra package (audioplayers/just_audio)
        // and adding native dependencies might complicate the build without verification.
        // We will stick to TTS for simplicity and reliability in this specific environment request.
        // If user explicitly asks for native audio, we can add it.
        // For now, let's use the TTS engine for consistent playback 
        await flutterTts.setLanguage("en-US");
        await flutterTts.speak(text);
        return;
      } catch (e) {
        print("Audio play error: $e");
      }
    }
    
    // 2. Fallback to TTS
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antigravity Dictionary'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 검색창
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '단어를 입력하세요 (영어/한글)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 20),
            
            // 로딩 인디케이터 또는 결과 화면
            if (_isLoading)
               const CircularProgressIndicator()
            else if (_hasResult) 
               Expanded(child: _buildResultView()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return ListView(
      children: [
        // 1. 검색어 헤더 및 발음 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _searchedWord,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            if (_isEnglish)
              IconButton(
                icon: const Icon(Icons.volume_up, size: 30, color: Colors.blue),
                onPressed: () => _speak(_searchedWord),
              ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),

        // 2. 검색 결과 표시 (영어 vs 한국어 분기)
        if (_isEnglish) ...[
          // [영어 검색 결과]
          const Text("뜻 (Top 3)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          if (_result.meanings.isEmpty) const Text("No definition found."),
          ..._result.meanings.map((m) => ListTile(
            leading: CircleAvatar(
              child: Text(m.pos.isNotEmpty ? m.pos.substring(0, 1) : "-", style: const TextStyle(fontSize: 12)), 
              backgroundColor: Colors.deepPurple.shade100,
              radius: 15,
            ),
            title: Text(m.def, style: const TextStyle(fontSize: 18)),
          )),
          const SizedBox(height: 20),
          const Text("유사어 (Synonyms)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          if (_result.synonyms.isEmpty) const Text("No synonyms found."),
          Wrap(
            spacing: 8.0,
            children: _result.synonyms.map<Widget>((syn) {
              return ActionChip(
                label: Text(syn),
                onPressed: () {
                  _controller.text = syn;
                  _search(syn);
                },
              );
            }).toList(),
          )

        ] else ...[
          // [한국어 검색 결과]
          const Text("영어 표현 및 예문", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          if (_result.engEquivalents.isEmpty) const Text("No equivalents found."),
          ..._result.engEquivalents.map((e) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(e.word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text("예문: ${e.example}", style: const TextStyle(fontStyle: FontStyle.italic)),
              trailing: IconButton(
                 icon: const Icon(Icons.volume_up, size: 20, color: Colors.grey),
                 onPressed: () => _speak(e.word),
              ),
            ),
          )),
          const SizedBox(height: 20),
          const Text("국어사전 뜻", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_result.korDefinition ?? "No definition found.", style: const TextStyle(fontSize: 16)),
          ),
        ],
      ],
    );
  }
}
