import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final String applicationId;
  final bool isTamil;

  const ApplicationDetailsScreen({super.key, required this.applicationId, required this.isTamil});

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _application;
  String? _errorMessage;

  final _notesController = TextEditingController();
  final _refController = TextEditingController();

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchApplicationDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplicationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.getApplications(); // A simple hack: fetch all and filter since we didn't expose getApplicationById in ApiService. Wait, we can hit it if we add it, but let's just fetch all and find it. Wait! I didn't add getApplicationById in api_service.dart. I will just fetch all and filter for now to save time, or I can add it. Let's just fetch all and find it since the list is small.
    
    if (res['success'] == true) {
      final apps = res['data'] as List<dynamic>;
      final targetApp = apps.firstWhere((a) => a['_id'] == widget.applicationId, orElse: () => null);
      
      if (targetApp != null) {
        setState(() {
          _application = targetApp;
          _notesController.text = targetApp['notes'] ?? '';
          _refController.text = targetApp['referenceNumber'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = _t('Application not found', 'விண்ணப்பம் காணவில்லை');
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to load details';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateApplication(Map<String, dynamic> data) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    final res = await ApiService.updateApplication(widget.applicationId, data);
    Navigator.pop(context); // close dialog
    
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Updated successfully', 'வெற்றிகரமாக புதுப்பிக்கப்பட்டது'))));
      _fetchApplicationDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Update failed')));
    }
  }

  Future<void> _deleteApplication() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Delete Tracking Record?', 'பதிவை நீக்க வேண்டுமா?')),
        content: Text(_t(
          'Are you sure you want to delete this tracking record? This will not delete your profile or the scholarship itself.',
          'இந்த பதிவை நீக்க விரும்புகிறீர்களா? இது உங்கள் சுயவிவரத்தையோ உதவித்தொகையையோ நீக்காது.'
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('CANCEL', 'ரத்து செய்'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('DELETE', 'நீக்கு')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      final res = await ApiService.deleteApplication(widget.applicationId);
      Navigator.pop(context); // close loading
      
      if (res['success'] == true) {
        Navigator.pop(context); // return to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Delete failed')));
      }
    }
  }

  Future<void> _handleApplyNow(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Leaving App', 'பயன்பாட்டிலிருந்து வெளியேறுகிறீர்கள்')),
        content: Text(_t('Open official scholarship application website?', 'அதிகாரப்பூர்வ இணையதளத்தை திறக்கவா?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('CANCEL', 'ரத்து செய்'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_t('CONTINUE', 'தொடர்க'))),
        ],
      ),
    );

    if (confirm == true) {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showStatusUpdateDialog() {
    String selectedStatus = _application!['status'];
    final statuses = [
      'NOT_APPLIED', 'PLANNING_TO_APPLY', 'APPLICATION_STARTED', 'SUBMITTED', 
      'UNDER_REVIEW', 'DOCUMENT_VERIFICATION', 'APPROVED', 'REJECTED', 'WITHDRAWN'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Update Status', 'நிலையை புதுப்பிக்கவும்')),
        content: StatefulBuilder(
          builder: (context, setStateBuilder) {
            return DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setStateBuilder(() => selectedStatus = val);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('CANCEL', 'ரத்து செய்'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateApplication({'status': selectedStatus});
            },
            child: Text(_t('SAVE', 'சேமி')),
          ),
        ],
      ),
    );
  }

  void _saveNotesAndRef() {
    _updateApplication({
      'referenceNumber': _refController.text,
      'notes': _notesController.text
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: Text(_t('Application Details', 'விண்ணப்ப விவரங்கள்'))), body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null || _application == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Application Details', 'விண்ணப்ப விவரங்கள்'))),
        body: Center(child: Text(_errorMessage ?? 'Error')),
      );
    }

    final sch = _application!['scholarship'] ?? {};
    final timeline = _application!['timeline'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Application Details', 'விண்ணப்ப விவரங்கள்')),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteApplication,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sch['title'] ?? 'Scholarship', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(sch['organization'] ?? 'Provider', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 24),

            // Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Current Status', 'தற்போதைய நிலை'), style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_application!['status'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showStatusUpdateDialog,
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(_t('UPDATE', 'மாற்று')),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Edit reference & notes
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _refController,
                      decoration: InputDecoration(
                        labelText: _t('Reference / Application Number', 'குறிப்பு / விண்ணப்ப எண்'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: _t('Private Notes', 'தனிப்பட்ட குறிப்புகள்'),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _saveNotesAndRef,
                        child: Text(_t('SAVE DETAILS', 'விவரங்களை சேமி')),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            if (timeline.isNotEmpty) ...[
              Text(_t('Timeline', 'காலவரிசை'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: timeline.reversed.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.history, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t['status'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_formatDate(t['date']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  if (t['description'] != null && t['description'].toString().isNotEmpty)
                                    Text(t['description'], style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleApplyNow(sch['applyUrl']),
                icon: const Icon(Icons.open_in_new),
                label: Text(_t('OPEN OFFICIAL PORTAL', 'அதிகாரப்பூர்வ தளத்தை திற')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade900,
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
