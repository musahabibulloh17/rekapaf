class Classroom {
  final int id;
  final String name;
  final String? waliKelasName;

  const Classroom({
    required this.id,
    required this.name,
    this.waliKelasName,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      waliKelasName: json['wali_kelas']?['name'],
    );
  }
}
