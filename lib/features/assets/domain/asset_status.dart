enum AssetStatus {
  sprawny,
  uszkodzony,
  wNaprawie,
  wycofany,
  zaginiony;

  String get label => switch (this) {
    AssetStatus.sprawny => 'Sprawny',
    AssetStatus.uszkodzony => 'Uszkodzony',
    AssetStatus.wNaprawie => 'W naprawie',
    AssetStatus.wycofany => 'Wycofany',
    AssetStatus.zaginiony => 'Zaginiony',
  };

  static AssetStatus fromName(String? name) {
    return AssetStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => AssetStatus.sprawny,
    );
  }
}
