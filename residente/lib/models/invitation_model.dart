class InvitationModel {
  final String id;
  final String name;
  final String company;
  final String reason;
  final DateTime date;
  final String time;
  final int duration;

  InvitationModel({
    required this.id,
    required this.name,
    required this.company,
    required this.reason,
    required this.date,
    required this.time,
    required this.duration,
  });

  // Convertir objeto a JSON para guardar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'reason': reason,
      'date': date.toIso8601String(),
      'time': time,
      'duration': duration,
    };
  }

  // Crear objeto desde un JSON al leer
  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'],
      name: json['name'],
      company: json['company'],
      reason: json['reason'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      duration: json['duration'],
    );
  }
}