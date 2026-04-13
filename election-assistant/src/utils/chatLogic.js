import parties from "../data/parties";

export function getResponse(question) {
  const q = question.toLowerCase();

  const party = parties.find(p =>
    q.includes(p.name.toLowerCase())
  );

  if (!party) return { text: "Party not found 🤔" };

  if (q.includes("flag")) {
    return {
      text: `${party.name} Flag`,
      image: `/assets/flags/${party.flag}.png`
    };
  }

  if (q.includes("symbol")) {
    return {
      text: `${party.name} Symbol`,
      image: `/assets/symbols/${party.symbol}.png`
    };
  }

  if (q.includes("leader")) {
    return {
      text: `${party.name} leader is ${party.leader}`
    };
  }

  return {
    text: `${party.name} details`,
    image: `/assets/flags/${party.flag}.png`
  };
}