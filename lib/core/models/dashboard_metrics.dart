class DashboardMetrics {
  final int totalPending;
  final int approvedThisMonth;
  final int rejectedThisMonth;
  final DateTime lastUpdated;

  DashboardMetrics({
    required this.totalPending,
    required this.approvedThisMonth,
    required this.rejectedThisMonth,
    required this.lastUpdated,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalPending: 0,
      approvedThisMonth: 0,
      rejectedThisMonth: 0,
      lastUpdated: DateTime.now(),
    );
  }
}
