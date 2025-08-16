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

  Employee({required this.id, required this.empno, required this.fullname});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      empno: json['empno'],
      fullname: json['fullname'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'empno': empno, 'fullname': fullname};
  }
}
