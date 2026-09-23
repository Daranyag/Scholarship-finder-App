import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'scholarship_details_screen.dart';

class DataMonitorScreen extends StatefulWidget {
  final bool isTamil;
  const DataMonitorScreen({super.key, required this.isTamil});

  @override
  State<DataMonitorScreen> createState() => _DataMonitorScreenState();
}

class _DataMonitorScreenState extends State<DataMonitorScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _overview;
  List<dynamic> _sources = [];
  List<dynamic> _history = [];
  List<dynamic> _changes = [];

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final futures = await Future.wait([
      ApiService.getDataMonitorOverview(),
      ApiService.getDataMonitorSources(),
      ApiService.getDataMonitorFetchHistory(),
      ApiService.getDataMonitorRecentChanges(),
    ]);

    if (mounted) {
      setState(() {
        _overview = futures[0]['success'] == true ? futures[0]['data'] : null;
        _sources = futures[1]['success'] == true ? futures[1]['data'] : [];
        _history = futures[2]['success'] == true ? futures[2]['data'] : [];
        _changes = futures[3]['success'] == true ? futures[3]['data'] : [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await ApiService.refreshDataMonitor();
    Navigator.pop(context);
    
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Fetching latest scholarship information...', 'புதிய தரவுகள் பெறப்படுகின்றன...'))));
      // Give the backend a few seconds to process, then re-fetch the dashboard
      Future.delayed(const Duration(seconds: 3), () {
        _fetchData();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return _t('Never', 'எப்போதுமில்லை');
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Data & Fetching Monitor', 'தரவு மற்றும் பெறுதல் கண்காணிப்பு')),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildOverviewSection(),
                  const SizedBox(height: 16),
                  _buildSourceHealthSection(),
                  const SizedBox(height: 16),
                  _buildRecentFetchesSection(),
                  const SizedBox(height: 16),
                  _buildRecentChangesSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_t('Live Dashboard', 'நேரடி கண்காணிப்பு'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _handleRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(_t('REFRESH DATA', 'தரவை புதுப்பிக்கவும்')),
        )
      ],
    );
  }

  Widget _buildOverviewSection() {
    if (_overview == null) return const SizedBox.shrink();
    
    final total = _overview!['totalScholarships'] ?? 0;
    final active = _overview!['activeScholarships'] ?? 0;
    final expired = _overview!['expiredScholarships'] ?? 0;
    final other = _overview!['otherScholarships'] ?? 0;
    
    final lastFetch = _overview!['lastFetch'];
    final lastFetchTime = lastFetch != null ? _formatDate(lastFetch['startedAt']) : _t('Never', 'எப்போதுமில்லை');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(total.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text(_t('Total Scholarships', 'மொத்த உதவித்தொகைகள்'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(active.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(_t('Active', 'செயலில் உள்ளது'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(expired.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text(_t('Expired', 'காலாவதியானது'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${_t('Last Successful Fetch:', 'கடைசி வெற்றிகரமான தரவு பெறுதல்:')} $lastFetchTime', style: const TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSourceHealthSection() {
    if (_sources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('SOURCE HEALTH', 'மூல நிலை'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _sources.map((src) {
              final isSuccess = src['lastRunStatus'] == 'SUCCESS' || src['lastRunStatus'] == 'SUCCESS_WITH_WARNINGS';
              final icon = isSuccess ? Icons.check_circle : (src['lastRunStatus'] == 'FAILED' ? Icons.cancel : Icons.warning);
              final color = isSuccess ? Colors.green : (src['lastRunStatus'] == 'FAILED' ? Colors.red : Colors.orange);
              
              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(src['sourceName'] ?? ''),
                subtitle: Text('${_t('Last check:', 'கடைசியாக சரிபார்க்கப்பட்டது:')} ${_formatDate(src['lastCheckedAt'])}'),
                trailing: Text(
                  isSuccess ? _t('Working', 'செயலில் உள்ளது') : (src['lastRunStatus'] == 'FAILED' ? _t('Failed', 'தோல்வியடைந்தது') : (src['lastRunStatus'] ?? 'Unknown')),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFetchesSection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('RECENT FETCHES', 'சமீபத்திய தரவு பெறுதல்கள்'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              columns: [
                DataColumn(label: Text(_t('Date', 'தேதி'))),
                DataColumn(label: Text(_t('Status', 'நிலை'))),
                DataColumn(label: Text(_t('Found', 'கண்டுபிடிக்கப்பட்டது'))),
                DataColumn(label: Text(_t('New', 'புதியது'))),
                DataColumn(label: Text(_t('Updated', 'புதுப்பிக்கப்பட்டது'))),
                DataColumn(label: Text(_t('Errors', 'பிழைகள்'))),
              ],
              rows: _history.map((job) {
                final status = job['status'] ?? '';
                final color = status == 'completed' ? Colors.green : (status == 'failed' ? Colors.red : Colors.orange);
                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(job['startedAt']).split(',')[0])),
                    DataCell(Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                    DataCell(Text('${job['recordsDiscovered'] ?? 0}')),
                    DataCell(Text('${job['recordsInserted'] ?? 0}')),
                    DataCell(Text('${job['recordsUpdated'] ?? 0}')),
                    DataCell(Text('${job['sourcesFailed'] ?? 0}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChangesSection() {
    if (_changes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('RECENT CHANGES', 'சமீபத்திய மாற்றங்கள்'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _changes.map((change) {
              final sch = change['scholarshipId'] ?? {};
              final schTitle = sch['title'] ?? 'Unknown';
              final fields = (change['changedFields'] as List<dynamic>? ?? []).join(', ');
              
              return ListTile(
                leading: const Icon(Icons.update, color: Colors.blue),
                title: Text(schTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Changed: $fields\nDate: ${_formatDate(change['detectedAt'])}'),
                isThreeLine: true,
                onTap: () {
                  if (sch['_id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ScholarshipDetailsScreen(scholarshipId: sch['_id'], isTamil: widget.isTamil)),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
