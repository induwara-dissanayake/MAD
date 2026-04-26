import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_complaint_screen.dart';
import 'update_complaint_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _filterStatus = 'All';

  static const _statusConfig = {
    'Pending':     {'color': Color(0xFFF59E0B), 'bg': Color(0xFFFFFBEB), 'icon': Icons.hourglass_empty_rounded},
    'In Progress': {'color': Color(0xFF3B82F6), 'bg': Color(0xFFEFF6FF), 'icon': Icons.autorenew_rounded},
    'Resolved':    {'color': Color(0xFF10B981), 'bg': Color(0xFFECFDF5), 'icon': Icons.verified_rounded},
  };

  static const _filters = ['All', 'Pending', 'In Progress', 'Resolved'];

  static const _filterColors = {
    'All':         Color(0xFF6366F1),
    'Pending':     Color(0xFFF59E0B),
    'In Progress': Color(0xFF3B82F6),
    'Resolved':    Color(0xFF10B981),
  };

  void _vote(String docId, int currentVotes) {
    FirebaseFirestore.instance
        .collection('community_complaints')
        .doc(docId)
        .update({'votes': currentVotes + 1});
  }

  void _updateStatus(BuildContext context, String docId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            const Align(alignment: Alignment.centerLeft, child: Text('Tap a status to update this complaint', style: TextStyle(fontSize: 13, color: Colors.grey))),
            const SizedBox(height: 20),
            ..._statusConfig.entries.map((entry) {
              final isSelected = currentStatus == entry.key;
              final color = entry.value['color'] as Color;
              final bg    = entry.value['bg']    as Color;
              final icon  = entry.value['icon']  as IconData;
              return GestureDetector(
                onTap: () {
                  FirebaseFirestore.instance.collection('community_complaints').doc(docId).update({'status': entry.key});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 8), Text('Status → "${entry.key}"')]),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(entry.key, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 15, color: isSelected ? color : Colors.black87))),
                    if (isSelected) Icon(Icons.check_circle, color: color),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Delete Complaint')]),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              FirebaseFirestore.instance.collection('community_complaints').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final cfg   = _statusConfig[status] ?? _statusConfig['Pending']!;
    final color = cfg['color'] as Color;
    final icon  = cfg['icon']  as IconData;
    final bg    = cfg['bg']    as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Premium SliverAppBar ──
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
                child: Stack(
                  children: [
                    Positioned(top: -30, right: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
                    Positioned(bottom: -20, left: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
                    Positioned(
                      left: 20, bottom: 64,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [
                          Icon(Icons.campaign_rounded, color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text('Complaints', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 4),
                        const Text('Report & track community issues', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            // Filter chips as AppBar bottom
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                height: 48,
                color: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _filters.map((f) {
                    final isSelected = _filterStatus == f;
                    final color = _filterColors[f] ?? Colors.grey;
                    return GestureDetector(
                      onTap: () => setState(() => _filterStatus = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5)],
                            Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? color : Colors.white)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('community_complaints').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));

            final allDocs = snapshot.data?.docs ?? [];
            final docs = _filterStatus == 'All'
                ? allDocs
                : allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == _filterStatus).toList();

            // ── Stats Row ──
            final pending    = allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Pending').length;
            final inProgress = allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'In Progress').length;
            final resolved   = allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Resolved').length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Stat cards
                Row(children: [
                  _statCard('Pending',     pending,    const Color(0xFFF59E0B), Icons.hourglass_empty_rounded),
                  const SizedBox(width: 8),
                  _statCard('In Progress', inProgress, const Color(0xFF3B82F6), Icons.autorenew_rounded),
                  const SizedBox(width: 8),
                  _statCard('Resolved',    resolved,   const Color(0xFF10B981), Icons.verified_rounded),
                ]),
                const SizedBox(height: 16),

                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
                        child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 16),
                      Text(_filterStatus == 'All' ? 'No complaints yet' : 'No "$_filterStatus" complaints',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text('Tap + to report a new issue', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
                  )
                else
                  ...docs.map((doc) {
                    final item   = doc.data() as Map<String, dynamic>;
                    final docId  = doc.id;
                    final status = item['status'] ?? 'Pending';
                    final statusColor = (_statusConfig[status]?['color'] as Color?) ?? Colors.grey;
                    final timestamp   = item['timestamp'] as Timestamp?;
                    final dateStr     = timestamp != null ? DateFormat('MMM dd · hh:mm a').format(timestamp.toDate()) : 'Recent';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            // Colored accent bar
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [statusColor.withOpacity(0.6), statusColor]),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + status
                                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(child: Text(item['title'] ?? 'No Title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                                    const SizedBox(width: 8),
                                    GestureDetector(onTap: () => _updateStatus(context, docId, status), child: _buildStatusBadge(status)),
                                  ]),
                                  const SizedBox(height: 8),

                                  // Description
                                  Text(item['description'] ?? 'No description provided.',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
                                      maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 12),

                                  // Location & time pill
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

                                  // Actions
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    // Vote
                                    GestureDetector(
                                      onTap: () => _vote(docId, item['votes'] ?? 0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                                        child: Row(children: [
                                          const Icon(Icons.thumb_up_alt_rounded, size: 15, color: Color(0xFF2E7D32)),
                                          const SizedBox(width: 5),
                                          Text('${item['votes'] ?? 0} Votes', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                                        ]),
                                      ),
                                    ),
                                    // Buttons
                                    Row(children: [
                                      _actionBtn(Icons.swap_horiz_rounded, const Color(0xFF6366F1), () => _updateStatus(context, docId, status)),
                                      const SizedBox(width: 6),
                                      _actionBtn(Icons.edit_outlined, const Color(0xFF2E7D32), () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateComplaintScreen(
                                          docId: docId,
                                          initialTitle: item['title'] ?? '',
                                          initialDescription: item['description'] ?? '',
                                          initialLocation: item['location'] ?? '',
                                        )));
                                      }),
                                      const SizedBox(width: 6),
                                      _actionBtn(Icons.delete_outline_rounded, Colors.red, () => _confirmDelete(context, docId)),
                                    ]),
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
        label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddComplaintScreen())),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}