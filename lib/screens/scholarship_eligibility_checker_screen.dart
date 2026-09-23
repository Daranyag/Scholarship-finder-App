import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scholarship_eligibility_result_screen.dart';

class ScholarshipEligibilityCheckerScreen extends StatefulWidget {
  final Map<String, dynamic> scholarship;
  final bool isTamil;

  const ScholarshipEligibilityCheckerScreen({
    super.key,
    required this.scholarship,
    this.isTamil = false,
  });

  @override
  State<ScholarshipEligibilityCheckerScreen> createState() => _ScholarshipEligibilityCheckerScreenState();
}

class _ScholarshipEligibilityCheckerScreenState extends State<ScholarshipEligibilityCheckerScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profile;
  final Map<String, dynamic> _answers = {};
  final Map<String, dynamic> _profileOverrides = {};

  // For missing profile fields
  final List<String> _missingFields = [];

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Fetch user profile
    final response = await ApiService.getProfile();
    if (response['success'] == true) {
      _profile = response['profile'];
      _determineMissingFields();
    }
    
    setState(() => _isLoading = false);
  }

  void _determineMissingFields() {
    if (_profile == null) return;
    
    final e = widget.scholarship['eligibility'] ?? {};
    
    // Check caste
    final casteReq = (e['caste'] as List<dynamic>?)?.cast<String>() ?? [];
    if (casteReq.isNotEmpty && !casteReq.contains('All') && !casteReq.contains('Any')) {
      if (_profile!['caste'] == null || _profile!['caste'].toString().isEmpty) {
        _missingFields.add('caste');
      }
    }
    
    // Check income
    if (e['incomeMax'] != null) {
      if (_profile!['annualIncome'] == null) {
        _missingFields.add('annualIncome');
      }
    }

    // Check level
    final levelReq = (e['educationLevel'] as List<dynamic>?)?.cast<String>() ?? [];
    if (levelReq.isNotEmpty && !levelReq.contains('All') && !levelReq.contains('Any')) {
      if (_profile!['educationLevel'] == null || _profile!['educationLevel'].toString().isEmpty) {
        _missingFields.add('educationLevel');
      }
    }
    
    // Check stream
    final streamReq = (e['stream'] as List<dynamic>?)?.cast<String>() ?? [];
    if (streamReq.isNotEmpty && !streamReq.contains('All') && !streamReq.contains('Any')) {
      if (_profile!['stream'] == null || _profile!['stream'].toString().isEmpty) {
        _missingFields.add('stream');
      }
    }
  }

  Future<void> _submitEligibility() async {
    // Validate missing fields are filled
    for (final field in _missingFields) {
      if (_profileOverrides[field] == null || _profileOverrides[field].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Please fill all required profile fields.', 'தேவையான அனைத்து விவரங்களையும் நிரப்பவும்.'))),
        );
        return;
      }
    }

    // Validate additional questions are answered
    final additional = widget.scholarship['additionalRequirements'] as List<dynamic>? ?? [];
    for (int i = 0; i < additional.length; i++) {
      final req = additional[i];
      final qId = req['_id']?.toString() ?? i.toString();
      if (_answers[qId] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Please answer all additional questions.', 'தயவுசெய்து அனைத்து கேள்விகளுக்கும் பதிலளிக்கவும்.'))),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'profileOverrides': _profileOverrides,
      'answers': _answers,
    };

    final schId = widget.scholarship['_id'] ?? widget.scholarship['id'] ?? 'dynamic';
    if (schId == 'dynamic') {
      payload['dynamicScholarship'] = widget.scholarship;
    }

    final response = await ApiService.checkEligibility(schId, payload);

    setState(() => _isSubmitting = false);

    if (response['success'] == true) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScholarshipEligibilityResultScreen(
              result: response,
              isTamil: widget.isTamil,
              scholarship: widget.scholarship,
              profileOverrides: _profileOverrides, // Pass them in case user wants to save
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Error evaluating eligibility')),
        );
      }
    }
  }

  Widget _buildMissingField(String field) {
    String label = '';
    List<String>? options;
    TextInputType keyboardType = TextInputType.text;

    switch (field) {
      case 'caste':
        label = _t('Community / Category', 'சமூகம் / வகை');
        options = ['SC', 'ST', 'BC', 'MBC', 'DNC', 'Minority', 'General'];
        break;
      case 'educationLevel':
        label = _t('Education Level', 'கல்வி நிலை');
        options = ['8th', '9th', '10th', '11th', '12th', 'UG Degree', 'PG Degree', 'Ph.D'];
        break;
      case 'stream':
        label = _t('Stream / Course', 'பாடப்பிரிவு');
        options = ['Engineering', 'Medical', 'Arts', 'Science', 'Commerce', 'Vocational'];
        break;
      case 'annualIncome':
        label = _t('Annual Family Income (₹)', 'ஆண்டு குடும்ப வருமானம் (₹)');
        keyboardType = TextInputType.number;
        break;
    }

    if (options != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          value: _profileOverrides[field],
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _profileOverrides[field] = newValue;
            });
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: keyboardType,
          onChanged: (value) {
            if (field == 'annualIncome') {
              _profileOverrides[field] = int.tryParse(value);
            } else {
              _profileOverrides[field] = value;
            }
          },
        ),
      );
    }
  }

  Widget _buildAdditionalRequirement(dynamic req, int index) {
    final qId = req['_id']?.toString() ?? index.toString();
    final question = req['question'] ?? 'Unknown Question';
    final type = req['type'] ?? 'yes_no';

    if (type == 'yes_no') {
      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${index + 1}. $question', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(_t('Yes', 'ஆம்')),
                      value: true,
                      groupValue: _answers[qId],
                      onChanged: (val) => setState(() => _answers[qId] = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(_t('No', 'இல்லை')),
                      value: false,
                      groupValue: _answers[qId],
                      onChanged: (val) => setState(() => _answers[qId] = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('${index + 1}. $question (Type $type not implemented yet)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Check Eligibility', 'தகுதியைச் சரிபார்க்கவும்'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final additional = widget.scholarship['additionalRequirements'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Check My Eligibility', 'எனது தகுதியைச் சரிபார்க்கவும்'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('We need a few more details to accurately determine your eligibility for this scholarship.',
                         'இந்த உதவித்தொகைக்கான உங்கள் தகுதியைத் துல்லியமாக தீர்மானிக்க சில விவரங்கள் தேவை.'),
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            if (_missingFields.isNotEmpty) ...[
              Text(
                _t('Missing Profile Information', 'விடுபட்ட சுயவிவரத் தகவல்'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._missingFields.map((f) => _buildMissingField(f)),
              const Divider(height: 40),
            ],

            if (additional.isNotEmpty) ...[
              Text(
                _t('Additional Eligibility Questions', 'கூடுதல் தகுதி கேள்விகள்'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...additional.asMap().entries.map((e) => _buildAdditionalRequirement(e.value, e.key)),
            ],

            if (_missingFields.isEmpty && additional.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _t('All necessary information is already in your profile!', 'அனைத்து தேவையான தகவல்களும் உங்கள் சுயவிவரத்தில் உள்ளன!'),
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEligibility,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _t('CHECK ELIGIBILITY', 'தகுதியைச் சரிபார்க்கவும்'),
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
