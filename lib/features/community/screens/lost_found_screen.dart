import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_lost_found_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String _filter = 'All'; // All, Lost, Found, Resolved

  static const _typeColors = {
    'Lost':     Color(0xFFEF4444),
    'Found':    Color(0xFF388E3C),
    'Resolved': Color(0xFF10B981),
  };

  void _markAsFound(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Mark as Found'),
        ]),
        content: const Text('Has this item been found? This will mark it as resolved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('community_lost_found')
                  .doc(docId)
                  .update({'status': 'Resolved'});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Item marked as found!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Yes, Mark Found'),
          ),
        ],
      ),
    );
  }

  void _contactOwner(String contact, String title) async {
    final phone = contact.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid contact number available.')),
      );
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
          Text('Delete Item'),
        ]),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              FirebaseFirestore.instance.collection('community_lost_found').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, Color color) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? color : Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 155,
            floating: false,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: -30, right: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
                  Positioned(bottom: -20, left: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
                  Positioned(
                    left: 20, bottom: 64,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Row(children: [
                        Icon(Icons.search_rounded, color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Text('Lost & Found', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ]),
                      SizedBox(height: 4),
                      Text('Help reunite people with their belongings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                height: 48,
                color: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('All',      const Color(0xFF2E7D32)),
                    _filterChip('Lost',     const Color(0xFFEF4444)),
                    _filterChip('Found',    const Color(0xFF388E3C)),
                    _filterChip('Resolved', const Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_lost_found')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
            }

            final allDocs = snapshot.data?.docs ?? [];
            final docs = _filter == 'All'
                ? allDocs
                : allDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    if (_filter == 'Resolved') return (data['status'] ?? '') == 'Resolved';
                    return data['type'] == _filter && (data['status'] ?? '') != 'Resolved';
                  }).toList();

            // Stats
            final lostCount     = allDocs.where((d) { final data = d.data() as Map<String, dynamic>; return data['type'] == 'Lost' && (data['status'] ?? '') != 'Resolved'; }).length;
            final foundCount    = allDocs.where((d) { final data = d.data() as Map<String, dynamic>; return data['type'] == 'Found' && (data['status'] ?? '') != 'Resolved'; }).length;
            final resolvedCount = allDocs.where((d) => ((d.data() as Map<String, dynamic>)['status'] ?? '') == 'Resolved').length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Stat cards
                Row(children: [
                  _statCard('Lost',     lostCount,     const Color(0xFFEF4444), Icons.help_outline_rounded),
                  const SizedBox(width: 8),
                  _statCard('Found',    foundCount,    const Color(0xFF388E3C), Icons.inventory_2_outlined),
                  const SizedBox(width: 8),
                  _statCard('Resolved', resolvedCount, const Color(0xFF10B981), Icons.verified_rounded),
                ]),
                const SizedBox(height: 16),

                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
                        child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 16),
                      Text(_filter == 'All' ? 'No items posted yet' : 'No "$_filter" items',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text('Tap + to post a lost or found item', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
                  )
                else
                  ...docs.map((doc) {
                    final item     = doc.data() as Map<String, dynamic>;
                    final docId    = doc.id;
                    final type     = item['type'] as String? ?? 'Lost';
                    final status   = item['status'] as String? ?? '';
                    final isResolved = status == 'Resolved';
                    final typeColor  = isResolved ? const Color(0xFF10B981) : (_typeColors[type] ?? Colors.grey);

                    final timestamp = item['timestamp'] as Timestamp?;
                    final dateStr   = timestamp != null ? DateFormat('MMM dd · hh:mm a').format(timestamp.toDate()) : 'Recent';
                    final imageUrl  = item['imageUrl'] as String?;
                    final contact   = item['contact'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: typeColor.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Accent bar
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [typeColor.withOpacity(0.6), typeColor]),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                              ),
                            ),

                            // Image (if exists)
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: Image.network(
                                  imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) => progress == null
                                      ? child
                                      : Container(
                                          height: 180,
                                          color: Colors.grey[100],
                                          child: const Center(child: CircularProgressIndicator()),
                                        ),
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    color: Colors.grey[100],
                                    child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + type badge
                                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] ?? 'No Title',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: typeColor.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        isResolved ? '✅ Resolved' : type,
                                        style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),

                                  // Description
                                  Text(item['description'] ?? 'No description provided.',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
                                      maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 12),

                                  // Location & time
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                                    child: Row(children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(item['location'] ?? 'Unknown', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(dateStr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    ]),
                                  ),
                                  const SizedBox(height: 12),

                                  // Action buttons
                                  if (!isResolved) Row(
                                    children: [
                                      // Contact Owner
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _contactOwner(contact, item['title'] ?? ''),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(colors: [typeColor.withOpacity(0.8), typeColor]),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                                              const SizedBox(width: 6),
                                              Text(contact.isNotEmpty ? contact : 'Contact Owner',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                            ]),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Mark as Found
                                      GestureDetector(
                                        onTap: () => _markAsFound(docId),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                          ),
                                          child: const Row(children: [
                                            Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                                            SizedBox(width: 4),
                                            Text('Found', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                          ]),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Delete
                                      GestureDetector(
                                        onTap: () => _confirmDelete(context, docId),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (isResolved)
                                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      GestureDetector(
                                        onTap: () => _confirmDelete(context, docId),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                          child: const Row(children: [
                                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                            SizedBox(width: 4),
                                            Text('Remove', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                                          ]),
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
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Post Item', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLostFoundScreen())),
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