import 'package:flutter/material.dart';
import 'scholarship_eligibility_checker_screen.dart';

class EligibilityExtractionResultScreen extends StatelessWidget {
  final Map<String, dynamic> extractedData;
  final String sourceType;
  final bool isTamil;

  const EligibilityExtractionResultScreen({
    super.key,
    required this.extractedData,
    required this.sourceType,
    required this.isTamil,
  });

  String _t(String en, String ta) => isTamil ? ta : en;

  @override
  Widget build(BuildContext context) {
    final title = extractedData['title'] ?? 'Unknown Scholarship';
    final sourceName = extractedData['sourceName'] ?? 'Unknown Source';
    final eligibility = extractedData['eligibility'] ?? {};
    
    final caste = (eligibility['caste'] as List<dynamic>?)?.cast<String>() ?? [];
    final educationLevel = (eligibility['educationLevel'] as List<dynamic>?)?.cast<String>() ?? [];
    final stream = (eligibility['stream'] as List<dynamic>?)?.cast<String>() ?? [];
    final incomeMax = eligibility['incomeMax'];
    final deadline = extractedData['deadline'];

    // For display
    final Map<String, dynamic> fakeScholarshipFormat = {
      'title': title,
      'sourceName': sourceName,
      'eligibility': eligibility,
      'deadline': deadline,
      'additionalRequirements': [] // In a real app we might extract these too
    };

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Extraction Result', 'பிரித்தெடுத்தல் முடிவு'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sourceType == 'pdf' || sourceType == 'image')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('Eligibility is based on the information extracted from the file you provided. Verify the latest official notification before applying.',
                           'நீங்கள் வழங்கிய கோப்பிலிருந்து எடுக்கப்பட்ட தகவலின் அடிப்படையில் தகுதி கணக்கிடப்பட்டுள்ளது. விண்ணப்பிக்கும் முன் அதிகாரப்பூர்வ அறிவிப்பைச் சரிபார்க்கவும்.'),
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Scholarship Identified', 'உதவித்தொகை அடையாளம் காணப்பட்டது'),
                      style: TextStyle(fontSize: 14, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_t('Source:', 'மூலம்:')} $sourceName', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _t('Eligibility information found:', 'கண்டறியப்பட்ட தகுதித் தகவல்:'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildExtractedRow('Category', caste.isNotEmpty ? caste.join(', ') : null),
                    const Divider(),
                    _buildExtractedRow('Income Limit', incomeMax != null ? '₹$incomeMax' : null),
                    const Divider(),
                    _buildExtractedRow('Education Level', educationLevel.isNotEmpty ? educationLevel.join(', ') : null),
                    const Divider(),
                    _buildExtractedRow('Stream/Course', stream.isNotEmpty ? stream.join(', ') : null),
                    const Divider(),
                    _buildExtractedRow('Deadline', deadline ?? _t('Not found in provided information', 'வழங்கப்பட்ட தகவலில் கிடைக்கவில்லை'), isDeadline: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScholarshipEligibilityCheckerScreen(
                        scholarship: fakeScholarshipFormat,
                        isTamil: isTamil,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _t('CONTINUE ELIGIBILITY CHECK', 'தகுதி சரிபார்ப்பைத் தொடரவும்'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedRow(String label, String? value, {bool isDeadline = false}) {
    bool hasValue = value != null && value.isNotEmpty && !isDeadline;
    if (isDeadline && value != null && value != 'Not found in provided information' && value != 'வழங்கப்பட்ட தகவலில் கிடைக்கவில்லை') {
      hasValue = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            hasValue ? Icons.check_circle : Icons.radio_button_unchecked,
            color: hasValue ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: hasValue ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          if (value != null)
            Text(
              value,
              style: TextStyle(
                color: hasValue ? Colors.black87 : Colors.grey.shade600,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}
