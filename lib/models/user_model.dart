class User {
  final int id;
  final String name;
  final String email;
  final Employee? employee;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee': employee?.toJson(),
    };
  }
}

class Employee {
  final int id;
  final String empno;
  final String fullname;
  final int? userId;
  final City? city;
  final Gender? gender;
  final MaritalStatus? maritalStatus;
  final Nationality? nationality;
  final Religion? religion;
  final String? createdAt;
  final String? updatedAt;

  Employee({
    required this.id,
    required this.empno,
    required this.fullname,
    this.userId,
    this.city,
    this.gender,
    this.maritalStatus,
    this.nationality,
    this.religion,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      empno: json['empno'] ?? '',
      fullname: json['fullname'] ?? '',
      userId: json['user_id'],
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      gender: json['gender'] != null ? Gender.fromJson(json['gender']) : null,
      maritalStatus: json['maritalstatus'] != null
          ? MaritalStatus.fromJson(json['maritalstatus'])
          : null,
      nationality: json['nationality'] != null
          ? Nationality.fromJson(json['nationality'])
          : null,
      religion: json['religion'] != null
          ? Religion.fromJson(json['religion'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empno': empno,
      'fullname': fullname,
      'user_id': userId,
      'city': city?.toJson(),
      'gender': gender?.toJson(),
      'maritalstatus': maritalStatus?.toJson(),
      'nationality': nationality?.toJson(),
      'religion': religion?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Gender {
  final int id;
  final String name;

  Gender({required this.id, required this.name});

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class MaritalStatus {
  final int id;
  final String name;

  MaritalStatus({required this.id, required this.name});

  factory MaritalStatus.fromJson(Map<String, dynamic> json) {
    return MaritalStatus(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Nationality {
  final int id;
  final String name;

  Nationality({required this.id, required this.name});

  factory Nationality.fromJson(Map<String, dynamic> json) {
    return Nationality(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Religion {
  final int id;
  final String name;

  Religion({required this.id, required this.name});

  factory Religion.fromJson(Map<String, dynamic> json) {
    return Religion(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
