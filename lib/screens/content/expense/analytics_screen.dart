import 'package:flutter/material.dart';
import 'package:digital_khata/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTextColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top metrics
            _buildTopMetricsSection(primaryTextColor),
            const SizedBox(height: 24),

            // Overdue customers alert
            _buildOverdueCustomersSection(primaryTextColor),
            const SizedBox(height: 24),

            // Payment status distribution
            _buildPaymentStatusSection(primaryTextColor),
            const SizedBox(height: 24),

            // Top customers
            _buildTopCustomersSection(primaryTextColor),
            const SizedBox(height: 24),

            // Monthly summary
            _buildMonthlySummarySection(primaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMetricsSection(Color primaryTextColor) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsService.getCustomerAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: TextStyle(color: primaryTextColor),
          );
        }

        final data = snapshot.data ?? {};
        final totalDue = (data['totalDue'] as num?)?.toDouble() ?? 0.0;
        final totalCustomers = (data['totalCustomers'] as int?) ?? 0;
        final averageDue = (data['averageDue'] as num?)?.toDouble() ?? 0.0;
        final highestDue = (data['highestDue'] as num?)?.toDouble() ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Due',
                    value: 'Rs. ${totalDue.toStringAsFixed(2)}',
                    icon: Icons.money,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Customers',
                    value: totalCustomers.toString(),
                    icon: Icons.people,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg Due',
                    value: 'Rs. ${averageDue.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Highest Due',
                    value: 'Rs. ${highestDue.toStringAsFixed(2)}',
                    icon: Icons.arrow_upward,
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final primaryTextColor = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCustomersSection(Color primaryTextColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getOverdueCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final overdueCustomers = snapshot.data ?? [];
        if (overdueCustomers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No overdue payments! Great job!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overdue Payments (30+ days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: List.generate(
                  overdueCustomers.length,
                  (index) => _buildOverdueCustomerTile(
                    overdueCustomers[index],
                    index,
                    overdueCustomers.length,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverdueCustomerTile(
    Map<String, dynamic> customer,
    int index,
    int totalCount,
  ) {
    final theme = Theme.of(context);
    final primaryTextColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customer['daysSinceLastTransaction']} days overdue',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${(customer['due'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          if (index < totalCount - 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(
                height: 1,
                color: Colors.red.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusSection(Color primaryTextColor) {
    return FutureBuilder<Map<String, int>>(
      future: _analyticsService.getPaymentStatusDistribution(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final status = snapshot.data ?? {};
        final clear = status['clear'] ?? 0;
        final partial = status['partial'] ?? 0;
        final highDue = status['highDue'] ?? 0;
        final total = clear + partial + highDue;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    label: 'Clear',
                    count: clear,
                    percentage: total > 0 ? (clear / total * 100) : 0,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    label: 'Partial',
                    count: partial,
                    percentage: total > 0 ? (partial / total * 100) : 0,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    label: 'High Due',
                    count: highDue,
                    percentage: total > 0 ? (highDue / total * 100) : 0,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard({
    required String label,
    required int count,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final primaryTextColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomersSection(Color primaryTextColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getTopCustomers(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final topCustomers = snapshot.data ?? [];
        if (topCustomers.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Customers (by due)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(
                topCustomers.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTopCustomerTile(topCustomers[index], index + 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopCustomerTile(Map<String, dynamic> customer, int rank) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final primaryTextColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryTextColor,
                  ),
                ),
                Text(
                  customer['phone'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${(customer['due'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummarySection(Color primaryTextColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _analyticsService.getMonthlySummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final monthly = snapshot.data ?? [];
        if (monthly.isEmpty) {
          return const SizedBox();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final cardColor = theme.colorScheme.surface;
        final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary (Last 12 months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(
                  monthly.length,
                  (index) => _buildMonthlySummaryTile(
                    monthly[index],
                    index,
                    monthly.length,
                    borderColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlySummaryTile(
    Map<String, dynamic> monthData,
    int index,
    int totalCount,
    Color borderColor,
  ) {
    final month = monthData['month'] as String? ?? '';
    final due = (monthData['due'] as num?)?.toDouble() ?? 0.0;
    final theme = Theme.of(context);
    final primaryTextColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: primaryTextColor,
                ),
              ),
              Text(
                'Rs. ${due.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          if (index < totalCount - 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(
                height: 1,
                color: borderColor,
              ),
            ),
        ],
      ),
    );
  }
}