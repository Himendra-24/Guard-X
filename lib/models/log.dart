import 'package:hive/hive.dart';

part 'log.g.dart';

@HiveType(typeId: 3)
class AppLog extends HiveObject {
  @HiveField(0)
  String event;

  @HiveField(1)
  DateTime timestamp;

  AppLog({
    required this.event,
    required this.timestamp,
  });
}