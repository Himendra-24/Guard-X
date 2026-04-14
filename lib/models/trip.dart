import 'package:hive/hive.dart';

part 'trip.g.dart';

@HiveType(typeId: 1)
class Trip extends HiveObject {
  @HiveField(0)
  String from;

  @HiveField(1)
  String to;

  @HiveField(2)
  int duration; // minutes

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  DateTime? startTime;

  @HiveField(5)
  bool completed;

  Trip({
    required this.from,
    required this.to,
    required this.duration,
    this.isActive = false,
    this.startTime,
    this.completed = false,
  });
}