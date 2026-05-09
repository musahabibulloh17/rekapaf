class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.icon = 'book',
  });

  final int id;
  final String name;
  final String icon;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'book',
    );
  }
}
