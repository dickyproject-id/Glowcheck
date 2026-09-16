import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String gender;
  final DateTime dob;
  final String? photoProfile;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.dob,
    this.photoProfile,
  });

  // --- GETTER AGE (PENTING untuk Provider) ---
  int get age {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  // Factory: Dari Map/Firestore ke Object
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      gender: map['gender'] ?? 'Belum diketahui',
      // Parsing tanggal lahir yang aman (support String & Timestamp)
      dob: map['dob'] != null
          ? (map['dob'] is Timestamp
                ? (map['dob'] as Timestamp).toDate()
                : DateTime.tryParse(map['dob'].toString()) ?? DateTime.now())
          : DateTime.now(),
      photoProfile: map['photoProfile'],
    );
  }

  // Factory Helper
  factory UserModel.fromFirestore(Map<String, dynamic> map, String id) {
    return UserModel.fromMap(map, id);
  }

  // To Map: Dari Object ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'dob': dob.toIso8601String(),
      'photoProfile': photoProfile,
    };
  }
}
