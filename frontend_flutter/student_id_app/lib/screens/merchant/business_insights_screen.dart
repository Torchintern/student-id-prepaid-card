import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

enum GraphType { bar, line, pie }

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

  // Backend data
  Map<String, double> todayData = {};
  Map<String, double> monthData = {};
  double todayGrowth = 0;
  double monthGrowth = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final todayRes =
        await ApiService.getTodayInsights(widget.merchantMobile);
    final monthRes =
        await ApiService.getMonthlyInsights(widget.merchantMobile);

    setState(() {
      todayData =
          Map<String, double>.from(todayRes['data']);
      todayGrowth = todayRes['growth'].toDouble();

      monthData =
          Map<String, double>.from(monthRes['data']);
      monthGrowth = monthRes['growth'].toDouble();

      _loading = false;
    });
  }

  // ================= GRAPH BUILDER =================
  Widget _buildGraph(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    switch (_graphType) {
      case GraphType.line:
        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: data.entries
                    .map((e) => FlSpot(
                          data.keys.toList().indexOf(e.key)
                              .toDouble(),
                          e.value,
                        ))
                    .toList(),
                isCurved: true,
                barWidth: 3,
                color: Colors.blue,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        );

      case GraphType.pie:
        return PieChart(
          PieChartData(
            sections: data.entries
                .map(
                  (e) => PieChartSectionData(
                    title: e.key,
                    value: e.value,
                    radius: 60,
                  ),
                )
                .toList(),
          ),
        );

      case GraphType.bar:
        return BarChart(
          BarChartData(
            barGroups: data.entries
                .map(
                  (e) => BarChartGroupData(
                    x: data.keys.toList().indexOf(e.key),
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: Colors.green,
                        width: 18,
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
    }
  }

  Widget _graphSelector() {
    return DropdownButton<GraphType>(
      value: _graphType,
      items: const [
        DropdownMenuItem(
            value: GraphType.bar, child: Text('Bar')),
        DropdownMenuItem(
            value: GraphType.line, child: Text('Line')),
        DropdownMenuItem(
            value: GraphType.pie, child: Text('Pie')),
      ],
      onChanged: (v) => setState(() => _graphType = v!),
    );
  }

  Widget _growthCard(String title, double value) {
    final bool positive = value >= 0;
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              positive
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: positive ? Colors.green : Colors.red,
              size: 40,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  '${positive ? '+' : ''}${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                        positive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            )
          ],
        ),
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
                      _todayTab(),
                      _monthTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _todayTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 250, child: _buildGraph(todayData)),
          const SizedBox(height: 20),
          _growthCard(
            'Sales growth vs Yesterday',
            todayGrowth,
          ),
        ],
      ),
    );
  }

  Widget _monthTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 250, child: _buildGraph(monthData)),
          const SizedBox(height: 20),
          _growthCard(
            'Sales growth vs Previous Month',
            monthGrowth,
          ),
        ],
      ),
    );
  }
}
