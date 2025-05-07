import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/sales_service.dart';
import '../services/enquiry_service.dart';
import '../services/measurement_service.dart';
import '../models/sales_model.dart';
import '../models/enquiry_model.dart';
import '../models/task_model.dart';

enum ReportPeriod { daily, weekly, monthly }

class OverviewCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;
  final bool isPositiveTrend;

  const OverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend = true,
  });

  @override
  State<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<OverviewCard> {
  // Analytics
  int totalSales = 0;
  int totalEnquiries = 0;
  int totalCashSales = 0;
  int totalCreditSales = 0;
  int totalMTBT = 0;
  int totalMOKPending = 0;
  int totalAdditionalNotes = 0; // sales with non-empty additional notes
  double conversionRate = 0.0;

  // Data for charts
  List<_SalesData> salesData = [];
  List<_PaymentTypeData> paymentTypeData = [];

  // Loading & error
  bool isLoading = true;
  String errorMessage = '';

  // Current period
  ReportPeriod _selectedPeriod = ReportPeriod.daily;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  /// Helper to parse the sales date from SalesModel
  DateTime _getSaleDate(SalesModel sale) {
    final rawDate = sale.salesDate;
    if (rawDate is Timestamp) {
      return (rawDate as Timestamp).toDate();
    } else {
      return rawDate;
    }
  }

  /// The main analytics fetch logic
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final salesService = Provider.of<SalesService>(context, listen: false);
      final enquiryService =
          Provider.of<EnquiryService>(context, listen: false);
      final measurementService =
          Provider.of<MeasurementService>(context, listen: false);

      // 1) Fetch raw data
      final List<SalesModel> allSales = await salesService.getSales();
      final List<EnquiryModel> allEnquiries =
          await enquiryService.getAllEnquiries();
      final List<TaskModel> tasks =
          await measurementService.getTATTaskTracking().first;

      // 2) Get date range for chosen period
      final now = DateTime.now();
      late DateTime start;
      late DateTime end;
      if (_selectedPeriod == ReportPeriod.daily) {
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_selectedPeriod == ReportPeriod.weekly) {
        final weekday = now.weekday; // Monday=1
        final monday = now.subtract(Duration(days: weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        end = start
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
      } else {
        // monthly
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(seconds: 1));
      }

      // 3) Filter
      final filteredSales = allSales.where((s) {
        final saleDate = _getSaleDate(s);
        return saleDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            saleDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      final filteredEnquiries = allEnquiries.where((e) {
        final eqDate = e.enquiryDate.toDate();
        return eqDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            eqDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      // 4) Summaries
      totalSales = filteredSales.length;
      totalEnquiries = filteredEnquiries.length;
      totalCashSales =
          filteredSales.where((s) => s.saleType.toLowerCase() == 'cash').length;
      totalCreditSales = filteredSales
          .where((s) => s.saleType.toLowerCase() == 'credit')
          .length;
      totalAdditionalNotes = filteredSales
          .where(
              (s) => s.additionalNotes != null && s.additionalNotes!.isNotEmpty)
          .length;

      // For tasks
      totalMTBT = tasks.where((t) => t.status == 'MTBT').length;
      totalMOKPending = tasks.where((t) => t.status == 'MOK').length;

      if (totalEnquiries > 0) {
        conversionRate = (totalSales / totalEnquiries) * 100.0;
      } else {
        conversionRate = 0.0;
      }

      // 5) For line chart (sales trend)
      final Map<DateTime, double> dailySales = {};
      for (var sale in filteredSales) {
        final date = _getSaleDate(sale);
        final dayKey = DateTime(date.year, date.month, date.day);
        dailySales[dayKey] = (dailySales[dayKey] ?? 0) + sale.crAmount;
      }
      final entries = dailySales.entries.toList();
      entries.sort((a, b) => a.key.compareTo(b.key));
      salesData = entries.map((e) => _SalesData(e.key, e.value)).toList();

      // 6) For pie chart (payment distribution)
      paymentTypeData = [
        _PaymentTypeData('Cash', totalCashSales.toDouble()),
        _PaymentTypeData('Credit', totalCreditSales.toDouble()),
      ];

      setState(() {
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching analytics: $e';
      });
    }
  }

  /// Choice chips for daily/weekly/monthly
  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodChip(label: 'Daily', period: ReportPeriod.daily),
        const SizedBox(width: 8),
        _buildPeriodChip(label: 'Weekly', period: ReportPeriod.weekly),
        const SizedBox(width: 8),
        _buildPeriodChip(label: 'Monthly', period: ReportPeriod.monthly),
      ],
    );
  }

  Widget _buildPeriodChip(
      {required String label, required ReportPeriod period}) {
    final selected = (_selectedPeriod == period);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.blueAccent,
      onSelected: (selectedVal) {
        if (selectedVal) {
          setState(() => _selectedPeriod = period);
          _fetchAnalyticsData();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // A gradient behind the card's content
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFDFCFB), Color(0xFFF3F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : errorMessage.isNotEmpty
                  ? SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _buildOverviewContent(context),
        ),
      ),
    );
  }

  Widget _buildOverviewContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Overview Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildPeriodSelector(),
          const SizedBox(height: 20),

          // Sales Trend (Line Chart)
          Text(
            'Sales Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries>[
                LineSeries<_SalesData, DateTime>(
                  dataSource: salesData,
                  xValueMapper: (_SalesData data, _) => data.date,
                  yValueMapper: (_SalesData data, _) => data.amount,
                  name: 'Sales (CR Amount)',
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Distribution (Pie Chart)
          Text(
            'Payment Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: SfCircularChart(
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CircularSeries>[
                PieSeries<_PaymentTypeData, String>(
                  dataSource: paymentTypeData,
                  xValueMapper: (_PaymentTypeData data, _) => data.paymentType,
                  yValueMapper: (_PaymentTypeData data, _) => data.count,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  explode: true,
                  explodeIndex: 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Statistics row
          _buildStatisticsGrid(context),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    // All your stats in a list
    final stats = [
      _StatItem(
        title: 'Total Sales',
        value: totalSales.toString(),
        icon: Icons.shopping_cart_outlined,
      ),
      _StatItem(
        title: 'Enquiries',
        value: totalEnquiries.toString(),
        icon: Icons.help_outline,
      ),
      _StatItem(
        title: 'MTBT Tasks',
        value: totalMTBT.toString(),
        icon: Icons.pending_actions,
      ),
      _StatItem(
        title: 'MOK Pending',
        value: totalMOKPending.toString(),
        icon: Icons.warning_amber_rounded,
      ),
      _StatItem(
        title: 'Conversion Rate',
        value: '${conversionRate.toStringAsFixed(1)}%',
        icon: Icons.trending_up,
      ),
      _StatItem(
        title: 'Notes in Sales',
        value: totalAdditionalNotes.toString(),
        icon: Icons.sticky_note_2_outlined,
      ),
    ];

    // We'll display them in a Wrap for flexible layout on mobile
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceEvenly,
      children: stats.map((item) => _buildStatCard(item)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    // Each stat is a small card
    final deviceWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (deviceWidth - 64) / 2; // 16px margin on both sides, spacing

    return Container(
      width: cardWidth > 150 ? cardWidth : 150,
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(item.icon, color: Colors.blueAccent, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for the Sales trend line chart
class _SalesData {
  final DateTime date;
  final double amount;
  _SalesData(this.date, this.amount);
}

/// Data class for the Payment distribution pie chart
class _PaymentTypeData {
  final String paymentType;
  final double count;
  _PaymentTypeData(this.paymentType, this.count);
}

/// For the statistic cards
class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}
