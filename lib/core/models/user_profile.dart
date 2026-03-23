/// Modello del profilo utente autenticato.
class UserProfile {
  final String nome;
  final String cognome;
  final String email;
  final String? ruolo;
  final String? struttura;

  const UserProfile({
    required this.nome,
    required this.cognome,
    required this.email,
    this.ruolo,
    this.struttura,
  });

  /// Restituisce nome e cognome concatenati.
  String get nomeCompleto => '$nome $cognome';

  /// Crea un'istanza da JSON con struttura `{ "data": { ... } }`.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dati = json['data'] as Map<String, dynamic>;
    final strutturaObj = dati['struttura'] as Map<String, dynamic>?;
    return UserProfile(
      nome: dati['nome'] as String,
      cognome: dati['cognome'] as String,
      email: dati['email'] as String,
      ruolo: dati['ruolo'] as String?,
      struttura: strutturaObj?['nome'] as String?,
    );
  }
}
