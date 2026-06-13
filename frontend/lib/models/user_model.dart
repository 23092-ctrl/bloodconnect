class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? bloodType;
  final String? gender;
  final String? phone;
  final String? profilePicture;
  final bool notificationsEnabled;
  final bool medicallyEligible;
  final DateTime? lastDonationDate;
  final String role;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.bloodType,
    this.gender,
    this.phone,
    this.profilePicture,
    required this.notificationsEnabled,
    required this.medicallyEligible,
    this.lastDonationDate,
    required this.role,
  });

  bool get canDonate {
    if (!medicallyEligible) return false;
    if (lastDonationDate == null) return true;
    return DateTime.now().difference(lastDonationDate!).inDays >= 56;
  }

  int? get daysSinceLastDonation => lastDonationDate != null
      ? DateTime.now().difference(lastDonationDate!).inDays
      : null;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] ?? json['id'],
        fullName: json['fullName'],
        email: json['email'],
        bloodType: json['bloodType'],
        gender: json['gender'],
        phone: json['phone'],
        profilePicture: json['profilePicture'],
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        medicallyEligible: json['medicallyEligible'] ?? true,
        lastDonationDate: json['lastDonationDate'] != null
            ? DateTime.parse(json['lastDonationDate'])
            : null,
        role: json['role'] ?? 'donor',
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'fullName': fullName,
        'email': email,
        'bloodType': bloodType,
        'gender': gender,
        'phone': phone,
        'profilePicture': profilePicture,
        'notificationsEnabled': notificationsEnabled,
        'medicallyEligible': medicallyEligible,
        'lastDonationDate': lastDonationDate?.toIso8601String(),
        'role': role,
      };
}
