import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  final AuthProvider? authProvider;

  const ProfileScreen({super.key, this.isInitialSetup = false, this.authProvider});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  
  // Profile Completion
  int _completionPercentage = 0;
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _annualIncomeController = TextEditingController();
  final _institutionController = TextEditingController();

  // Selections
  DateTime? _dateOfBirth;
  String? _gender;
  String? _district;
  String? _caste;
  String? _educationLevel;
  String? _stream;
  String? _yearOfStudy;

  // Constants
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _tnDistricts = [
    'Ariyalur', 'Chengalpattu', 'Chennai', 'Coimbatore', 'Cuddalore',
    'Dharmapuri', 'Dindigul', 'Erode', 'Kallakurichi', 'Kanchipuram',
    'Kanyakumari', 'Karur', 'Krishnagiri', 'Madurai', 'Mayiladuthurai',
    'Nagapattinam', 'Namakkal', 'Nilgiris', 'Perambalur', 'Pudukkottai',
    'Ramanathapuram', 'Ranipet', 'Salem', 'Sivaganga', 'Tenkasi',
    'Thanjavur', 'Theni', 'Thoothukudi', 'Tiruchirappalli', 'Tirunelveli',
    'Tirupathur', 'Tiruppur', 'Tiruvallur', 'Tiruvannamalai', 'Tiruvarur',
    'Vellore', 'Viluppuram', 'Virudhunagar'
  ];
  final List<String> _castes = ['BC', 'MBC', 'SC', 'ST', 'OC', 'DNC'];
  final List<String> _educationLevels = ['10th', '12th', 'Diploma', 'UG Degree', 'PG Degree'];
  final List<String> _streams = ['Arts', 'Science', 'Commerce', 'Engineering', 'Medical', 'Other'];
  final List<String> _yearsOfStudy = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _annualIncomeController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await ApiService.getProfile();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success'] == true) {
          final data = response['data'];
          _completionPercentage = response['profileCompletion'] ?? 0;
          
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _institutionController.text = data['institution'] ?? '';
          
          if (data['annualIncome'] != null) {
            _annualIncomeController.text = data['annualIncome'].toString();
          }

          if (data['dateOfBirth'] != null) {
            _dateOfBirth = DateTime.tryParse(data['dateOfBirth']);
          }

          _gender = data['gender'];
          _district = data['district'];
          _caste = data['caste'];
          _educationLevel = data['educationLevel'];
          _stream = data['stream'];
          _yearOfStudy = data['yearOfStudy'];
          
        } else {
          _errorMessage = response['message'] ?? 'Failed to load profile';
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final profileData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'gender': _gender,
      'district': _district,
      'caste': _caste,
      'educationLevel': _educationLevel,
      'stream': _stream,
      'institution': _institutionController.text,
      'yearOfStudy': _yearOfStudy,
    };

    if (_dateOfBirth != null) {
      profileData['dateOfBirth'] = _dateOfBirth!.toIso8601String();
    }
    
    if (_annualIncomeController.text.isNotEmpty) {
      profileData['annualIncome'] = _annualIncomeController.text;
    }

    final response = await ApiService.updateProfile(profileData);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (response['success'] == true) {
        setState(() {
          _completionPercentage = response['profileCompletion'] ?? 0;
        });

        if (widget.isInitialSetup && response['profileComplete'] == true) {
          // Profile is complete, trigger auth provider to fetch new user state
          // which will automatically route to HomeScreen
          widget.authProvider?.checkToken();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildCompletionWidget(),
                      const SizedBox(height: 24),
                      const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name *',
                        validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date of Birth *',
                              border: const OutlineInputBorder(),
                              errorText: _dateOfBirth == null ? 'Date of birth is required for a complete profile' : null,
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _dateOfBirth == null
                                  ? 'Select Date'
                                  : DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
                              style: TextStyle(
                                color: _dateOfBirth == null ? Colors.black54 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildDropdown(
                        value: _gender,
                        items: _genders,
                        label: 'Gender *',
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                      _buildDropdown(
                        value: _district,
                        items: _tnDistricts,
                        label: 'District (Tamil Nadu) *',
                        onChanged: (val) => setState(() => _district = val),
                      ),
                      const SizedBox(height: 24),
                      const Text('Eligibility Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildDropdown(
                        value: _caste,
                        items: _castes,
                        label: 'Community/Caste *',
                        onChanged: (val) => setState(() => _caste = val),
                      ),
                      _buildTextField(
                        controller: _annualIncomeController,
                        label: 'Annual Family Income (₹) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = int.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Enter a valid non-negative income';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Education', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildDropdown(
                        value: _educationLevel,
                        items: _educationLevels,
                        label: 'Education Level *',
                        onChanged: (val) => setState(() => _educationLevel = val),
                      ),
                      _buildDropdown(
                        value: _stream,
                        items: _streams,
                        label: 'Course/Stream *',
                        onChanged: (val) => setState(() => _stream = val),
                      ),
                      _buildTextField(
                        controller: _institutionController,
                        label: 'Institution/College *',
                      ),
                      _buildDropdown(
                        value: _yearOfStudy,
                        items: _yearsOfStudy,
                        label: 'Year of Study *',
                        onChanged: (val) => setState(() => _yearOfStudy = val),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Profile', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCompletionWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$_completionPercentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _completionPercentage / 100,
            backgroundColor: Colors.blue.shade100,
            color: Colors.blue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your profile to improve scholarship matching.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
