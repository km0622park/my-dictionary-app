import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word_model.dart';

class ApiService {
  // Datamuse is free and keyless
  static const String _datamuseUrl = 'https://api.datamuse.com/words';

  Future<DictionaryResult> searchEnglish(String query) async {
    // 1. Try Local Dictionary first (Simulated Backend)
    if (_localDictionary.containsKey(query.toLowerCase())) {
      var localData = _localDictionary[query.toLowerCase()]!;
      // Still fetch synonyms if possible to make it dynamic
      var synonyms = await _fetchSynonyms(query);
      return DictionaryResult(
        meanings: localData.meanings,
        synonyms: synonyms.isNotEmpty ? synonyms.take(5).toList() : localData.synonyms,
      );
    }

    // 2. Fallback: Fetch Just Synonyms from real API and use Generic Definition
    final synonyms = await _fetchSynonyms(query);
    return DictionaryResult(
      meanings: [
        WordDefinition(pos: "Results", def: "Found ${synonyms.length} synonyms for '$query'. (Add more words to local dictionary for definitions)"),
      ],
      synonyms: synonyms.take(10).toList(),
    );
  }

  Future<DictionaryResult> searchKorean(String query) async {
    // 1. Try Local Dictionary
    if (_localDictionary.containsKey(query)) {
      return _localDictionary[query]!;
    }

    // 2. Fallback Generic
    return DictionaryResult(
      engEquivalents: [
        EnglishEquivalent(word: "Unknown", example: "We don't have '$query' in our offline database yet."),
      ],
      korDefinition: "이 단어는 아직 오프라인 데이터베이스에 등록되지 않았습니다.",
    );
  }

  Future<List<String>> _fetchSynonyms(String query) async {
    try {
      final response = await http.get(Uri.parse('$_datamuseUrl?rel_syn=$query'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e['word'] as String).toList();
      }
    } catch (e) {
      print('Datamuse API Error: $e');
    }
    return [];
  }

  // --- BIG LOCAL DICTIONARY (Simulating a Database) ---
  static final Map<String, DictionaryResult> _localDictionary = {
    // English Words
    "good": DictionaryResult(
      meanings: [
        WordDefinition(pos: "형", def: "좋은, 즐거운, 기쁜"),
        WordDefinition(pos: "명", def: "선(善), 유익한 것"),
      ],
      synonyms: ["fine", "excellent", "quality"],
    ),
    "love": DictionaryResult(
      meanings: [
        WordDefinition(pos: "명", def: "사랑, 애정"),
        WordDefinition(pos: "동", def: "사랑하다, 좋아하다"),
      ],
      synonyms: ["affection", "passion", "devotion"],
    ),
    "hello": DictionaryResult(
      meanings: [
        WordDefinition(pos: "감", def: "안녕, 안녕하세요 (인사)"),
      ],
      synonyms: ["hi", "greetings"],
    ),
    "run": DictionaryResult(
      meanings: [
        WordDefinition(pos: "동", def: "달리다, 뛰다"),
        WordDefinition(pos: "동", def: "경영하다, 운영하다"),
      ],
      synonyms: ["jog", "sprint", "operate"],
    ),
    "developer": DictionaryResult(
      meanings: [
        WordDefinition(pos: "명", def: "개발자"),
        WordDefinition(pos: "명", def: "택지 조성업자"),
      ],
      synonyms: ["programmer", "coder", "engineer"],
    ),

    // Korean Words
    "사랑": DictionaryResult(
      engEquivalents: [
        EnglishEquivalent(word: "Love", example: "I love you."),
        EnglishEquivalent(word: "Affection", example: "He has a deep affection for her."),
      ],
      korDefinition: "어떤 사람이나 존재를 몹시 아끼고 귀중히 여기는 마음. 또는 그런 일.",
    ),
    "학교": DictionaryResult(
      engEquivalents: [
        EnglishEquivalent(word: "School", example: "I go to school."),
      ],
      korDefinition: "일정한 목적ㆍ교과 과정ㆍ설비ㆍ제도 및 법규에 의하여 교사가 계속적으로 학생에게 교육을 실시하는 기관.",
    ),
    "친구": DictionaryResult(
      engEquivalents: [
        EnglishEquivalent(word: "Friend", example: "She is my best friend."),
        EnglishEquivalent(word: "Companion", example: "A traveling companion."),
      ],
      korDefinition: "가깝게 오래 사귄 사람.",
    ),
     "안녕": DictionaryResult(
      engEquivalents: [
        EnglishEquivalent(word: "Hello", example: "Hello, how are you?"),
        EnglishEquivalent(word: "Hi", example: "Hi there!"),
      ],
      korDefinition: "아무 탈 없이 편안함. 또는 만날 때나 헤어질 때 하는 인사.",
    ),
  };
}
