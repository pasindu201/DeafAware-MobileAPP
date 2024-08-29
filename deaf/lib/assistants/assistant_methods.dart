import 'package:drivers/global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import 'dart:async';

class AssistantMethods {
  static Future<void> readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      print("No user is currently logged in.");
      return;
    }

    DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child("deafcare_users").child(currentUser!.uid);

    try {
      DatabaseEvent event = await userRef.once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        userModelCurrentinfo = UserModel.fromSnapshot(snapshot);
        print("User info loaded: ${userModelCurrentinfo.toString()}");
      } else {
        print("User data not found in database for UID: ${currentUser!.uid}");
      }
    } catch (error) {
      print("Failed to load user info: $error");
    }
  }

}
