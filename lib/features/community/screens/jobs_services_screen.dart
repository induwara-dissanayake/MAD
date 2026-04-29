import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_job_screen.dart';

class JobsServicesScreen extends StatefulWidget {
  const JobsServicesScreen({super.key});

  @override
  State<JobsServicesScreen> createState() => _JobsServicesScreenState();
}

class _JobsServicesScreenState extends State<JobsServicesScreen> {
  String _filter = 'All'; // All, Full-time, Part-time

  static const _green     = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _greenLight = Color(0xFFE8F5E9);

  static const _filters = ['All', 'Full-time', 'Part-time'];

  static const _typeColors = {
    'Full-time': Color(0xFF1565C0),
    'Part-time': Color(0xFF6A1B9A),
  };

  static const _typeBg = {
    'Full-time': Color(0xFFE3F2FD),
    'Part-time': Color(0xFFF3E5F5),
  };

  Future<void> _applyJob(String contact, String title) async {
    final phone = contact.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contact number available.')),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Job'),
        ]),
        content: const Text('Are you sure you want to delete this job post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              FirebaseFirestore.instance.collection('community_jobs').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _filter == label;
    Color chipColor = _green;
    if (label == 'Full-time') chipColor = const Color(0xFF1565C0);
    if (label == 'Part-time') chipColor = const Color(0xFF6A1B9A);

    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? chipColor : Colors.white,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: _green,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_greenDark, Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: -30, right: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
                  Positioned(bottom: -20, left: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
                  const Positioned(
                    left: 20, bottom: 60,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.work_rounded, color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Text('Jobs & Services', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ]),
                      SizedBox(height: 4),
                      Text('Find work opportunities in your area', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                height: 48,
                color: _greenDark,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _filters.map(_filterChip).toList(),
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_jobs')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _green));
            }

            final allDocs = snapshot.data?.docs ?? [];
            final docs = _filter == 'All'
                ? allDocs
                : allDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['jobType'] ?? 'Full-time') == _filter;
                  }).toList();

            // Stats
            final fullTime = allDocs.where((d) => ((d.data() as Map<String, dynamic>)['jobType'] ?? 'Full-time') == 'Full-time').length;
            final partTime = allDocs.where((d) => ((d.data() as Map<String, dynamic>)['jobType'] ?? '') == 'Part-time').length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Stat cards
                Row(children: [
                  _statCard('Total',     allDocs.length, _green,                Icons.work_rounded),
                  const SizedBox(width: 8),
                  _statCard('Full-time', fullTime,       const Color(0xFF1565C0), Icons.badge_rounded),
                  const SizedBox(width: 8),
                  _statCard('Part-time', partTime,       const Color(0xFF6A1B9A), Icons.access_time_rounded),
                ]),
                const SizedBox(height: 16),

                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
                        child: Icon(Icons.work_off_rounded, size: 48, color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 16),
                      Text(_filter == 'All' ? 'No jobs posted yet' : 'No "$_filter" jobs',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text('Tap + to post a job opportunity', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
                  )
                else
                  ...docs.map((doc) {
                    final job   = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final type  = job['jobType'] as String? ?? 'Full-time';
                    final typeColor = _typeColors[type] ?? _green;
                    final typeBg    = _typeBg[type] ?? _greenLight;
                    final timestamp = job['timestamp'] as Timestamp?;
                    final dateStr   = timestamp != null
                        ? DateFormat('MMM dd · hh:mm a').format(timestamp.toDate())
                        : job['date'] ?? 'Recent';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: _green.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            // Green accent bar
                            Container(
                              height: 5,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [_greenDark, Color(0xFF66BB6A)]),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + type badge
                                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(
                                      child: Text(job['title'] ?? 'No Title',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: typeBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: typeColor.withOpacity(0.4)),
                                      ),
                                      child: Text(type, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),

                                  // Company
                                  if ((job['company'] ?? '').isNotEmpty)
                                    Row(children: [
                                      const Icon(Icons.business_rounded, size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 5),
                                      Text(job['company'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                                    ]),
                                  const SizedBox(height: 10),

                                  // Info row
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      children: [
                                        Row(children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 5),
                                          Expanded(child: Text(job['location'] ?? 'Location not specified',
                                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                        ]),
                                        if ((job['salary'] ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 5),
                                            Expanded(child: Text(job['salary'] ?? '',
                                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                          ]),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 5),
                                          Text(dateStr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Apply + Delete buttons
                                  Row(children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _applyJob(job['contact'] ?? '', job['title'] ?? ''),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [_greenDark, Color(0xFF43A047)]),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                          ),
                                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Text(
                                              (job['contact'] ?? '').isNotEmpty ? 'Apply · ${job['contact']}' : 'Apply Now',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ]),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _confirmDelete(context, docId),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddJobScreen())),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Post Job', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}