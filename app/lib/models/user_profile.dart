class UserProfile {
  final String id;
  final String login;
  final String nome;
  final String email;
  final String role;

  UserProfile({
    required this.id,
    required this.login,
    required this.nome,
    required this.email,
    required this.role,
  });

  bool get isCellOwner => role == 'cell_owner';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      login: json['login'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
