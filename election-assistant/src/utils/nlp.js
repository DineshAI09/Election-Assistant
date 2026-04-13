import parties from "../data/parties.js";
import cms from "../data/cms.js";
import leaders from "../data/leaders.js";

const STOP_WORDS = [
  "what",
  "who",
  "is",
  "the",
  "of",
  "in",
  "for",
  "please",
  "tell",
  "me",
  "show",
  "about",
  "a",
  "an"
];

const tokenize = (input) => {
  const text = input.toLowerCase();
  const rawTokens = text.split(/[^a-z]+/).filter(Boolean);
  return rawTokens.filter((t) => !STOP_WORDS.includes(t));
};

const detectIntent = (tokens) => {
  const joined = tokens.join(" ");

  if (joined.includes("flag")) return "flag";
  if (joined.includes("symbol")) return "symbol";
  if (joined.includes("leader")) return "leader";
  if (joined.includes("slogan") || joined.includes("motto")) return "slogan";
  if (joined.includes("cm") || joined.includes("chief minister")) return "cm";
  if (joined.includes("prime minister") || joined === "pm") return "pm";
  if (
    joined.includes("list") ||
    joined.includes("major") ||
    joined.includes("all") ||
    joined.includes("parties") ||
    joined.includes("available")
  ) return "list_parties";

  return "party_info";
};


const normalizeStateKey = (stateName) =>
  stateName.toLowerCase().replace(/\s+/g, " ").trim();

const cmsByKey = Object.keys(cms).reduce((map, state) => {
  const key = normalizeStateKey(state);
  // eslint-disable-next-line no-param-reassign
  map[key] = cms[state];
  return map;
}, {});

export const getResponse = (input) => {
  const tokens = tokenize(input);
  if (tokens.length === 0) {
    return { text: "Please ask an election-related question." };
  }

  const intent = detectIntent(tokens);

  // Party detection using aliases and name
  const party = parties.find((p) => {
    const partyTokens = [
      p.name.toLowerCase(),
      ...(p.aliases || []).map((a) => a.toLowerCase())
    ];
    return tokens.some((t) =>
      partyTokens.some((pt) => pt.split(" ").includes(t) || pt === t)
    );
  });

  if (party) {
    if (intent === "flag") {
      return { text: `${party.name} Flag`, image: party.flag };
    }
    if (intent === "symbol") {
      return { text: `${party.name} Symbol`, image: party.symbol };
    }
    if (intent === "leader") {
      return { text: `${party.name} Leader: ${party.leader}` };
    }
    if (intent === "slogan") {
      const parts = [];
      if (party.sloganEn) {
        parts.push(party.sloganEn);
      }
      if (party.sloganTa) {
        parts.push(party.sloganTa);
      }
      const text =
        parts.length > 0
          ? parts.join("\n")
          : `I don't have a stored slogan for ${party.name}.`;
      return { text };
    }
    const detailLines = [`Party: ${party.name}`, `Leader: ${party.leader}`];
    if (party.sloganEn) detailLines.push(party.sloganEn);
    if (party.sloganTa) detailLines.push(party.sloganTa);

    return {
      text: detailLines.join("\n"),
      image: party.flag
    };
  }

  if (intent === "cm") {
    const afterCmIndex = tokens.findIndex(
      (t) => t === "cm" || (t === "chief" && tokens.includes("minister"))
    );
    const stateTokens =
      afterCmIndex >= 0 ? tokens.slice(afterCmIndex + 1) : tokens;
    const stateKey = normalizeStateKey(stateTokens.join(" "));

    // Exact match
    if (stateKey && cmsByKey[stateKey]) {
      const prettyState =
        Object.keys(cms).find(
          (state) => normalizeStateKey(state) === stateKey
        ) || stateKey;
      return { text: `Chief Minister of ${prettyState}: ${cmsByKey[stateKey]}` };
    }

    // Substring fallback: "tamil" → "tamil nadu"
    const allStateKeys = Object.keys(cmsByKey);
    const partialMatch = allStateKeys.find(
      (k) => stateKey && (k.includes(stateKey) || stateKey.includes(k))
    );
    if (partialMatch) {
      const prettyState =
        Object.keys(cms).find(
          (state) => normalizeStateKey(state) === partialMatch
        ) || partialMatch;
      return { text: `Chief Minister of ${prettyState}: ${cmsByKey[partialMatch]}` };
    }

    return {
      text:
        "I could not detect the state. Please ask like: 'Who is the CM of Tamil Nadu?'."
    };
  }

  if (intent === "pm") {
    return {
      text: `Prime Minister of India: ${leaders["prime minister"]}`
    };
  }

  if (intent === "list_parties") {
    const names = parties.map((p) => p.name).join(", ");
    return { text: `Major parties in Tamil Nadu: ${names}.` };
  }

  return {
    text:
      "I am trained for Indian election questions. Ask about party flags, symbols, slogans, leaders, CMs, or the Prime Minister."
  };
};