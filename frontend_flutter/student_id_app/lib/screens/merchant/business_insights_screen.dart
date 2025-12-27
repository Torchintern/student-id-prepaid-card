import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import 'all_payments_screen.dart';

enum GraphType { bar, pie }

class BusinessInsightsScreen extends StatefulWidget {
  final String merchantMobile;

  const BusinessInsightsScreen({
    super.key,
    required this.merchantMobile,
  });

  @override
  State<BusinessInsightsScreen> createState() =>
      _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState extends State<BusinessInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  GraphType _graphType = GraphType.bar;
  bool _loading = true;
  bool _mounted = true;

  late Map<String, double> _todayData;
  late Map<String, double> _monthlyData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _todayData = {};
    _monthlyData = {};
    _loadData();
  }

  @override
  void dispose() {
    _mounted = false;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final txns =
        await ApiService.getMerchantTransactions(widget.merchantMobile);

    if (!_mounted) return;

    final today = DateTime.now();

    double morning = 0, afternoon = 0, evening = 0;
    final Map<String, double> monthly = {};

    for (final t in txns) {
      if (t['type'] != 'CREDIT' || t['status'] != 'SUCCESS') continue;

      final dt = DateTime.parse(t['created_at']);
      final amount = double.parse(t['amount'].toString());

      if (dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day) {
        if (dt.hour >= 6 && dt.hour < 12) {
          morning += amount;
        } else if (dt.hour >= 12 && dt.hour < 18) {
          afternoon += amount;
        } else {
          evening += amount;
        }
      }

      final key = '${dt.day}/${dt.month}';
      monthly[key] = (monthly[key] ?? 0) + amount;
    }

    if (!_mounted) return;

    setState(() {
      _todayData = {
        'Morning': morning,
        'Afternoon': afternoon,
        'Evening': evening,
      };
      _monthlyData = monthly;
      _loading = false;
    });
  }

  Widget _graphSelector() {
    return DropdownButton<GraphType>(
      value: _graphType,
      items: const [
        DropdownMenuItem(
            value: GraphType.bar, child: Text('Bar Graph')),
        DropdownMenuItem(
            value: GraphType.pie, child: Text('Pie Chart')),
      ],
      onChanged: (v) {
        if (!_mounted) return;
        setState(() => _graphType = v!);
      },
    );
  }

  Widget _buildGraph(Map<String, double> data) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return const Center(
        child: Text(
          'No collection data available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final keys = data.keys.toList(growable: false);

    if (_graphType == GraphType.bar) {
      return BarChart(
        BarChartData(
          barGroups: List.generate(keys.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[keys[index]]!,
                  color: Colors.green,
                  width: 22,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= keys.length) {
                    return const SizedBox();
                  }
                  return Text(keys[i]);
                },
              ),
            ),
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: data.entries
            .where((e) => e.value > 0)
            .map(
              (e) => PieChartSectionData(
                value: e.value,
                title: '₹${e.value.toInt()}',
                radius: 60,
                titleStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                _graphSelector(),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildGraph(_todayData),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildGraph(_monthlyData),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
