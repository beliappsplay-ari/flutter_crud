class AssetsSalarySlip {
  final int id;
  final String empno;
  final String period;
  final String periodFormatted;
  final String fullname;
  final double basicSalary;
  final double total;
  final String pdfUrl;
  final bool hasPdf;

  AssetsSalarySlip({
    required this.id,
    required this.empno,
    required this.period,
    required this.periodFormatted,
    required this.fullname,
    required this.basicSalary,
    required this.total,
    required this.pdfUrl,
    required this.hasPdf,
  });

  factory AssetsSalarySlip.fromJson(Map<String, dynamic> json) {
    return AssetsSalarySlip(
      id: json['id'] ?? 0,
      empno: json['empno'] ?? '',
      period: json['period'] ?? '',
      periodFormatted: json['period_formatted'] ?? '',
      fullname: json['fullname'] ?? '',
      basicSalary:
          double.tryParse(json['basic_salary']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      pdfUrl: json['pdf_url'] ?? '',
      hasPdf: json['has_pdf'] ?? false,
    );
  }

  // Format currency untuk display
  String get formattedBasicSalary =>
      'Rp ${basicSalary.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedTotal =>
      'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}
