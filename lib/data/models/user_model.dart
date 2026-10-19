import 'work_location_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? employeeId;
  final String? nik;
  final String? dob;
  final String? phone;
  final bool mustChangePassword;
  final WorkLocation? location;
  final String? avatarUrl;
  final bool? isActive;
  final List<String>? roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId,
    this.nik,
    this.dob,
    this.phone,
    this.mustChangePassword = false,
    this.location,
    this.avatarUrl,
    this.isActive,
    this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      employeeId: json['employee_id']?.toString(),
      nik: json['nik']?.toString(),
      dob: json['dob']?.toString(),
      phone: json['phone']?.toString(),
      mustChangePassword: json['must_change_password'] == true,
      location: json['location'] != null && json['location'] is Map<String, dynamic>
          ? WorkLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] : null,
      roles: json['roles'] is List
          ? (json['roles'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee_id': employeeId,
      'nik': nik,
      'dob': dob,
      'phone': phone,
      'must_change_password': mustChangePassword,
      'location': location?.toJson(),
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'roles': roles,
    };
  }
}
