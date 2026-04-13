class Party {
  final String name;
  final List<String> aliases;
  final String leader;
  final String? sloganEn;
  final String? sloganTa;
  final String flag;
  final String symbol;

  const Party({
    required this.name,
    required this.aliases,
    required this.leader,
    this.sloganEn,
    this.sloganTa,
    required this.flag,
    required this.symbol,
  });
}
