import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 4)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  String bloodGroup;

  @HiveField(3)
  String allergies;

  @HiveField(4)
  String emergencyContact;

  UserProfile({
    this.name = '',
    this.phone = '',
    this.bloodGroup = '',
    this.allergies = '',
    this.emergencyContact = '',
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? emergencyContact,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
