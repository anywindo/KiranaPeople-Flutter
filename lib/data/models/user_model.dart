import '../../core/config/api_config.dart';
import 'shift_model.dart';
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
  String? get avatar => avatarUrl;
  final bool? isActive;
  final List<String>? roles;
  final String? joinedAt;
  final Shift? shift;
  final String? department;
  final String? gender;

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
    this.joinedAt,
    this.shift,
    this.department,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedNik = json['nik']?.toString();
    final rawGender = json['gender']?.toString();
    final derivedGender = rawGender ?? _deriveGenderFromNik(parsedNik);

    String? dept;
    if (json['department'] != null) {
      dept = json['department'].toString();
    } else if (json['teams'] is List && (json['teams'] as List).isNotEmpty) {
      final first = (json['teams'] as List).first;
      dept = first is Map ? first['name']?.toString() : first.toString();
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      employeeId: json['employee_id']?.toString(),
      nik: parsedNik,
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
      joinedAt: json['joined_at']?.toString() ?? json['created_at']?.toString(),
      shift: json['shift'] != null && json['shift'] is Map<String, dynamic>
          ? Shift.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
      department: dept,
      gender: derivedGender,
    );
  }

  static String? _deriveGenderFromNik(String? nik) {
    if (nik == null) return null;
    final clean = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 16) {
      final rawDay = int.tryParse(clean.substring(6, 8));
      if (rawDay != null) {
        return rawDay > 40 ? 'Perempuan' : 'Laki-laki';
      }
    }
    return null;
  }

  String? get computedGender => gender ?? _deriveGenderFromNik(nik);

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
      'joined_at': joinedAt,
      'shift': shift?.toJson(),
      'department': department,
      'gender': gender,
    };
  }

  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) return null;
    final trimmed = avatarUrl!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final origin = ApiConfig.cachedHostOrigin;
    if (cleanPath.startsWith('storage/')) {
      return '$origin/$cleanPath';
    }
    return '$origin/storage/$cleanPath';
  }
}
