import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../models/word_model.dart';

class ApiService {
  final GoogleTranslator _translator = GoogleTranslator();
  static const String _dictionaryApiUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  /// Searches for an English word.
  /// Returns Korean definitions (translated from English) and synonyms.
  Future<DictionaryResult> searchEnglish(String query) async {
    try {
      final response = await http.get(Uri.parse('$_dictionaryApiUrl/$query'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entry = data[0];
        
        // 1. Get Audio
        String? audioUrl;
        if (entry['phonetics'] != null) {
          for (var p in entry['phonetics']) {
            if (p['audio'] != null && p['audio'].toString().isNotEmpty) {
              audioUrl = p['audio'];
              break;
            }
          }
        }

        // 2. Get Meanings & Synonyms
        List<WordDefinition> meanings = [];
        Set<String> synonymsSet = {};

        if (entry['meanings'] != null) {
          for (var m in entry['meanings']) {
            String partOfSpeech = m['partOfSpeech'] ?? '';
            String definition = '';
            
            // Get first definition
            if (m['definitions'] != null && m['definitions'].isNotEmpty) {
              definition = m['definitions'][0]['definition'];
            }

            // Translate definition to Korean
            if (definition.isNotEmpty) {
              var translation = await _translator.translate(definition, to: 'ko');
              var posTranslation = await _translator.translate(partOfSpeech, to: 'ko');
              meanings.add(WordDefinition(pos: posTranslation.text, def: translation.text));
            }

            // Collect Synonyms
            if (m['synonyms'] != null) {
               m['synonyms'].forEach((s) => synonymsSet.add(s.toString()));
            }
          }
        }
        
        return DictionaryResult(
          meanings: meanings.take(3).toList(), // Top 3
          synonyms: synonymsSet.take(5).toList(),
          audioUrl: audioUrl,
        );
      } 
    } catch (e) {
      print("Error fetching English word: $e");
    }

    // Fallback if API fails or word not found
    var translation = await _translator.translate(query, to: 'ko');
    return DictionaryResult(
      meanings: [WordDefinition(pos: "번역", def: translation.text)],
    );
  }

  /// Searches for a Korean word.
  /// 1. Translates Korean -> English to find the word.
  /// 2. Fetches English definition (for examples).
  /// 3. Provides Korean definition (via translation or fallback).
  Future<DictionaryResult> searchKorean(String query) async {
    try {
      // 1. Translate Korean -> English
      var trans = await _translator.translate(query, to: 'en');
      String engWord = trans.text;

      // 2. Fetch English details for examples
      final response = await http.get(Uri.parse('$_dictionaryApiUrl/$engWord'));
      List<EnglishEquivalent> equivalents = [];
      String? audioUrl;
      
      if (response.statusCode == 200) {
         final List<dynamic> data = json.decode(response.body);
         final entry = data[0];

         // Audio
         if (entry['phonetics'] != null) {
          for (var p in entry['phonetics']) {
            if (p['audio'] != null && p['audio'].toString().isNotEmpty) {
              audioUrl = p['audio'];
              break;
            }
          }
        }

         // Find examples
         if (entry['meanings'] != null) {
           for (var m in entry['meanings']) {
             if (m['definitions'] != null) {
               for (var d in m['definitions']) {
                 if (d['example'] != null) {
                   equivalents.add(EnglishEquivalent(word: engWord, example: d['example']));
                 }
               }
             }
           }
         }
      }

      // If no examples found, just show the word
      if (equivalents.isEmpty) {
        equivalents.add(EnglishEquivalent(word: engWord, example: "No example available."));
      }

      // 3. Korean Definition (Simulated by translating the English definition back or using original query)
      // Since we don't have a KR Dictionary API, we use a placeholder or potentially translate the English definition's essence.
      // Better approach for "Korean Definition": Just use the input query as the "word" and provide a standard description if possible. 
      // Current constraint: We lack a Real KR Dictionary API.
      // We will leave the definition generic or try to fetch a definition from English and translate it.
      
      return DictionaryResult(
        engEquivalents: equivalents.take(3).toList(),
        korDefinition: "$query (한국어 뜻 - 상세 사전 데이터 필요)", // Placeholder due to API limits.
        audioUrl: audioUrl
      );

    } catch (e) {
      return DictionaryResult(
        engEquivalents: [EnglishEquivalent(word: "Error", example: "Translation failed.")],
        korDefinition: "오류가 발생했습니다.",
      );
    }
  }
}
