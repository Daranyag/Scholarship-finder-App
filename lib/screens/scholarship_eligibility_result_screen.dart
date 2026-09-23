import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ScholarshipEligibilityResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final bool isTamil;
  final Map<String, dynamic> scholarship;
  final Map<String, dynamic> profileOverrides;

  const ScholarshipEligibilityResultScreen({
    super.key,
    required this.result,
    required this.isTamil,
    required this.scholarship,
    required this.profileOverrides,
  });

  @override
  State<ScholarshipEligibilityResultScreen> createState() => _ScholarshipEligibilityResultScreenState();
}

class _ScholarshipEligibilityResultScreenState extends State<ScholarshipEligibilityResultScreen> {
  String _t(String en, String ta) => widget.isTamil ? ta : en;

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Application link unavailable.', 'பயன்பாட்டு இணைப்பு கிடைக்கவில்லை.'))),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (widget.profileOverrides.isEmpty) return;

    final response = await ApiService.updateProfile(widget.profileOverrides);
    if (mounted) {
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Profile updated successfully!', 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to update profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.result['status'];
    final summary = widget.result['summary'] ?? '';
    final matchedRequirements = widget.result['matchedRequirements'] as List<dynamic>? ?? [];
    final failedRequirements = widget.result['failedRequirements'] as List<dynamic>? ?? [];
    final missingRequirements = widget.result['missingRequirements'] as List<dynamic>? ?? [];
    final verificationRequired = widget.result['verificationRequired'] as List<dynamic>? ?? [];
    final conflicts = widget.result['conflicts'] as List<dynamic>? ?? [];
    final requiredDocuments = widget.result['requiredDocuments'] as List<dynamic>? ?? [];
    final sources = widget.result['sources'] as List<dynamic>? ?? [];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'LIKELY_ELIGIBLE') {
      statusColor = Colors.green.shade700;
      statusText = _t('Likely Eligible', 'தகுதி இருக்கலாம்');
      statusIcon = Icons.check_circle;
    } else if (status == 'NEEDS_VERIFICATION') {
      statusColor = Colors.orange.shade700;
      statusText = _t('Needs Verification', 'தகுதியை சரிபார்க்க வேண்டும்');
      statusIcon = Icons.warning_amber_rounded;
    } else if (status == 'NOT_ENOUGH_INFORMATION') {
      statusColor = Colors.blue.shade700;
      statusText = _t('Not Enough Information', 'போதுமான தகவல் இல்லை');
      statusIcon = Icons.help_outline;
    } else { // DOES_NOT_MEET_LISTED_REQUIREMENTS
      statusColor = Colors.red.shade700;
      statusText = _t('Does Not Meet Listed Requirements', 'குறிப்பிட்ட தகுதிகளை பூர்த்தி செய்யவில்லை');
      statusIcon = Icons.cancel;
    }

    final bool isActive = widget.scholarship['isActive'] ?? true;
    final String? applyUrl = widget.scholarship['applyUrl'];
    final bool hasValidUrl = applyUrl != null && applyUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Eligibility Result', 'தகுதி முடிவு'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.scholarship['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      summary,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // MATCHED REQUIREMENTS
            if (matchedRequirements.isNotEmpty) ...[
              _buildSectionTitle(_t('Matched Requirements', 'பொருத்தமான தேவைகள்')),
              _buildRequirementList(matchedRequirements, Icons.check_circle, Colors.green),
              const SizedBox(height: 16),
            ],

            // FAILED REQUIREMENTS
            if (failedRequirements.isNotEmpty) ...[
              _buildSectionTitle(_t('Failed Requirements', 'தோல்வியுற்ற தேவைகள்')),
              _buildRequirementList(failedRequirements, Icons.cancel, Colors.red),
              const SizedBox(height: 16),
            ],

            // MISSING INFORMATION
            if (missingRequirements.isNotEmpty) ...[
              _buildSectionTitle(_t('Missing Information', 'விடுபட்ட தகவல்')),
              _buildRequirementList(missingRequirements, Icons.help, Colors.blue),
              const SizedBox(height: 16),
            ],

            // VERIFICATION REQUIRED
            if (verificationRequired.isNotEmpty) ...[
              _buildSectionTitle(_t('Verification Required', 'சரிபார்க்கப்பட வேண்டியவை')),
              _buildRequirementList(verificationRequired, Icons.warning_amber_rounded, Colors.orange),
              const SizedBox(height: 16),
            ],

            // CONFLICTS
            if (conflicts.isNotEmpty) ...[
              _buildSectionTitle(_t('Conflicts', 'முரண்பாடுகள்')),
              _buildRequirementList(conflicts, Icons.error_outline, Colors.orange.shade900),
              const SizedBox(height: 16),
            ],

            // REQUIRED DOCUMENTS
            if (requiredDocuments.isNotEmpty) ...[
              _buildSectionTitle(_t('Required Documents', 'தேவையான ஆவணங்கள்')),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: requiredDocuments.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.description, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(doc['name'] ?? '', style: const TextStyle(fontSize: 15))),
                            Text(
                              doc['status'] ?? '',
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // OFFICIAL SOURCE
            if (sources.isNotEmpty) ...[
              _buildSectionTitle(_t('Official Source', 'அதிகாரப்பூர்வ மூலம்')),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: sources.map((s) {
                      return ListTile(
                        leading: const Icon(Icons.link, color: Colors.blue),
                        title: Text(s['name'] ?? 'Source'),
                        subtitle: Text(s['url'] ?? ''),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchURL(s['url']),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ACTIONS
            Row(
              children: [
                if (widget.profileOverrides.isNotEmpty)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t('Update Profile', 'சுயவிவரத்தை புதுப்பி'), textAlign: TextAlign.center),
                    ),
                  ),
                if (widget.profileOverrides.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_t('Check Again', 'மீண்டும் சரிபார்'), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 48),

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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget _buildRequirementList(List<dynamic> items, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_t('Your Info:', 'உங்கள் தகவல்:'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(item['userValue'] ?? '-', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_t('Required:', 'தேவை:'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(item['requiredValue'] ?? '-', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (item['reason'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              item['reason'],
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
