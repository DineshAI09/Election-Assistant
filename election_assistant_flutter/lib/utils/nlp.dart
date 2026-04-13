import '../data/parties.dart';
import '../data/party.dart';
import '../data/cms.dart';
import '../data/leaders.dart';

const _stopWords = [
  'what', 'who', 'is', 'the', 'of', 'in', 'for', 'please',
  'tell', 'me', 'show', 'about', 'a', 'an',
];

List<String> tokenize(String input) {
  final text = input.toLowerCase();
  final rawTokens = text.split(RegExp(r'[^a-z]+')).where((s) => s.isNotEmpty).toList();
  return rawTokens.where((t) => !_stopWords.contains(t)).toList();
}

String detectIntent(List<String> tokens) {
  final joined = tokens.join(' ');
  if (joined.contains('flag')) return 'flag';
  if (joined.contains('symbol')) return 'symbol';
  if (joined.contains('leader')) return 'leader';
  if (joined.contains('slogan') || joined.contains('motto')) return 'slogan';
  if (joined.contains('cm') || joined.contains('chief minister')) return 'cm';
  if (joined.contains('prime minister') || joined == 'pm') return 'pm';
  return 'party_info';
}

String normalizeStateKey(String stateName) {
  return stateName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

final _cmsByKey = <String, String>{
  for (final e in cms.entries) normalizeStateKey(e.key): e.value,
};

class ChatResponse {
  final String text;
  final String? image;

  const ChatResponse({required this.text, this.image});
}

ChatResponse getResponse(String input) {
  final tokens = tokenize(input);
  if (tokens.isEmpty) {
    return const ChatResponse(text: 'Please ask an election-related question.');
  }

  final intent = detectIntent(tokens);

  Party? party;
  for (final p in parties) {
    final partyTokens = [
      p.name.toLowerCase(),
      ...p.aliases.map((a) => a.toLowerCase()),
    ];
    final match = tokens.any((t) {
      return partyTokens.any((pt) {
        return pt.split(' ').contains(t) || pt == t;
      });
    });
    if (match) {
      party = p;
      break;
    }
  }

  if (party != null) {
    switch (intent) {
      case 'flag':
        return ChatResponse(text: '${party.name} Flag', image: party.flag);
      case 'symbol':
        return ChatResponse(text: '${party.name} Symbol', image: party.symbol);
      case 'leader':
        return ChatResponse(text: '${party.name} Leader: ${party.leader}');
      case 'slogan':
        final parts = <String>[];
        if (party.sloganEn != null && party.sloganEn!.isNotEmpty) parts.add(party.sloganEn!);
        if (party.sloganTa != null && party.sloganTa!.isNotEmpty) parts.add(party.sloganTa!);
        final text = parts.isNotEmpty
            ? parts.join('\n')
            : "I don't have a stored slogan for ${party.name}.";
        return ChatResponse(text: text);
      default:
        final detailLines = ['Party: ${party.name}', 'Leader: ${party.leader}'];
        if (party.sloganEn != null && party.sloganEn!.isNotEmpty) detailLines.add(party.sloganEn!);
        if (party.sloganTa != null && party.sloganTa!.isNotEmpty) detailLines.add(party.sloganTa!);
        return ChatResponse(
          text: detailLines.join('\n'),
          image: party.flag,
        );
    }
  }

  if (intent == 'cm') {
    int afterCmIndex = -1;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == 'cm' || (tokens[i] == 'chief' && tokens.contains('minister'))) {
        afterCmIndex = i;
        break;
      }
    }
    final stateTokens = afterCmIndex >= 0 ? tokens.sublist(afterCmIndex + 1) : tokens;
    final stateKey = normalizeStateKey(stateTokens.join(' '));

    if (stateKey.isNotEmpty && _cmsByKey.containsKey(stateKey)) {
      String prettyState = stateKey;
      for (final s in cms.keys) {
        if (normalizeStateKey(s) == stateKey) {
          prettyState = s;
          break;
        }
      }
      return ChatResponse(
        text: 'Chief Minister of $prettyState: ${_cmsByKey[stateKey]}',
      );
    }
    return const ChatResponse(
      text: "I could not detect the state. Please ask like: 'Who is the CM of Tamil Nadu?'.",
    );
  }

  if (intent == 'pm') {
    return ChatResponse(
      text: 'Prime Minister of India: ${leaders['prime minister']}',
    );
  }

  return const ChatResponse(
    text: 'I am trained for Indian election questions. Ask about party flags, symbols, slogans, leaders, CMs, or the Prime Minister.',
  );
}
