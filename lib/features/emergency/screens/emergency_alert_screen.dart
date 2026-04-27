import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../incidents/repositories/incident_repository.dart';

class EmergencyAlertScreen extends ConsumerStatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  ConsumerState<EmergencyAlertScreen> createState() =>
      _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends ConsumerState<EmergencyAlertScreen>
    with TickerProviderStateMixin {
  String? _selectedType;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _useCurrentLocation = true;
  bool _isSending = false;
  String? _lastIncidentId;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final List<_EmergencyType> _emergencyTypes = [
    _EmergencyType(
      'Fire',
      Icons.local_fire_department_rounded,
      const Color(0xFFE53935),
    ),
    _EmergencyType('Flood', Icons.water_rounded, const Color(0xFF1E88E5)),
    _EmergencyType(
      'Medical',
      Icons.medical_services_rounded,
      const Color(0xFF43A047),
    ),
    _EmergencyType('Crime', Icons.gavel_rounded, const Color(0xFF6D4C41)),
    _EmergencyType(
      'Accident',
      Icons.car_crash_rounded,
      const Color(0xFFF57C00),
    ),
    _EmergencyType(
      'Other',
      Icons.warning_amber_rounded,
      const Color(0xFF757575),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _sendAlert() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emergency type')),
      );
      return;
    }
    if (!_useCurrentLocation && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the incident location')),
      );
      return;
    }
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      context.go('/auth/login');
      return;
    }

    setState(() => _isSending = true);
    try {
      final profile = await ref
          .read(userServiceProvider)
          .getUserProfileOnce(user.uid);
      if (profile == null) {
        throw Exception('User profile not found.');
      }
      final location = _useCurrentLocation
          ? 'Current device location requested'
          : _locationController.text.trim();
      _lastIncidentId = await ref
          .read(incidentRepositoryProvider)
          .createIncident(
            reporter: profile,
            type: _selectedType!,
            description: _descriptionController.text.trim().isEmpty
                ? 'No additional description provided.'
                : _descriptionController.text.trim(),
            location: location,
          );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text('Alert Sent!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Your emergency alert has been sent to the Grama Niladhari and local authorities. Help is on the way.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reference: ${_lastIncidentId ?? 'EMR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'}',
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Alert'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Pulsing Button
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Report an emergency situation',
                style: AppTextStyles.caption,
              ),
            ),

            const SizedBox(height: 32),

            // Emergency Type Selection
            Text('Emergency Type *', style: AppTextStyles.label),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: _emergencyTypes.length,
              itemBuilder: (context, index) {
                final type = _emergencyTypes[index];
                final isSelected = _selectedType == type.name;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withOpacity(0.12)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? type.color : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: type.color.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type.icon, color: type.color, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          type.name,
                          style: AppTextStyles.captionMedium.copyWith(
                            color: isSelected
                                ? type.color
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Location
            Text('Location', style: AppTextStyles.label),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use current location',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              _useCurrentLocation
                                  ? '6.9271° N, 79.8612° E'
                                  : 'Enter location manually',
                              style: AppTextStyles.small,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useCurrentLocation,
                        onChanged: (v) =>
                            setState(() => _useCurrentLocation = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (!_useCurrentLocation) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter address or landmark',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Description
            Text('Description', style: AppTextStyles.label),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the emergency situation...',
                filled: true,
                fillColor: AppColors.surfaceGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your contact info and location will be shared with authorities for faster response.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Send Alert Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.error.withOpacity(0.4),
                  disabledBackgroundColor: AppColors.error.withOpacity(0.6),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.sos_rounded, size: 26),
                label: Text(
                  _isSending ? 'SENDING ALERT...' : 'SEND EMERGENCY ALERT',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmergencyType {
  final String name;
  final IconData icon;
  final Color color;
  const _EmergencyType(this.name, this.icon, this.color);
}
