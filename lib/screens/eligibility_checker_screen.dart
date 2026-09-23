import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'scholarship_eligibility_checker_screen.dart';
import 'eligibility_extraction_result_screen.dart';

class EligibilityCheckerScreen extends StatefulWidget {
  final bool isTamil;

  const EligibilityCheckerScreen({super.key, required this.isTamil});

  @override
  State<EligibilityCheckerScreen> createState() => _EligibilityCheckerScreenState();
}

class _EligibilityCheckerScreenState extends State<EligibilityCheckerScreen> {
  bool _isLoading = false;
  List<dynamic> _allScholarships = [];
  bool _isSearching = false;
  String _searchQuery = '';

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchScholarships();
  }

  Future<void> _fetchScholarships() async {
    final response = await ApiService.getScholarships();
    if (response['success'] == true && mounted) {
      setState(() {
        _allScholarships = response['scholarships'] ?? [];
      });
    }
  }

  Future<void> _processUniversal(String sourceType, {String? url, String? filePath}) async {
    setState(() => _isLoading = true);
    
    final response = await ApiService.analyzeUniversal(
      sourceType: sourceType,
      url: url,
      filePath: filePath,
    );
    
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EligibilityExtractionResultScreen(
              extractedData: response['extractedData'],
              sourceType: response['sourceType'],
              isTamil: widget.isTamil,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? _t('Analysis failed', 'பகுப்பாய்வு தோல்வியடைந்தது'))),
        );
      }
    }
  }

  void _handleUrlInput() {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Enter Website URL', 'இணையதள URL உள்ளிடவும்')),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(
            hintText: 'https://...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Cancel', 'ரத்து செய்')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (urlController.text.isNotEmpty) {
                _processUniversal('url', url: urlController.text.trim());
              }
            },
            child: Text(_t('Analyze', 'பகுப்பாய்வு செய்யவும்')),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePdfUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      _processUniversal('pdf', filePath: result.files.single.path!);
    }
  }

  Future<void> _handleImageUpload() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _processUniversal('image', filePath: image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Eligibility Checker', 'தகுதி சரிபார்ப்பு'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_t('Analyzing... Please wait.', 'பகுப்பாய்வு செய்கிறது... காத்திருக்கவும்.')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Eligibility Checker', 'தகுதி சரிபார்ப்பு'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t('Check whether you may qualify for a scholarship.', 'நீங்கள் உதவித்தொகைக்கு தகுதியானவரா என்று சரிபார்க்கவும்.'),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              _t('How would you like to check?', 'எப்படி சரிபார்க்க விரும்புகிறீர்கள்?'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Option 1: Scholarship Name (Search)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: const Icon(Icons.search, color: Colors.blue),
                title: Text(_t('Scholarship Name', 'உதவித்தொகை பெயர்'), style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: _t('Search existing scholarships...', 'இருக்கும் உதவித்தொகைகளைத் தேடுங்கள்...'),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                              _isSearching = val.isNotEmpty;
                            });
                          },
                        ),
                        if (_isSearching)
                          ..._allScholarships
                              .where((s) => s['title'].toString().toLowerCase().contains(_searchQuery))
                              .take(3)
                              .map((s) => ListTile(
                                    title: Text(s['title']),
                                    subtitle: Text(s['organization'] ?? ''),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ScholarshipEligibilityCheckerScreen(
                                            scholarship: s,
                                            isTamil: widget.isTamil,
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Website URL
            _buildOptionCard(
              icon: Icons.link,
              title: _t('Website URL', 'இணையதள URL'),
              onTap: _handleUrlInput,
            ),

            const SizedBox(height: 12),

            // Option 3: Upload PDF
            _buildOptionCard(
              icon: Icons.picture_as_pdf,
              title: _t('Upload PDF', 'PDF பதிவேற்றவும்'),
              onTap: _handlePdfUpload,
            ),

            const SizedBox(height: 12),

            // Option 4: Upload Image
            _buildOptionCard(
              icon: Icons.image,
              title: _t('Upload Image', 'படத்தை பதிவேற்றவும்'),
              onTap: _handleImageUpload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
