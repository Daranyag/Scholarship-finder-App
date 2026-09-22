import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'scholarship_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const HomeScreen({super.key, required this.authProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  bool _isLoadingScholarships = true;
  List<dynamic> _liveScholarships = [];
  List<dynamic> _matches = [];
  bool _isProfileIncomplete = false;

  final List<String> _categories = [
    'All',
    'Merit-Based',
    'Minority',
    'Women',
    'Need-Based'
  ];

  @override
  void initState() {
    super.initState();
    _checkProfileCompleteness();
    _fetchScholarships();
  }

  void _checkProfileCompleteness() {
    final user = widget.authProvider.user;
    if (user != null) {
      if (user['caste'] == null || user['annualIncome'] == null || 
          user['educationLevel'] == null || user['stream'] == null) {
        setState(() => _isProfileIncomplete = true);
      } else {
        setState(() => _isProfileIncomplete = false);
      }
    }
  }

  Future<void> _fetchScholarships() async {
    setState(() => _isLoadingScholarships = true);
    
    // Fetch both simultaneously
    final results = await Future.wait([
      ApiService.getScholarships(),
      ApiService.getMatches()
    ]);
    
    final response = results[0];
    final matchResponse = results[1];

    if (response['success'] == true) {
      setState(() {
        _liveScholarships = response['scholarships'] ?? [];
        if (matchResponse['success'] == true) {
          _matches = matchResponse['matches'] ?? [];
        }
        _isLoadingScholarships = false;
      });
    } else {
      setState(() => _isLoadingScholarships = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load scholarships')),
        );
      }
    }
  }

  List<dynamic> get _filteredScholarships {
    if (_selectedCategory == 'All') return _liveScholarships;
    return _liveScholarships
        .where((s) => s['category'] == _selectedCategory)
        .toList();
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'group': return Icons.group;
      case 'female': return Icons.female;
      case 'favorite': return Icons.favorite;
      case 'star':
      default: return Icons.star;
    }
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'red': return Colors.red;
      case 'amber':
      default: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authProvider.user;
    final userName = user?['name'] ?? 'Student';
    // Get first name
    final firstName = userName.split(' ')[0];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $firstName!',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Text(
              'Find the best scholarships for you',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            label: const Text('Complete Profile', style: TextStyle(color: Colors.white, fontSize: 13)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    firstName,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              widget.authProvider.logout();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Blue Header with Search Bar
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 20),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for scholarships...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Categories section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    selectedColor: Colors.blue.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Profile completeness prompt
          if (_isProfileIncomplete)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                      const SizedBox(width: 10),
                      const Text(
                        'Your profile is incomplete.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete your profile to find scholarships that match your eligibility.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
                          .then((_) => _checkProfileCompleteness());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete Profile'),
                  ),
                ],
              ),
            ),

          // Scholarships For You
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scholarships For You',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
                        .then((_) => { _checkProfileCompleteness(), _fetchScholarships() });
                  },
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          ),
          
          if (!_isLoadingScholarships && _matches.isEmpty && !_isProfileIncomplete)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('No scholarships currently match your profile.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),

          if (_matches.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final matchObj = _matches[index];
                  final scholarship = matchObj['scholarship'];
                  final matchResult = matchObj['matchResult'];
                  
                  // Determine badge
                  Color badgeColor = Colors.green;
                  String badgeText = '✓ Eligible';
                  if (matchResult['matchStatus'] == 'needs_verification') {
                    badgeColor = Colors.orange;
                    badgeText = '? Verify Eligibility';
                  } else if (matchResult['matchStatus'] == 'possibly_eligible') {
                    badgeColor = Colors.lightGreen;
                    badgeText = 'Possibly Eligible';
                  }

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScholarshipDetailsScreen(
                                scholarshipId: scholarship['_id'] ?? scholarship['id'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: badgeColor),
                                ),
                                child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                scholarship['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                scholarship['amount'] ?? '',
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // All Scholarships List
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'All Scholarships',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoadingScholarships 
              ? const Center(child: CircularProgressIndicator())
              : _filteredScholarships.isEmpty
                ? const Center(
                    child: Text('No scholarships found.',
                        style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
                    onRefresh: _fetchScholarships,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _filteredScholarships.length,
                      itemBuilder: (context, index) {
                        final scholarship = _filteredScholarships[index];
                        final Color sColor = _getColor(scholarship['colorName']);
                        final IconData sIcon = _getIcon(scholarship['iconName']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScholarshipDetailsScreen(
                                    scholarshipId: scholarship['_id'] ?? scholarship['id'],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: sColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(sIcon, color: sColor, size: 28),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              scholarship['title'] ?? 'Unknown',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              scholarship['organization'] ?? 'Unknown',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Divider(),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.currency_rupee,
                                              size: 16, color: Colors.green.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            scholarship['amount'] ?? '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined,
                                              size: 16, color: Colors.redAccent),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ends: ${scholarship['deadline'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
