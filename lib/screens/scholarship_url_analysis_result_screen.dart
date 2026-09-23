import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';

class ScholarshipUrlAnalysisResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ScholarshipUrlAnalysisResultScreen({
    super.key,
    required this.resultData,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = context.watch<LanguageProvider>().isEnglish;

    final String title = resultData['title'] ?? 'Unknown';
    final String organization = resultData['organization'] ?? 'Unknown';
    final String source = resultData['source'] ?? 'Unknown';
    final String amount = resultData['amount']?.toString() ?? (isEnglish ? 'Not Specified' : 'குறிப்பிடப்படவில்லை');
    final String deadline = resultData['deadline']?.toString() ?? (isEnglish ? 'Not Specified' : 'குறிப்பிடப்படவில்லை');
    final String description = resultData['description'] ?? '';
    final String sourceUrl = resultData['sourceUrl'] ?? '';
    final String? applyUrl = resultData['applyUrl'];
    final Map<String, dynamic>? eligibility = resultData['eligibility'];
    
    final String incomeMax = eligibility?['income_max'] != null 
        ? '₹${eligibility!['income_max']}' 
        : (isEnglish ? 'Not Specified' : 'குறிப்பிடப்படவில்லை');
    final String gender = eligibility?['gender'] ?? 'Any';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Scholarship Details' : 'உதவித்தொகை விவரங்கள்'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(organization, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${isEnglish ? "Official Source" : "அதிகாரப்பூர்வ மூலம்"}: $source', style: const TextStyle(color: Colors.grey)),
            
            const Divider(height: 32),
            
            Text(isEnglish ? 'Scholarship Amount' : 'தொகை', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(amount),
            
            const Divider(height: 32),
            
            Text(isEnglish ? 'Eligibility' : 'தகுதி', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${isEnglish ? "Income" : "வருமானம்"}: $incomeMax'),
            Text('${isEnglish ? "Gender" : "பாலினம்"}: $gender'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEnglish ? 'Eligibility information found on this webpage. Needs verification.' : 'தகுதியை சரிபார்க்கவும்',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 32),
            
            Text(isEnglish ? 'Application Deadline' : 'கடைசி தேதி', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(deadline),
            
            const Divider(height: 32),
            
            Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: applyUrl != null ? () => _launchUrl(applyUrl) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEnglish ? 'APPLY NOW' : 'விண்ணப்பிக்க'),
              ),
            ),
            if (applyUrl == null) ...[
              const SizedBox(height: 8),
              Text(
                isEnglish ? 'Application link not found on this webpage.' : 'விண்ணப்ப இணைப்பு காணப்படவில்லை.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _launchUrl(sourceUrl),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEnglish ? 'View Original Website' : 'அசல் இணையதளத்தைப் பார்க்கவும்'),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              isEnglish ? 'Information is extracted from the webpage you provided. Please verify the original official notification before applying.' : 'தகவல்கள் நீங்கள் வழங்கிய இணையதளத்திலிருந்து எடுக்கப்பட்டவை. தயவுசெய்து விண்ணப்பிக்கும் முன் சரிபார்க்கவும்.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
