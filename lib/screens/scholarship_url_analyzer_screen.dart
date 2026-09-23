import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'scholarship_url_analysis_result_screen.dart';

class ScholarshipUrlAnalyzerScreen extends StatefulWidget {
  const ScholarshipUrlAnalyzerScreen({super.key});

  @override
  State<ScholarshipUrlAnalyzerScreen> createState() => _ScholarshipUrlAnalyzerScreenState();
}

class _ScholarshipUrlAnalyzerScreenState extends State<ScholarshipUrlAnalyzerScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _analyzeUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      setState(() {
        _errorMessage = context.read<LanguageProvider>().isEnglish 
            ? 'Please enter a valid scholarship website URL.'
            : 'சரியான உதவித்தொகை இணையதள URL-ஐ உள்ளிடவும்.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.analyzeUrl(url);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScholarshipUrlAnalysisResultScreen(
            resultData: result,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? (context.read<LanguageProvider>().isEnglish ? 'Analysis Failed' : 'பகுப்பாய்வு தோல்வியடைந்தது');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = context.watch<LanguageProvider>().isEnglish;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Analyze Scholarship' : 'உதவித்தொகையை பகுப்பாய்வு செய்யவும்'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEnglish ? 'Paste a scholarship website URL' : 'உதவித்தொகை இணையதள URL-ஐ உள்ளிடவும்',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeUrl,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : Text(isEnglish ? 'ANALYZE' : 'பகுப்பாய்வு செய்யவும்'),
            ),
            const SizedBox(height: 32),
            Text(
              isEnglish ? 'Supported:\nOfficial government scholarship websites' : 'ஆதரவு:\nஅதிகாரப்பூர்வ அரசு உதவித்தொகை இணையதளங்கள்',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
