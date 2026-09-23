import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'application_details_screen.dart';
import 'package:intl/intl.dart';

class ApplicationsScreen extends StatefulWidget {
  final bool isTamil;
  const ApplicationsScreen({super.key, required this.isTamil});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _isLoading = true;
  List<dynamic> _applications = [];
  String? _errorMessage;

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getApplications();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _applications = res['data'] ?? [];
        } else {
          _errorMessage = res['message'] ?? _t('Failed to load applications.', 'விண்ணப்பங்களை ஏற்ற முடியவில்லை.');
        }
      });
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return isoString;
    }
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'NOT_APPLIED':
        return {'label': _t('Not Applied', 'விண்ணப்பிக்கவில்லை'), 'icon': Icons.not_interested, 'color': Colors.grey};
      case 'PLANNING_TO_APPLY':
        return {'label': _t('Planning to Apply', 'திட்டமிடப்பட்டுள்ளது'), 'icon': Icons.schedule, 'color': Colors.blue};
      case 'APPLICATION_STARTED':
        return {'label': _t('Application Started', 'தொடங்கப்பட்டது'), 'icon': Icons.edit_document, 'color': Colors.orange};
      case 'SUBMITTED':
        return {'label': _t('Submitted', 'சமர்ப்பிக்கப்பட்டது'), 'icon': Icons.check_circle_outline, 'color': Colors.indigo};
      case 'UNDER_REVIEW':
        return {'label': _t('Under Review', 'பரிசீலனையில் உள்ளது'), 'icon': Icons.rate_review, 'color': Colors.purple};
      case 'DOCUMENT_VERIFICATION':
        return {'label': _t('Document Verification', 'ஆவண சரிபார்ப்பு'), 'icon': Icons.verified_user, 'color': Colors.teal};
      case 'APPROVED':
        return {'label': _t('Approved', 'அனுமதிக்கப்பட்டது'), 'icon': Icons.check_circle, 'color': Colors.green};
      case 'REJECTED':
        return {'label': _t('Rejected', 'நிராகரிக்கப்பட்டது'), 'icon': Icons.cancel, 'color': Colors.red};
      case 'WITHDRAWN':
        return {'label': _t('Withdrawn', 'திரும்பப் பெறப்பட்டது'), 'icon': Icons.undo, 'color': Colors.grey.shade700};
      default:
        return {'label': status, 'icon': Icons.help_outline, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('My Applications', 'எனது விண்ணப்பங்கள்')),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchApplications, child: Text(_t('Retry', 'மீண்டும் முயற்சி செய்')))
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _t('No applications tracked yet.', 'விண்ணப்பங்கள் எதுவும் இல்லை.'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          final sch = app['scholarship'] ?? {};
          final statusConfig = _getStatusConfig(app['status']);
          final appDate = _formatDate(app['applicationDate']);
          final deadline = _formatDate(sch['deadline'] ?? ''); // Wait, scholarship.deadline is usually string, might not be ISO, but _formatDate handles fallback
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicationDetailsScreen(applicationId: app['_id'], isTamil: widget.isTamil),
                  ),
                ).then((_) => _fetchApplications());
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sch['title'] ?? 'Unknown Scholarship',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusConfig['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusConfig['color'].withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusConfig['icon'], size: 16, color: statusConfig['color']),
                          const SizedBox(width: 4),
                          Text(
                            statusConfig['label'],
                            style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Applied On:', 'விண்ணப்பித்த தேதி:'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(appDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_t('Deadline:', 'கடைசி தேதி:'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(deadline.isEmpty ? _t('Not available', 'கிடைக்கவில்லை') : deadline, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          ],
                        ),
                      ],
                    ),
                    if (app['referenceNumber'] != null && app['referenceNumber'].isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Ref: ${app['referenceNumber']}',
                            style: TextStyle(fontFamily: 'monospace', color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
