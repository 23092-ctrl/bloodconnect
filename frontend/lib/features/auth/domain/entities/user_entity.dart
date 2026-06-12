import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
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

  const UserEntity({
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

  int? get daysSinceLastDonation =>
      lastDonationDate != null ? DateTime.now().difference(lastDonationDate!).inDays : null;

  @override
  List<Object?> get props => [id, fullName, email, bloodType, role];
}
