import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ScholarshipDetailsScreen extends StatefulWidget {
  final String scholarshipId;

  const ScholarshipDetailsScreen({super.key, required this.scholarshipId});

  @override
  State<ScholarshipDetailsScreen> createState() => _ScholarshipDetailsScreenState();
}

class _ScholarshipDetailsScreenState extends State<ScholarshipDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _scholarship;
  Map<String, dynamic>? _matchResult;
  String? _dataStale;
  bool _isTamil = false; // Local state for translation toggle

  // Translation helpers
  String _t(String english, String tamil) => _isTamil ? tamil : english;

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
    
    if (response['success'] == true) {
      setState(() {
        _scholarship = response['scholarship'];
        _matchResult = response['matchResult'];
        _dataStale = response['dataStale'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'Unable to load scholarship details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application link unavailable.')),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_t('Scholarship Details', 'உதவித்தொகை விவரங்கள்'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isTamil = !_isTamil;
              });
            },
            child: Text(
              _isTamil ? 'EN' : 'தமிழ்',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _scholarship != null ? _buildApplyButton() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading scholarship details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchScholarshipDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_scholarship == null) {
      return const Center(child: Text('Scholarship not found.'));
    }

    final scholarship = _scholarship!;
    final eligibility = scholarship['eligibility'] ?? {};
    final documents = (scholarship['documents'] as List<dynamic>?)?.cast<String>() ?? [];
    
    // Check if scholarship is active
    final bool isActive = scholarship['isActive'] ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isActive)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _t('CLOSED', 'மூடப்பட்டது'),
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  Text(
                    scholarship['title'] ?? 'Unknown Title',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scholarship['organization'] ?? 'Unknown Organization',
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      Icon(Icons.currency_rupee, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        scholarship['amount'] ?? 'Amount not specified',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_matchResult != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _matchResult!['matchStatus'] == 'eligible' 
                            ? Icons.check_circle 
                            : _matchResult!['matchStatus'] == 'needs_verification'
                              ? Icons.help_outline
                              : _matchResult!['matchStatus'] == 'possibly_eligible'
                                ? Icons.check_circle_outline
                                : Icons.cancel,
                          color: _matchResult!['matchStatus'] == 'eligible' || _matchResult!['matchStatus'] == 'possibly_eligible'
                            ? Colors.green
                            : _matchResult!['matchStatus'] == 'needs_verification'
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _t('Your Eligibility', 'உங்கள் தகுதி'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_matchResult!['reasons'] as List<dynamic>).map((reason) {
                      bool isGood = reason.toString().toLowerCase().contains('match') || reason.toString().toLowerCase().contains('within');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(isGood ? Icons.check : Icons.info_outline, size: 16, color: isGood ? Colors.green : Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(child: Text(reason.toString(), style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      );
                    }),
                    if (_matchResult!['matchStatus'] == 'eligible' || _matchResult!['matchStatus'] == 'possibly_eligible')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          _t('Eligibility is based on the information currently available from the scholarship source. Please verify the official notification before applying.',
                             'தகுதி உதவித்தொகை மூலம் கிடைக்கும் தகவலின் அடிப்படையில் அமைந்துள்ளது. விண்ணப்பிக்கும் முன் அதிகாரப்பூர்வ அறிவிப்பை சரிபார்க்கவும்.'),
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_dataStale == 'stale' || _dataStale == 'aging')
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _t('⚠ Data may be outdated. Please verify the official source before applying.', 
                                 '⚠ தரவு பழையதாக இருக்கலாம். விண்ணப்பிக்கும் முன் அதிகாரப்பூர்வ மூலத்தைச் சரிபார்க்கவும்.'),
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  _buildSectionHeader(_t('ABOUT', 'விவரங்கள்')),
                  Text(
                    scholarship['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                  
                  const Divider(height: 40),
                  
                  _buildSectionHeader(_t('ELIGIBILITY', 'தகுதி')),
                  _buildInfoRow(_t('Community:', 'சமூகம்:'), _formatList(eligibility['caste'])),
                  _buildInfoRow(_t('Income Limit:', 'வருமான வரம்பு:'), eligibility['incomeMax'] != null ? '₹${eligibility['incomeMax']}' : _t('Not specified', 'குறிப்பிடப்படவில்லை')),
                  _buildInfoRow(_t('Education Level:', 'நிலை:'), _formatList(eligibility['educationLevel'])),
                  _buildInfoRow(_t('Stream:', 'பாடப்பிரிவு:'), _formatList(eligibility['stream'])),
                  _buildInfoRow(_t('Gender:', 'பாலினம்:'), eligibility['gender'] ?? _t('Any', 'எதுவும்')),
                  
                  const Divider(height: 40),
                  
                  _buildSectionHeader(_t('DEADLINE', 'கடைசி தேதி')),
                  Row(
                    children: [
                      const Icon(Icons.event, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        scholarship['deadline'] ?? _t('Not specified', 'குறிப்பிடப்படவில்லை'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 40),
                  
                  _buildSectionHeader(_t('DOCUMENTS REQUIRED', 'தேவையான ஆவணங்கள்')),
                  if (documents.isEmpty)
                    Text(_t('Documents not specified by source.', 'ஆவணங்கள் குறிப்பிடப்படவில்லை.'), style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  else
                    ...documents.map((doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Expanded(child: Text(doc, style: const TextStyle(fontSize: 15))),
                            ],
                          ),
                        )),
                        
                  const Divider(height: 40),
                  
                  _buildSectionHeader(_t('OFFICIAL SOURCE', 'அதிகாரப்பூர்வ மூலம்')),
                  Text(
                    scholarship['sourceName'] ?? 'Unknown Source',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  if (scholarship['sourceUrl'] != null && scholarship['sourceUrl'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () => _launchURL(scholarship['sourceUrl']),
                        child: const Text(
                          'View Official Source',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Last updated
                  if (scholarship['lastUpdated'] != null)
                    Center(
                      child: Text(
                        '${_t("Last updated:", "கடைசியாக புதுப்பிக்கப்பட்டது:")} ${DateTime.parse(scholarship['lastUpdated']).toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatList(dynamic list) {
    if (list == null) return 'Any';
    if (list is List) {
      if (list.isEmpty) return 'Any';
      return list.join(', ');
    }
    return list.toString();
  }

  Widget _buildApplyButton() {
    final scholarship = _scholarship!;
    final bool isActive = scholarship['isActive'] ?? true;
    final String? applyUrl = scholarship['applyUrl'];
    
    final bool hasValidUrl = applyUrl != null && applyUrl.isNotEmpty;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _t('Please verify the eligibility requirements and deadline on the official government website before applying.', 
                   'விண்ணப்பிக்கும் முன் அதிகாரப்பூர்வ இணையதளத்தில் தகுதி மற்றும் கடைசி தேதியை சரிபார்க்கவும்.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!isActive || !hasValidUrl) ? null : () => _launchURL(applyUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  !isActive
                      ? _t('CLOSED', 'மூடப்பட்டது')
                      : !hasValidUrl
                          ? _t('APPLICATION LINK UNAVAILABLE', 'இணைப்பு கிடைக்கவில்லை')
                          : _t('APPLY NOW', 'விண்ணப்பிக்க'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
