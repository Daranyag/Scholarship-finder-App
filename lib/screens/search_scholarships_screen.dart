import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scholarship_details_screen.dart';
import 'package:intl/intl.dart';

class SearchScholarshipsScreen extends StatefulWidget {
  final bool isTamil;
  const SearchScholarshipsScreen({super.key, required this.isTamil});

  @override
  State<SearchScholarshipsScreen> createState() => _SearchScholarshipsScreenState();
}

class _SearchScholarshipsScreenState extends State<SearchScholarshipsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> _scholarships = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  
  // Filters
  String? _education;
  String? _course;
  String? _community;
  String? _income;
  String? _deadline;
  String? _status;
  bool _savedOnly = false;
  bool _forMe = false;
  String _sort = 'relevance';

  String _t(String en, String ta) => widget.isTamil ? ta : en;

  @override
  void initState() {
    super.initState();
    _fetchScholarships();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _page = 1;
      _fetchScholarships();
    });
  }

  Future<void> _fetchScholarships({bool loadMore = false}) async {
    if (loadMore) {
      if (_page >= _totalPages) return;
      setState(() => _isLoadingMore = true);
      _page++;
    } else {
      setState(() => _isLoading = true);
      _page = 1;
      _scholarships.clear();
    }

    final params = <String, dynamic>{
      'q': _searchController.text,
      'page': _page,
      'limit': 20,
      'sort': _sort,
      if (_education != null && _education != 'All') 'education': _education,
      if (_course != null && _course != 'All') 'course': _course,
      if (_community != null && _community != 'All') 'community': _community,
      if (_income != null) 'income': _income,
      if (_deadline != null && _deadline != 'All') 'deadline': _deadline,
      if (_status != null && _status != 'All') 'status': _status,
      if (_savedOnly) 'saved': 'true',
      if (_forMe) 'forMe': 'true',
    };

    final response = await ApiService.searchScholarships(params);
    
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          if (loadMore) {
            _scholarships.addAll(response['data']);
          } else {
            _scholarships = response['data'];
          }
          _totalPages = response['pagination']['pages'];
        } else {
          if (!loadMore) _scholarships = [];
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _openFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('Filters', 'வடிகட்டிகள்'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _education = null;
                              _course = null;
                              _community = null;
                              _income = null;
                              _deadline = null;
                              _status = null;
                              _savedOnly = false;
                              _forMe = false;
                              _sort = 'relevance';
                            });
                          },
                          child: Text(_t('Clear All', 'அனைத்தையும் அழிக்கவும்')),
                        )
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          SwitchListTile(
                            title: Text(_t('For Me (Profile Aware)', 'எனக்காக (சுயவிவர அடிப்படையில்)')),
                            subtitle: Text(_t('Uses your saved profile details', 'உங்கள் சேமிக்கப்பட்ட சுயவிவர விவரங்களை பயன்படுத்துகிறது')),
                            value: _forMe,
                            onChanged: (val) => setModalState(() => _forMe = val),
                          ),
                          SwitchListTile(
                            title: Text(_t('Saved Only', 'சேமிக்கப்பட்டவை மட்டும்')),
                            value: _savedOnly,
                            onChanged: (val) => setModalState(() => _savedOnly = val),
                          ),
                          _buildDropdown(_t('Education', 'கல்வி'), _education, ['All', 'School', '11th', '12th', 'UG Degree', 'PG Degree', 'Diploma', 'PhD'], (val) => setModalState(() => _education = val)),
                          _buildDropdown(_t('Community', 'சமூகம்'), _community, ['All', 'BC', 'MBC', 'SC', 'ST', 'DNC', 'OC', 'Minority'], (val) => setModalState(() => _community = val)),
                          _buildDropdown(_t('Deadline', 'கடைசி தேதி'), _deadline, ['All', 'Closing Soon', 'Expired'], (val) => setModalState(() => _deadline = val)),
                          _buildDropdown(_t('Sort By', 'வரிசைப்படுத்து'), _sort, ['relevance', 'newest', 'recently_updated', 'deadline'], (val) => setModalState(() => _sort = val)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _fetchScholarships();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_t('Apply Filters', 'வடிகட்டிகளை பயன்படுத்து')),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    int filterCount = [
      _education != null && _education != 'All',
      _course != null && _course != 'All',
      _community != null && _community != 'All',
      _income != null,
      _deadline != null && _deadline != 'All',
      _status != null && _status != 'All',
      _savedOnly,
      _forMe
    ].where((e) => e).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_t('Search Scholarships', 'உதவித்தொகைகளை தேடு')),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filterCount > 0,
              label: Text(filterCount.toString()),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilterDrawer,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade900,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _t('Search by name, provider...', 'பெயர், வழங்குநரால் தேடுங்கள்...'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ) : null,
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _scholarships.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(_t('No scholarships found.', 'உதவித்தொகைகள் எதுவும் கிடைக்கவில்லை.')),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _education = null;
                                  _community = null;
                                  _deadline = null;
                                  _forMe = false;
                                  _savedOnly = false;
                                  _searchController.clear();
                                });
                                _fetchScholarships();
                              },
                              child: Text(_t('CLEAR FILTERS', 'வடிகட்டிகளை அழிக்கவும்')),
                            )
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!_isLoadingMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            _fetchScholarships(loadMore: true);
                            return true;
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _scholarships.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _scholarships.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final sch = _scholarships[i];
                            final isExpired = sch['status'] == 'EXPIRED' || sch['deadline'] == 'Expired';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ScholarshipDetailsScreen(scholarshipId: sch['_id'], isTamil: widget.isTamil)),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.school, color: Colors.blue.shade800),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              sch['title'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                          if (isExpired)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                                              child: Text('EXPIRED', style: TextStyle(color: Colors.red.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(sch['organization'] ?? '', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(sch['amount'] ?? 'Not specified'),
                                          const Spacer(),
                                          const Icon(Icons.event, size: 16, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            isExpired ? _t('Expired', 'காலாவதியானது') : (sch['deadline'] ?? ''),
                                            style: TextStyle(color: isExpired ? Colors.red : Colors.black87),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${_t('Last updated:', 'கடைசியாக புதுப்பிக்கப்பட்டது:')} ${_formatDate(sch['lastUpdated'] ?? '')}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      )
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
