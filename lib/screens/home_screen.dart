import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'scholarship_details_screen.dart';
import 'eligibility_checker_screen.dart';
import 'scholarship_eligibility_checker_screen.dart';
import 'scholarship_eligibility_result_screen.dart';
import 'applications_screen.dart';
import 'data_monitor_screen.dart';
import 'search_scholarships_screen.dart';
import 'settings_screen.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_button.dart';
import '../theme.dart';
import 'search_scholarships_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider;
  
  const HomeScreen({super.key, required this.authProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isTamil = false;
  bool _isLoading = true;
  bool _isProfileIncomplete = false;

  Map<String, dynamic> _counts = {
    'all': 0,
    'likelyEligible': 0,
    'needsVerification': 0,
    'moreInformationRequired': 0,
    'doesNotMatch': 0
  };

  List<dynamic> _all = [];
  List<dynamic> _likelyEligible = [];
  List<dynamic> _needsVerification = [];
  List<dynamic> _moreInformationRequired = [];
  List<dynamic> _doesNotMatch = [];

  String _t(String en, String ta) => _isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkProfileCompleteness();
    _fetchMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkProfileCompleteness() async {
    final res = await ApiService.getProfile();
    if (res['success'] == true) {
      final data = res['profile'];
      if (data == null || 
          data['caste'] == null || 
          data['annualIncome'] == null || 
          data['educationLevel'] == null) {
        if (mounted) setState(() => _isProfileIncomplete = true);
      } else {
        if (mounted) setState(() => _isProfileIncomplete = false);
      }
    }
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    
    final res = await ApiService.getMatches();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _counts = res['counts'] ?? _counts;
          _all = res['all'] ?? [];
          _likelyEligible = res['likelyEligible'] ?? [];
          _needsVerification = res['needsVerification'] ?? [];
          _moreInformationRequired = res['moreInformationRequired'] ?? [];
          _doesNotMatch = res['doesNotMatch'] ?? [];
        }
      });
    }
  }

  void _handlePerformDetailedCheck(Map<String, dynamic> scholarship) async {
    // Show a small loader, hit checkEligibility directly, then open result screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final response = await ApiService.checkEligibility(scholarship['_id'] ?? scholarship['id'], {});
    
    if (mounted) Navigator.pop(context); // close loader

    if (response['success'] == true) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScholarshipEligibilityResultScreen(
              result: response,
              isTamil: _isTamil,
              scholarship: scholarship,
              profileOverrides: const {},
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Failed to load result', 'முடிவை ஏற்ற முடியவில்லை'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _t('Tamil Nadu Scholarships', 'தமிழ்நாடு உதவித்தொகைகள்'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Row(
            children: [
              const Text('TA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Switch(
                value: !_isTamil,
                activeColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _isTamil = !val;
                  });
                },
              ),
              const Text('EN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: _t('Search', 'தேடு'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchScholarshipsScreen(isTamil: _isTamil)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: _t('Data Monitor', 'தரவு கண்காணிப்பு'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DataMonitorScreen(isTamil: _isTamil)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            tooltip: _t('My Applications', 'எனது விண்ணப்பங்கள்'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ApplicationsScreen(isTamil: _isTamil)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: _t('Settings', 'அமைப்புகள்'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    authProvider: widget.authProvider,
                    isTamil: _isTamil,
                    onLanguageChanged: (val) {
                      setState(() {
                        _isTamil = val;
                      });
                    },
                  ),
                ),
              );
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: [
            Tab(text: '${_t('All', 'அனைத்து')} (${_counts['all']})'),
            Tab(text: '${_t('Likely Eligible', 'தகுதி இருக்கலாம்')} (${_counts['likelyEligible']})'),
            Tab(text: '${_t('Needs Verification', 'சரிபார்ப்பு தேவை')} (${_counts['needsVerification']})'),
            Tab(text: '${_t('More Info Required', 'கூடுதல் தகவல் தேவை')} (${_counts['moreInformationRequired']})'),
            Tab(text: '${_t('Does Not Match', 'பொருந்தவில்லை')} (${_counts['doesNotMatch']})'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isProfileIncomplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('Complete your eligibility profile to improve scholarship matching.',
                         'உதவித்தொகை பொருத்தத்தை மேம்படுத்த உங்கள் சுயவிவரத்தை பூர்த்தி செய்யவும்.'),
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
                          .then((_) {
                            _checkProfileCompleteness();
                            _fetchMatches();
                          });
                    },
                    child: Text(_t('COMPLETE PROFILE', 'பூர்த்தி செய்')),
                  )
                ],
              ),
            ),
            
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_all, 'No scholarships found.', 'எந்த உதவித்தொகையும் கிடைக்கவில்லை.'),
                      _buildList(_likelyEligible, 'No scholarships currently match all available profile information.', 'உங்கள் தகவல்களுடன் பொருந்தக்கூடிய உதவித்தொகைகள் இல்லை.'),
                      _buildList(_needsVerification, 'No scholarships currently require additional verification.', 'கூடுதல் சரிபார்ப்பு தேவைப்படும் உதவித்தொகைகள் இல்லை.'),
                      _buildList(_moreInformationRequired, 'No scholarships require more information from you.', 'உங்களிடம் இருந்து கூடுதல் தகவல் தேவைப்படும் உதவித்தொகைகள் இல்லை.'),
                      _buildList(_doesNotMatch, 'No mismatched scholarships.', 'பொருந்தாத உதவித்தொகைகள் எதுவும் இல்லை.'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EligibilityCheckerScreen(isTamil: _isTamil),
            ),
          );
        },
        icon: const Icon(Icons.fact_check),
        label: Text(_isTamil ? 'தகுதி சரிபார்ப்பு' : 'Check Eligibility'),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String emptyEn, String emptyTa) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _t(emptyEn, emptyTa),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildCard(items[index]);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> scholarship) {
    final status = scholarship['status'];

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'LIKELY_ELIGIBLE') {
      statusColor = Colors.green.shade700;
      statusLabel = _t('Likely Eligible', 'தகுதி இருக்கலாம்');
      statusIcon = Icons.check_circle;
    } else if (status == 'NEEDS_VERIFICATION') {
      statusColor = Colors.orange.shade700;
      statusLabel = _t('Needs Verification', 'சரிபார்ப்பு தேவை');
      statusIcon = Icons.warning_amber_rounded;
    } else if (status == 'NOT_ENOUGH_INFORMATION') {
      statusColor = Colors.blue.shade700;
      statusLabel = _t('More Info Required', 'கூடுதல் தகவல் தேவை');
      statusIcon = Icons.help_outline;
    } else if (status == 'DOES_NOT_MEET_LISTED_REQUIREMENTS') {
      statusColor = Colors.red.shade700;
      statusLabel = _t('Does Not Match', 'பொருந்தவில்லை');
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.grey;
      statusLabel = _t('Unknown', 'தெரியவில்லை');
      statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scholarship['title'] ?? 'Unknown Scholarship',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  scholarship['organization'] ?? 'Unknown Provider',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  scholarship['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${_t('Deadline:', 'கடைசி தேதி:')} ${scholarship['deadline'] ?? _t('Not available', 'கிடைக்கவில்லை')}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Action Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScholarshipDetailsScreen(
                          scholarshipId: scholarship['_id'] ?? scholarship['id'],
                          isTamil: _isTamil,
                        ),
                      ),
                    );
                  },
                  child: Text(_t('VIEW DETAILS', 'விவரங்களை பார்')),
                ),
                if (status == 'DOES_NOT_MEET_LISTED_REQUIREMENTS')
                  ElevatedButton(
                    onPressed: () => _handlePerformDetailedCheck(scholarship),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade900,
                      elevation: 0,
                    ),
                    child: Text(_t('WHY?', 'ஏன்?')),
                  )
                else if (status == 'NOT_ENOUGH_INFORMATION')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScholarshipEligibilityCheckerScreen(
                            scholarship: scholarship,
                            isTamil: _isTamil,
                          ),
                        ),
                      ).then((_) => _fetchMatches()); // refresh after checking
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade900,
                      elevation: 0,
                    ),
                    child: Text(_t('CHECK ELIGIBILITY', 'தகுதியை சரிபார்')),
                  )
                else if (status == 'NEEDS_VERIFICATION')
                  ElevatedButton(
                    onPressed: () => _handlePerformDetailedCheck(scholarship),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange.shade900,
                      elevation: 0,
                    ),
                    child: Text(_t('VIEW REQUIREMENTS', 'தேவைகளை பார்')),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _handlePerformDetailedCheck(scholarship),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade900,
                      elevation: 0,
                    ),
                    child: Text(_t('VIEW ELIGIBILITY', 'தகுதியை பார்')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
