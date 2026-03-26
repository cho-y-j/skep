import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? businessNumber;
  final String? representativeName;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Company({
    required this.id,
    required this.name,
    required this.type,
    this.businessNumber,
    this.representativeName,
    this.phone,
    this.email,
    this.address,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      businessNumber: json['businessNumber'] as String?,
      representativeName: json['representativeName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'businessNumber': businessNumber,
      'representativeName': representativeName,
      'phone': phone,
      'email': email,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        businessNumber,
        representativeName,
        phone,
        email,
        address,
        isActive,
        createdAt,
        updatedAt,
      ];
}

enum CompanyType {
  supplier('SUPPLIER'),
  bpCompany('BP_COMPANY');

  final String value;

  const CompanyType(this.value);

  factory CompanyType.fromString(String value) {
    return CompanyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CompanyType.supplier,
    );
  }
}
