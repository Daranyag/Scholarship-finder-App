import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ApplicationReadinessScreen extends StatefulWidget {
  final String scholarshipId;
  final String applyUrl;
  final bool isTamil;

  const ApplicationReadinessScreen({
    super.key,
    required this.scholarshipId,
    required this.applyUrl,
    required this.isTamil,
  });

  @override
  State<ApplicationReadinessScreen> createState() => _ApplicationReadinessScreenState();
}

class _ApplicationReadinessScreenState extends State<ApplicationReadinessScreen> {
  bool _isLoading = true;
  String _readinessStatus = 'NOT_READY';
  List<dynamic> _checklist = [];
  bool _isUploading = false;

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchReadiness();
  }

  Future<void> _fetchReadiness() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getApplicationReadiness(widget.scholarshipId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _readinessStatus = res['status'] ?? 'NOT_READY';
          _checklist = res['checklist'] ?? [];
        }
      });
    }
  }

  Future<void> _handleUpload(String docName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'], // Allow docx to test error handling
    );

    if (result == null || result.files.isEmpty) return;
    
    setState(() => _isUploading = true);
    final filePath = result.files.single.path!;
    
    final res = await ApiService.uploadScholarshipDocument(widget.scholarshipId, docName, filePath);
    
    if (mounted) {
      setState(() => _isUploading = false);
      
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Document uploaded successfully!', 'ஆவணம் வெற்றிகரமாக பதிவேற்றப்பட்டது!'))),
        );
        _fetchReadiness();
      } else {
        _showUploadErrorDialog(docName, res);
      }
    }
  }

  void _showUploadErrorDialog(String docName, Map<String, dynamic> res) {
    final errorType = res['errorType'];
    String title = _t('UPLOAD FAILED', 'பதிவேற்றம் தோல்வியடைந்தது');
    String whatHappened = res['message'] ?? _t('Unknown error', 'தெரியாத பிழை');
    String whatToDo = _t('Please try again.', 'மீண்டும் முயற்சிக்கவும்.');
    List<Widget> actions = [];

    if (errorType == 'UNSUPPORTED_FORMAT') {
      title = _t('DOCUMENT FORMAT NOT SUPPORTED', 'ஆதரிக்கப்படாத ஆவணம்');
      whatHappened = _t('Your uploaded file is ${res['uploadedFormat']}. This scholarship accepts ${res['acceptedFormats']}.', 'உங்கள் பதிவேற்றப்பட்ட கோப்பு ${res['uploadedFormat']}. இந்த உதவித்தொகை ${res['acceptedFormats']} ஐ ஏற்கிறது.');
      whatToDo = _t('Please upload the certificate as a PDF or clear JPG/PNG image.', 'சான்றிதழை PDF அல்லது தெளிவான படமாக பதிவேற்றவும்.');
      actions.add(_buildDialogBtn(_t('HOW TO CONVERT', 'எவ்வாறு மாற்றுவது')));
    } else if (errorType == 'FILE_TOO_LARGE') {
      title = _t('FILE TOO LARGE', 'ஆவணம் மிகப் பெரியது');
      whatHappened = _t('Maximum allowed size: ${res['maxSize']}\nYour file: ${res['actualSize']}', 'அதிகபட்ச அளவு: ${res['maxSize']}\nஉங்கள் கோப்பு: ${res['actualSize']}');
      whatToDo = _t('Compress the file or upload a smaller PDF/image.', 'கோப்பை சுருக்கவும் அல்லது சிறியதாக பதிவேற்றவும்.');
      actions.add(_buildDialogBtn(_t('HOW TO REDUCE FILE SIZE', 'கோப்பின் அளவை குறைப்பது எப்படி')));
    } else if (errorType == 'CORRUPTED') {
      title = _t('DOCUMENT COULD NOT BE OPENED', 'ஆவணத்தை திறக்க முடியவில்லை');
      whatHappened = _t('The uploaded file may be corrupted or incomplete.', 'பதிவேற்றப்பட்ட கோப்பு சிதைந்திருக்கலாம்.');
      whatToDo = _t('1. Open original document.\n2. Download again.\n3. Upload new copy.', '1. அசல் ஆவணத்தை திறக்கவும்.\n2. மீண்டும் பதிவிறக்கவும்.\n3. புதிய நகலை பதிவேற்றவும்.');
    } else if (errorType == 'UNREADABLE') {
      title = _t('DOCUMENT IS NOT CLEAR ENOUGH', 'ஆவணம் தெளிவாக இல்லை');
      whatHappened = _t('We cannot reliably read this document.', 'இந்த ஆவணத்தை எங்களால் தெளிவாக படிக்க முடியவில்லை.');
      whatToDo = _t('Please upload a clear photo with no glare.', 'பளபளப்பு இல்லாத தெளிவான புகைப்படத்தை பதிவேற்றவும்.');
    } else if (errorType == 'EXPIRED') {
      title = _t('DOCUMENT EXPIRED', 'ஆவணம் காலாவதியாகிவிட்டது');
      whatHappened = _t('This document expired on: ${res['expiredOn']}', 'இந்த ஆவணம் காலாவதியான தேதி: ${res['expiredOn']}');
      whatToDo = _t('Please obtain an updated certificate before submitting the application.', 'விண்ணப்பத்தை சமர்ப்பிக்கும் முன் புதுப்பிக்கப்பட்ட சான்றிதழைப் பெறவும்.');
    }

    actions.add(_buildDialogBtn(_t('UPLOAD AGAIN', 'மீண்டும் பதிவேற்றவும்'), isPrimary: true, onTap: () {
      Navigator.pop(context);
      _handleUpload(docName);
    }));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(whatHappened, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            const Text('What to do:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(whatToDo),
          ],
        ),
        actions: actions,
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Widget _buildDialogBtn(String text, {bool isPrimary = false, VoidCallback? onTap}) {
    return TextButton(
      onPressed: onTap ?? () => Navigator.pop(context),
      style: TextButton.styleFrom(
        foregroundColor: isPrimary ? Colors.blue.shade900 : Colors.grey.shade700,
        backgroundColor: isPrimary ? Colors.blue.shade50 : null,
      ),
      child: Text(text),
    );
  }

  void _proceedToExternalApply() async {
    final Uri url = Uri.parse(widget.applyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Application Readiness', 'விண்ணப்ப தயார்நிலை')),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  if (_checklist.isNotEmpty) _buildChecklistCard(),
                  const SizedBox(height: 80),
                ],
              ),
              if (_isUploading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildHeaderCard() {
    IconData icon;
    Color color;
    String title;
    String desc;

    switch (_readinessStatus) {
      case 'READY':
        icon = Icons.check_circle;
        color = Colors.green;
        title = _t('READY TO APPLY', 'விண்ணப்பிக்க தயார்');
        desc = _t('You have all the required documents. You can proceed to the official portal.', 'உங்களிடம் தேவையான அனைத்து ஆவணங்களும் உள்ளன.');
        break;
      case 'READY_WITH_VERIFICATION':
        icon = Icons.warning;
        color = Colors.orange;
        title = _t('READY WITH VERIFICATION', 'விண்ணப்பிக்கலாம் (சரிபார்ப்பு தேவை)');
        desc = _t('You can start the application, but some optional/non-blocking documents are missing.', 'நீங்கள் விண்ணப்பத்தை தொடங்கலாம், ஆனால் சில ஆவணங்கள் இல்லை.');
        break;
      case 'MISSING_REQUIRED_DOCUMENTS':
        icon = Icons.error;
        color = Colors.red;
        title = _t('APPLICATION NOT READY', 'விண்ணப்பிக்க இன்னும் தயாராகவில்லை');
        desc = _t('You are missing mandatory documents required before applying.', 'விண்ணப்பிக்கும் முன் தேவையான கட்டாய ஆவணங்கள் உங்களிடம் இல்லை.');
        break;
      default:
        icon = Icons.person_off;
        color = Colors.grey;
        title = _t('PROFILE INCOMPLETE', 'சுயவிவரம் முழுமையடையவில்லை');
        desc = _t('Please complete your profile first.', 'தயவுசெய்து உங்கள் சுயவிவரத்தை முதலில் முடிக்கவும்.');
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('DOCUMENT CHECKLIST', 'ஆவண சரிபார்ப்புப் பட்டியல்'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ..._checklist.map((doc) => _buildDocItem(doc)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(Map<String, dynamic> doc) {
    bool isMissing = doc['status'] == 'MISSING';
    bool isBlocking = doc['isBlocking'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMissing ? (isBlocking ? Colors.red.shade50 : Colors.orange.shade50) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMissing ? (isBlocking ? Colors.red.shade200 : Colors.orange.shade200) : Colors.green.shade200)
      ),
      child: Row(
        children: [
          Icon(
            isMissing ? (isBlocking ? Icons.cancel : Icons.warning) : Icons.check_circle,
            color: isMissing ? (isBlocking ? Colors.red : Colors.orange) : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (isMissing)
                  Text(
                    isBlocking ? _t('Required to apply', 'விண்ணப்பிக்க தேவை') : _t('Optional/Verification recommended', 'விருப்பத்தேர்வு'), 
                    style: TextStyle(fontSize: 12, color: isBlocking ? Colors.red : Colors.orange.shade900)
                  )
              ],
            ),
          ),
          if (isMissing)
            TextButton.icon(
              onPressed: () => _handleUpload(doc['name']),
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(_t('UPLOAD', 'பதிவேற்று')),
            )
          else
            TextButton.icon(
              onPressed: () => _handleUpload(doc['name']),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(_t('REPLACE', 'மாற்றவும்')),
            )
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    bool canApply = _readinessStatus == 'READY' || _readinessStatus == 'READY_WITH_VERIFICATION';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: canApply ? _proceedToExternalApply : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(
            canApply 
              ? _t('PROCEED TO OFFICIAL PORTAL', 'அதிகாரப்பூர்வ இணையதளத்திற்கு செல்லவும்') 
              : _t('COMPLETE REQUIREMENTS TO APPLY', 'விண்ணப்பிக்க தேவைகளை பூர்த்தி செய்யவும்'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
