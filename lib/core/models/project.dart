class Project {
  final int id;
  final String nome;
  const Project({required this.id, required this.nome});
  factory Project.fromJson(Map<String, dynamic> json) =>
      Project(id: json['id'] as int, nome: (json['name'] ?? json['nome']) as String);
}
