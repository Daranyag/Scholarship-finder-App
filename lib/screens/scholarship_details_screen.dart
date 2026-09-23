import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import 'scholarship_eligibility_checker_screen.dart';
import 'scholarship_eligibility_result_screen.dart';
import 'application_details_screen.dart';
import 'application_readiness_screen.dart';

class ScholarshipDetailsScreen extends StatefulWidget {
  final String scholarshipId;
  final bool isTamil;

  const ScholarshipDetailsScreen({super.key, required this.scholarshipId, this.isTamil = false});

  @override
  State<ScholarshipDetailsScreen> createState() => _ScholarshipDetailsScreenState();
}

class _ScholarshipDetailsScreenState extends State<ScholarshipDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _scholarship;
  Map<String, dynamic>? _matchResult;
  bool _isBookmarked = false;
  String? _dataStale;
  String? _trackingApplicationId;

  // Translation helpers
  String _t(String english, String tamil) => widget.isTamil ? tamil : english;

  @override
  void initState() {
    super.initState();
    _fetchScholarshipDetails();
  }

  Future<void> _fetchScholarshipDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getScholarshipById(widget.scholarshipId);
    
    // Also check if tracked
    final trackRes = await ApiService.getApplications();
    String? trackId;
    if (trackRes['success'] == true) {
      final apps = trackRes['data'] as List<dynamic>;
      final match = apps.firstWhere((a) => (a['scholarship']?['_id'] ?? a['scholarship']) == widget.scholarshipId, orElse: () => null);
      if (match != null) trackId = match['_id'];
    }
    
    if (response['success'] == true) {
      setState(() {
        _scholarship = response['scholarship'];
        _matchResult = response['matchResult'];
        _isBookmarked = response['isBookmarked'] ?? false;
        _dataStale = response['dataStale'];
        _trackingApplicationId = trackId;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'Unable to load scholarship details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final originalState = _isBookmarked;
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    final res = await ApiService.toggleBookmark(widget.scholarshipId, originalState);
    if (res['success'] != true) {
      // Revert if failed
      setState(() {
        _isBookmarked = originalState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Failed to update bookmark.', 'புக்மார்க் செய்வதில் பிழை.'))),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isBookmarked ? _t('♥ Saved', '♥ சேமிக்கப்பட்டது') : _t('Removed from saved', 'நீக்கப்பட்டது'))),
        );
      }
    }
  }

  void _shareScholarship() {
    if (_scholarship == null) return;
    
    final title = _scholarship!['title'] ?? 'Scholarship';
    final org = _scholarship!['organization'] ?? '';
    final url = _scholarship!['applyUrl'] ?? '';
    final desc = _scholarship!['description'] ?? '';

    final textToShare = "$title by $org\n\n$desc\n\nApply here: $url\n\nShared via Tamil Nadu Scholarship Finder";
    Share.share(textToShare);
  }

  Future<void> _handleApplyNow() async {
    final urlString = _scholarship?['applyUrl'];
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Application link unavailable.', 'விண்ணப்ப இணைப்பு கிடைக்கவில்லை.'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationReadinessScreen(
          scholarshipId: widget.scholarshipId,
          applyUrl: urlString,
          isTamil: widget.isTamil,
        ),
      ),
    );
  }

  Future<void> _handleMarkAsApplied() async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    final res = await ApiService.createApplication({'scholarshipId': widget.scholarshipId});
    Navigator.pop(context);

    if (res['success'] == true) {
      final appId = res['data']['_id'];
      setState(() => _trackingApplicationId = appId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationDetailsScreen(applicationId: appId, isTamil: widget.isTamil),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error creating tracking record')));
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Scholarship Details', 'உதவித்தொகை விவரங்கள்'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _scholarship == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Scholarship Details', 'உதவித்தொகை விவரங்கள்'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage ?? _t('Unable to load scholarship details.', 'விவரங்களை ஏற்ற முடியவில்லை.')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchScholarshipDetails,
                child: Text(_t('RETRY', 'மீண்டும் முயற்சி செய்')),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_t('Scholarship Details', 'உதவித்தொகை விவரங்கள்')),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
            tooltip: _t('Save Scholarship', 'உதவித்தொகையை சேமி'),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: _t('Share', 'பகிர்'),
            onPressed: _shareScholarship,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const Divider(height: 32),
            
            _buildEligibilityBanner(),
            const Divider(height: 32),
            
            _buildAboutSection(),
            const Divider(height: 32),
            
            _buildBenefitsSection(),
            const Divider(height: 32),
            
            _buildEligibilitySection(),
            const Divider(height: 32),
            
            _buildRequiredDocumentsSection(),
            const Divider(height: 32),
            
            _buildImportantDatesSection(),
            const Divider(height: 32),
            
            _buildOfficialSourceSection(),
            
            const SizedBox(height: 100), // padding for bottom button
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildHeaderSection() {
    final title = _scholarship!['title'] ?? 'Unknown Scholarship';
    final org = _scholarship!['organization'] ?? _t('Provider: Not available', 'வழங்குபவர்: கிடைக்கவில்லை');
    final deadline = _scholarship!['deadline'] ?? _t('Not available', 'கிடைக்கவில்லை');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.business, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                org,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.event, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              '${_t('Deadline:', 'கடைசி தேதி:')} $deadline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red.shade900),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEligibilityBanner() {
    if (_matchResult == null) return const SizedBox.shrink();

    final status = _matchResult!['status'];
    Color color;
    IconData icon;
    String label;
    String actionLabel;
    VoidCallback action;
    String? subtitle;

    if (status == 'LIKELY_ELIGIBLE') {
      color = Colors.green.shade700;
      icon = Icons.check_circle;
      label = _t('Likely Eligible', 'தகுதி இருக்கலாம்');
      actionLabel = _t('VIEW ELIGIBILITY DETAILS', 'தகுதி விவரங்களை பார்');
      action = () => _openResultScreen();
      final matchedCount = _matchResult!['matchedRequirements']?.length ?? 0;
      subtitle = '✓ $matchedCount requirements matched\n❌ 0 failed';
    } else if (status == 'NEEDS_VERIFICATION') {
      color = Colors.orange.shade700;
      icon = Icons.warning_amber_rounded;
      label = _t('Needs Verification', 'சரிபார்ப்பு தேவை');
      actionLabel = _t('VIEW REQUIREMENTS', 'தேவைகளை பார்');
      action = () => _openResultScreen();
      subtitle = '⚠ Verification required for some documents.';
    } else if (status == 'NOT_ENOUGH_INFORMATION') {
      color = Colors.blue.shade700;
      icon = Icons.help_outline;
      label = _t('More Information Required', 'கூடுதல் தகவல் தேவை');
      actionLabel = _t('COMPLETE CHECK', 'சரிபார்ப்பை முடி');
      action = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScholarshipEligibilityCheckerScreen(
              scholarship: _scholarship!,
              isTamil: widget.isTamil,
            ),
          ),
        ).then((_) => _fetchScholarshipDetails());
      };
      subtitle = '⚠ More information is required to determine eligibility.';
    } else {
      color = Colors.red.shade700;
      icon = Icons.cancel;
      label = _t('Does Not Match', 'பொருந்தவில்லை');
      actionLabel = _t('VIEW FULL REASON', 'முழு காரணத்தை பார்');
      action = () => _openResultScreen();
      
      final failedReqs = _matchResult!['failedRequirements'] as List<dynamic>? ?? [];
      if (failedReqs.isNotEmpty) {
        final firstReason = failedReqs[0]['reason'] ?? 'Requirement failed';
        subtitle = '❌ ${failedReqs[0]['label'] ?? 'Requirement'}\n$firstReason';
      } else {
        subtitle = '❌ Requirements not met';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                _t('Your Eligibility', 'உங்கள் தகுதி'),
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: Text(actionLabel),
          )
        ],
      ),
    );
  }

  void _openResultScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScholarshipEligibilityResultScreen(
          result: {
            'success': true,
            'status': _matchResult!['status'],
            'summary': _matchResult!['summary'] ?? '',
            'matchedRequirements': _matchResult!['matchedRequirements'] ?? [],
            'failedRequirements': _matchResult!['failedRequirements'] ?? [],
            'missingRequirements': _matchResult!['missingRequirements'] ?? [],
            'verificationRequired': _matchResult!['verificationRequired'] ?? [],
            'conflicts': _matchResult!['conflicts'] ?? [],
            'requiredDocuments': _matchResult!['requiredDocuments'] ?? [],
            'sources': _matchResult!['sources'] ?? []
          },
          isTamil: widget.isTamil,
          scholarship: _scholarship!,
          profileOverrides: const {},
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('ABOUT', 'பற்றி')),
        Text(
          _scholarship!['description'] ?? _t('Description not available.', 'விளக்கம் கிடைக்கவில்லை.'),
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    final amount = _scholarship!['amount']?.toString();
    final benefits = _scholarship!['benefits'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('BENEFITS', 'நன்மைகள்')),
        if (amount != null && amount.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee, color: Colors.green),
                const SizedBox(width: 8),
                Text('₹$amount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          )
        else
          Text(
            _t('Benefit amount not specified in available source.', 'கிடைக்கக்கூடிய ஆதாரத்தில் நன்மை தொகை குறிப்பிடப்படவில்லை.'),
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        
        if (benefits is List && benefits.isNotEmpty)
          ...benefits.map((b) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(child: Text(b.toString(), style: const TextStyle(fontSize: 15))),
              ],
            ),
          ))
      ],
    );
  }

  Widget _buildEligibilitySection() {
    final eligibilityMap = _scholarship!['eligibility'] as Map<String, dynamic>? ?? {};
    
    if (eligibilityMap.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(_t('ELIGIBILITY', 'தகுதிகள்')),
          Text(_t('Not available', 'கிடைக்கவில்லை')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('ELIGIBILITY', 'தகுதிகள்')),
        ...eligibilityMap.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    e.key[0].toUpperCase() + e.key.substring(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(e.value.toString()),
                ),
              ],
            ),
          );
        })
      ],
    );
  }

  Widget _buildRequiredDocumentsSection() {
    final requiredDocs = _matchResult?['requiredDocuments'] as List<dynamic>? ?? [];
    
    if (requiredDocs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('REQUIRED DOCUMENTS', 'தேவையான ஆவணங்கள்')),
        ...requiredDocs.map((doc) {
          final isMissing = doc['status'] == 'MISSING';
          final isPending = doc['status'] == 'PENDING';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  isMissing ? Icons.error_outline : (isPending ? Icons.pending_actions : Icons.check_circle),
                  color: isMissing ? Colors.red : (isPending ? Colors.orange : Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['documentName'] ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isMissing)
                        Text(_t('❌ Missing', '❌ விடுபட்டுள்ளது'), style: const TextStyle(color: Colors.red, fontSize: 12))
                      else if (isPending)
                        Text(_t('Verification: Pending', 'சரிபார்ப்பு: நிலுவையில் உள்ளது'), style: const TextStyle(color: Colors.orange, fontSize: 12))
                      else
                        Text(_t('✓ Uploaded', '✓ பதிவேற்றப்பட்டது'), style: const TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          );
        })
      ],
    );
  }

  Widget _buildImportantDatesSection() {
    final start = _scholarship!['applicationStartDate'] ?? _t('Not specified in available source.', 'குறிப்பிடப்படவில்லை.');
    final deadline = _scholarship!['deadline'] ?? _t('Not specified in available source.', 'குறிப்பிடப்படவில்லை.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('IMPORTANT DATES', 'முக்கிய தேதிகள்')),
        Row(
          children: [
            const Icon(Icons.date_range, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Applications Open', 'விண்ணப்பம் தொடக்கம்'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(start),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.event_busy, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Application Deadline', 'கடைசி தேதி'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(deadline, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfficialSourceSection() {
    final srcUrl = _scholarship!['applyUrl'] ?? _scholarship!['officialSourceUrl'];
    final lastUpdated = _scholarship!['updatedAt']?.toString().split('T')[0] ?? _t('Not available', 'கிடைக்கவில்லை');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('OFFICIAL SOURCE', 'அதிகாரப்பூர்வ ஆதாரம்')),
        if (srcUrl != null && srcUrl.isNotEmpty)
          InkWell(
            onTap: () async {
              final Uri url = Uri.parse(srcUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: Row(
              children: [
                const Icon(Icons.public, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _t('View Official Source', 'அதிகாரப்பூர்வ ஆதாரத்தை பார்'),
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ],
            ),
          )
        else
          Text(_t('Source URL not provided.', 'ஆதார இணைப்பு வழங்கப்படவில்லை.')),
        
        const SizedBox(height: 8),
        Text('${_t('Last Updated:', 'கடைசியாக புதுப்பிக்கப்பட்டது:')} $lastUpdated', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        if (_dataStale == 'stale')
           Padding(
             padding: const EdgeInsets.only(top: 4.0),
             child: Text('⚠ ${_t('Information may be outdated', 'தகவல் காலாவதியாக இருக்கலாம்')}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
           ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final status = _scholarship!['status'] ?? 'ACTIVE';
    final isExpired = status == 'EXPIRED' || _scholarship!['deadline'] == 'Expired';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_trackingApplicationId != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ApplicationDetailsScreen(applicationId: _trackingApplicationId!, isTamil: widget.isTamil)),
                  ).then((_) => _fetchScholarshipDetails());
                },
                icon: const Icon(Icons.assignment),
                label: Text(_t('VIEW APPLICATION', 'விண்ணப்பத்தை பார்க்கவும்')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: isExpired ? null : _handleMarkAsApplied,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_t('MARK APPLIED', 'விண்ணப்பித்ததாக குறி'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: isExpired
                        ? ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, minimumSize: const Size(double.infinity, 50)),
                            child: Text(_t('Deadline Passed', 'கடைசி தேதி முடிந்தது'), style: const TextStyle(fontSize: 16)),
                          )
                        : ElevatedButton(
                            onPressed: _handleApplyNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(_t('APPLY NOW', 'இப்போதே விண்ணப்பிக்கவும்'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
