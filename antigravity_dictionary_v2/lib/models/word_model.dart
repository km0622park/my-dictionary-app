
class DictionaryResult {
  final List<WordDefinition> meanings;
  final List<String> synonyms;
  final List<EnglishEquivalent> engEquivalents;
  final String? korDefinition;
  final String? audioUrl; // URL for pronunciation audio

  DictionaryResult({
    this.meanings = const [],
    this.synonyms = const [],
    this.engEquivalents = const [],
    this.korDefinition,
    this.audioUrl,
  });
}

class WordDefinition {
  final String pos; // Part of speech (명사, 형용사...)
  final String def; // Definition

  WordDefinition({required this.pos, required this.def});
}

class EnglishEquivalent {
  final String word;
  final String example;

  EnglishEquivalent({required this.word, required this.example});
}
