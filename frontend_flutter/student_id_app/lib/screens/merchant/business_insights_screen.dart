import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

enum GraphType { bar, line, pie }
enum InsightsTab { today, week, month, custom }

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
  InsightsTab _currentTab = InsightsTab.today;

  bool _loading = true;

  Map<String, double> chartData = {};
  double totalAmount = 0;
  int totalCount = 0;
  double growthPercent = 0;

  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInsights();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _currentTab = InsightsTab.values[_tabController.index];
    });

    if (_currentTab == InsightsTab.custom && _customRange == null) {
      _pickDateRange();
    } else {
      _loadInsights();
    }
  }

  Future<void> _loadInsights() async {
    setState(() => _loading = true);

    try {
      Map<String, dynamic> insightsRes;
      Map<String, dynamic> currentSummary;
      Map<String, dynamic> previousSummary;

      switch (_currentTab) {
        case InsightsTab.today:
          insightsRes =
              await ApiService.getTodayInsights(widget.merchantMobile);
          currentSummary =
              await ApiService.getMerchantCollectionSummary(
                  widget.merchantMobile, 'today');
          previousSummary =
              await ApiService.getYesterdaySummary(widget.merchantMobile);
          break;

        case InsightsTab.week:
          insightsRes =
              await ApiService.getTodayInsights(widget.merchantMobile);
          currentSummary =
              await ApiService.getMerchantCollectionSummary(
                  widget.merchantMobile, 'week');
          previousSummary =
              await ApiService.getPrevWeekSummary(widget.merchantMobile);
          break;

        case InsightsTab.month:
          insightsRes =
              await ApiService.getMonthlyInsights(widget.merchantMobile);
          currentSummary =
              await ApiService.getMerchantCollectionSummary(
                  widget.merchantMobile, 'month');
          previousSummary =
              await ApiService.getPrevMonthSummary(widget.merchantMobile);
          break;

        case InsightsTab.custom:
          if (_customRange == null) {
            setState(() => _loading = false);
            return;
          }

          final diff = _customRange!.duration;

          insightsRes = await ApiService.getCustomInsights(
            mobile: widget.merchantMobile,
            start: _customRange!.start,
            end: _customRange!.end,
          );

          currentSummary = {
            'total': insightsRes['total'] ?? 0,
            'count': insightsRes['count'] ?? 0,
          };

          final prevRes = await ApiService.getCustomInsights(
            mobile: widget.merchantMobile,
            start: _customRange!.start.subtract(diff),
            end: _customRange!.end.subtract(diff),
          );

          previousSummary = {
            'total': prevRes['total'] ?? 0,
            'count': prevRes['count'] ?? 0,
          };
          break;
      }

      final currentTotal =
          (currentSummary['total'] ?? 0).toDouble();
      final previousTotal =
          (previousSummary['total'] ?? 0).toDouble();

      setState(() {
        chartData = _parseChartData(insightsRes['data']);
        totalAmount = currentTotal;
        totalCount = currentSummary['count'] ?? 0;
        growthPercent = _calculateGrowth(
          currentTotal,
          previousTotal,
        );
        _loading = false;
      });
    } catch (_) {
      setState(() {
        chartData = {};
        totalAmount = 0;
        totalCount = 0;
        growthPercent = 0;
        _loading = false;
      });
    }
  }

  double _calculateGrowth(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  Map<String, double> _parseChartData(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _customRange = picked);
      _loadInsights();
    }
  }

  Widget _growthCard() {
    final positive = growthPercent >= 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              positive ? Icons.trending_up : Icons.trending_down,
              size: 40,
              color: positive ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Growth'),
                const SizedBox(height: 6),
                Text(
                  '${positive ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: positive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsCard() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
              'Total Collection', '₹${totalAmount.toInt()}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
              'Transactions', totalCount.toString()),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph() {
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'No credited transactions found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final values = chartData.values.toList();

    return BarChart(
      BarChartData(
        barGroups: List.generate(
          values.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: Colors.green,
                width: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _graphSelector() {
    return DropdownButton<GraphType>(
      value: _graphType,
      items: const [
        DropdownMenuItem(value: GraphType.bar, child: Text('Bar')),
        DropdownMenuItem(value: GraphType.line, child: Text('Line')),
        DropdownMenuItem(value: GraphType.pie, child: Text('Pie')),
      ],
      onChanged: (v) => setState(() => _graphType = v!),
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
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _graphSelector(),
                  const SizedBox(height: 12),
                  _totalsCard(),
                  const SizedBox(height: 12),
                  _growthCard(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildGraph()),
                ],
              ),
            ),
    );
  }
}
