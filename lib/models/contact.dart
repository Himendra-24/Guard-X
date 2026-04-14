import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 0)
class Contact extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  bool isPrimary;

  Contact({
    required this.name,
    required this.phone,
    this.isPrimary = false,
  });
}