import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/contact.dart';
import '../models/trip.dart';
import '../models/note.dart';
import '../models/log.dart';
import '../models/user_profile.dart';

class HiveService {
  static const String contactsBoxName = 'contacts';
  static const String tripsBoxName = 'trips';
  static const String notesBoxName = 'notes';
  static const String logsBoxName = 'logs';
  static const String userProfileBoxName = 'user_profile';
  
  static final ValueNotifier<String> userNameNotifier = ValueNotifier<String>('');

  static Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ContactAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TripAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AppLogAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UserProfileAdapter());

    // Open boxes
    await Hive.openBox<Contact>(contactsBoxName);
    await Hive.openBox<Trip>(tripsBoxName);
    await Hive.openBox<Note>(notesBoxName);
    await Hive.openBox<AppLog>(logsBoxName);
    await Hive.openBox<UserProfile>(userProfileBoxName);
    await Hive.openBox('settings');

    // Initialize notifier
    final user = getUser();
    userNameNotifier.value = user.name.isNotEmpty ? user.name : 'Guardian';
  }

  static Box<Contact> get contacts => Hive.box<Contact>(contactsBoxName);
  static Box<Trip> get trips => Hive.box<Trip>(tripsBoxName);
  static Box<Note> get notes => Hive.box<Note>(notesBoxName);
  static Box<AppLog> get logs => Hive.box<AppLog>(logsBoxName);
  static Box<UserProfile> get userProfile => Hive.box<UserProfile>(userProfileBoxName);
  static Box get settings => Hive.box('settings');

  /// Helper to get or create the user profile
  static UserProfile getUser() {
    if (userProfile.isEmpty) {
      return UserProfile();
    }
    return userProfile.getAt(0)!;
  }

  static Future<void> saveUser(UserProfile user) async {
    if (userProfile.isEmpty) {
      await userProfile.add(user);
    } else {
      await userProfile.putAt(0, user);
    }
    userNameNotifier.value = user.name.isNotEmpty ? user.name : 'Guardian';
  }

  static Future<void> addLog(String event) async {
    await logs.add(AppLog(event: event, timestamp: DateTime.now()));
  }
}