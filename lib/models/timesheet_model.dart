class TimesheetModel {
  final String id;
  final String period;
  final String employeeName;
  final String employeeNumber;
  final DateTime createdAt;
  final String pdfPath;
  final bool hasPdf;
  final String? pdfUrl;

  TimesheetModel({
    required this.id,
    required this.period,
    required this.employeeName,
    required this.employeeNumber,
    required this.createdAt,
    required this.pdfPath,
    this.hasPdf = false,
    this.pdfUrl,
  });

  factory TimesheetModel.fromJson(Map<String, dynamic> json) {
    return TimesheetModel(
      id: json['id']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      employeeName:
          json['employee_name']?.toString() ??
          json['fullname']?.toString() ??
          '',
      employeeNumber:
          json['empno']?.toString() ??
          json['employee_number']?.toString() ??
          '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      pdfPath: json['pdf_path']?.toString() ?? '',
      hasPdf: json['has_pdf'] ?? false,
      pdfUrl: json['pdf_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'employee_name': employeeName,
      'empno': employeeNumber,
      'created_at': createdAt.toIso8601String(),
      'pdf_path': pdfPath,
      'has_pdf': hasPdf,
      'pdf_url': pdfUrl,
    };
  }

  String get periodFormatted {
    if (period.length == 6) {
      final year = period.substring(0, 4);
      final month = period.substring(4, 6);

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return '${months[monthIndex - 1]} $year';
      }
    }
    return period;
  }

  // Helper methods for backward compatibility
  @deprecated
  String get fullname => employeeName;

  @deprecated
  String get empno => employeeNumber;
}
