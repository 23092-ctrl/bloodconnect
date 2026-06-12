import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.bloodType,
    super.gender,
    super.phone,
    super.profilePicture,
    required super.notificationsEnabled,
    required super.medicallyEligible,
    super.lastDonationDate,
    required super.role,
  });

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
