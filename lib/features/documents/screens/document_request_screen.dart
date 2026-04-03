import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/request_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/vc_components.dart';
import '../repositories/document_repository.dart';

class DocumentRequestScreen extends ConsumerStatefulWidget {
  const DocumentRequestScreen({super.key, this.initialDocumentType});

  final String? initialDocumentType;

  @override
  ConsumerState<DocumentRequestScreen> createState() =>
      _DocumentRequestScreenState();
}

class _DocumentRequestScreenState extends ConsumerState<DocumentRequestScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isSubmitting = false;
  String? _selectedDocumentTitle;

  // Step 1
  int _selectedDocumentIndex = -1;

  // Step 2
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _dynamicControllers = {};

  // Step 3
  final List<Map<String, String>> _uploadedFiles = [];

  // Step 4
  bool _confirmChecked = false;

  final List<Map<String, dynamic>> _documentTypes = [
    {
      'title': 'Character Certificate',
      'icon': Icons.verified_user_rounded,
      'desc': 'For employment, visa applications',
    },
    {
      'title': 'Residence Certificate',
      'icon': Icons.home_rounded,
      'desc': 'Proof of residence in GN division',
    },
    {
      'title': 'Income Certificate',
      'icon': Icons.account_balance_wallet_rounded,
      'desc': 'For subsidies, financial aid',
    },
    {
      'title': 'Birth Certificate',
      'icon': Icons.child_care_rounded,
      'desc': 'Birth registration & copies',
    },
    {
      'title': 'Identity Verification',
      'icon': Icons.badge_rounded,
      'desc': 'NIC-based identity confirmation',
    },
    {
      'title': 'Land Ownership',
      'icon': Icons.landscape_rounded,
      'desc': 'Land title & ownership letters',
    },
  ];

  final List<String> _stepLabels = ['Document', 'Details', 'Upload', 'Confirm'];

  final Map<String, List<String>> _applicationFieldsByType = {
    'Residence Certificate': [
      'Full Name',
      'NIC Number',
      'Permanent Address',
      'Duration of residence',
      'Purpose of certificate',
      'Contact number',
    ],
    'Character Certificate': [
      'Full Name',
      'NIC Number',
      'Address',
      'Occupation / Student status',
      'Purpose (job, school, etc.)',
      'Referee details (if required)',
    ],
    'NIC Application Confirmation': [
      'Full Name',
      'Date of Birth',
      'Birth Certificate Number',
      'Address',
      'Parent/Guardian details',
      'Declaration of correctness',
    ],
    'Family Composition Certificate': [
      'Head of household name',
      'Address',
      'List of family members (name, age, relationship)',
      'NIC numbers (if available)',
    ],
    'Land Ownership Confirmation': [
      'Owner’s name',
      'NIC Number',
      'Address',
      'Land location (address)',
      'Land size',
      'Deed/permit details',
    ],
    'Boundary Verification': [
      'Owner’s name',
      'Land location',
      'Survey plan details',
      'Neighbor details',
      'Issue description',
    ],
    'Land Permit Recommendation': [
      'Applicant name',
      'NIC Number',
      'Address',
      'Requested land details',
      'Purpose of land use',
    ],
    'Samurdhi / Aswesuma Application': [
      'Full Name',
      'NIC Number',
      'Address',
      'Family details',
      'Monthly income',
      'Employment status',
      'Assets owned',
    ],
    'Low-Income Certificate': [
      'Applicant name',
      'NIC Number',
      'Address',
      'Occupation',
      'Monthly income',
      'Family dependents',
    ],
    'Disability / Elderly Allowance': [
      'Name',
      'NIC Number',
      'Age',
      'Medical condition (if applicable)',
      'Income details',
      'Family support details',
    ],
    'Scholarship Application Support': [
      'Student name',
      'Date of Birth',
      'School name',
      'Address',
      'Parent income details',
      'Family details',
    ],
    'University / Hostel Income Verification': [
      'Student name',
      'Parent/Guardian name',
      'Address',
      'Occupation',
      'Monthly income',
      'Number of dependents',
    ],
    'Passport Verification': [
      'Full Name',
      'NIC Number',
      'Address',
      'Duration of residence',
      'Occupation',
    ],
    'Birth/Marriage/Death Confirmation': [
      'Relevant person’s name',
      'Date of event',
      'Address',
      'Relationship to applicant',
    ],
    'Police Clearance Support': [
      'Name',
      'NIC Number',
      'Address',
      'Duration of residence',
      'Purpose',
    ],
    'Job Character Certificate': [
      'Name',
      'NIC Number',
      'Address',
      'Occupation',
      'Purpose (job type)',
    ],
    'Foreign Employment Documents': [
      'Name',
      'NIC Number',
      'Address',
      'Passport details',
      'Job details abroad',
    ],
    'Electricity / Water Connection': [
      'Applicant name',
      'NIC Number',
      'Address',
      'Proof of residence',
      'Land ownership/permission details',
    ],
    'Business Registration Support': [
      'Applicant name',
      'NIC Number',
      'Address',
      'Business type',
      'Business location',
    ],
    'Disaster Damage Report': [
      'Applicant name',
      'Address',
      'Type of disaster',
      'Date of incident',
      'Damage description',
    ],
    // fallback for legacy shortcuts
    'Income Certificate': [
      'Applicant name',
      'NIC Number',
      'Address',
      'Occupation',
      'Monthly income',
      'Family dependents',
    ],
    'Birth Certificate': [
      'Relevant person’s name',
      'Date of event',
      'Address',
      'Relationship to applicant',
    ],
    'Identity Verification': [
      'Full Name',
      'NIC Number',
      'Address',
      'Purpose of certificate',
    ],
    'Land Ownership': [
      'Owner’s name',
      'NIC Number',
      'Address',
      'Land location (address)',
      'Land size',
      'Deed/permit details',
    ],
  };

  String get _activeDocumentType {
    if (_selectedDocumentTitle != null && _selectedDocumentTitle!.isNotEmpty) {
      return _selectedDocumentTitle!;
    }
    if (_selectedDocumentIndex >= 0) {
      return _documentTypes[_selectedDocumentIndex]['title'] as String;
    }
    return '';
  }

  List<String> get _activeFieldLabels {
    final type = _activeDocumentType;
    return _applicationFieldsByType[type] ??
        const ['Full Name', 'NIC Number', 'Address', 'Reason for Request'];
  }

  TextEditingController _controllerForField(String label) {
    return _dynamicControllers.putIfAbsent(label, TextEditingController.new);
  }

  bool _areActiveFieldsFilled() {
    if (_activeFieldLabels.isEmpty) return false;
    return _activeFieldLabels.every(
      (field) => _controllerForField(field).text.trim().isNotEmpty,
    );
  }

  Map<String, String> _collectFormData() {
    return {
      for (final field in _activeFieldLabels)
        field: _controllerForField(field).text.trim(),
    };
  }

  String _firstValueContaining(
    Map<String, String> data,
    List<String> keywords,
  ) {
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (keywords.any((k) => key.contains(k.toLowerCase()))) {
        return entry.value;
      }
    }
    return '';
  }

  IconData _iconForField(String label) {
    final key = label.toLowerCase();
    if (key.contains('name')) return Icons.person_rounded;
    if (key.contains('nic')) return Icons.badge_rounded;
    if (key.contains('address') || key.contains('location')) {
      return Icons.location_on_rounded;
    }
    if (key.contains('date') || key.contains('duration')) {
      return Icons.calendar_month_rounded;
    }
    if (key.contains('phone') || key.contains('contact')) {
      return Icons.phone_rounded;
    }
    if (key.contains('income')) return Icons.attach_money_rounded;
    if (key.contains('occupation') || key.contains('employment')) {
      return Icons.work_rounded;
    }
    if (key.contains('passport')) return Icons.flight_rounded;
    if (key.contains('purpose')) return Icons.flag_rounded;
    return Icons.note_alt_rounded;
  }

  String _hintForField(String label) {
    final key = label.toLowerCase();
    if (key.contains('nic')) return 'Enter NIC number';
    if (key.contains('date')) return 'Enter date';
    if (key.contains('address') || key.contains('location')) {
      return 'Enter address details';
    }
    if (key.contains('income')) return 'Enter monthly income';
    if (key.contains('purpose')) return 'Enter purpose';
    return 'Enter $label';
  }

  TextInputType _keyboardTypeForField(String label) {
    final key = label.toLowerCase();
    if (key.contains('phone') || key.contains('contact')) {
      return TextInputType.phone;
    }
    if (key.contains('income') || key.contains('age') || key.contains('size')) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  bool _isMultilineField(String label) {
    final key = label.toLowerCase();
    return key.contains('address') ||
        key.contains('details') ||
        key.contains('description') ||
        key.contains('list of family members') ||
        key.contains('declaration') ||
        key.contains('issue');
  }

  @override
  void initState() {
    super.initState();
    final preselectedType = widget.initialDocumentType?.trim();
    if (preselectedType == null || preselectedType.trim().isEmpty) return;

    _selectedDocumentTitle = preselectedType;
    _currentStep = 1;

    final index = _documentTypes.indexWhere(
      (doc) =>
          ((doc['title'] as String?) ?? '').toLowerCase() ==
          preselectedType.toLowerCase(),
    );

    if (index >= 0) {
      _selectedDocumentIndex = index;
    }
  }

  @override
  void dispose() {
    for (final controller in _dynamicControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedDocumentIndex >= 0;
      case 1:
        return _areActiveFieldsFilled();
      case 2:
        return _uploadedFiles.isNotEmpty;
      case 3:
        return _confirmChecked;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedDocumentIndex >= 0) {
      _selectedDocumentTitle =
          _documentTypes[_selectedDocumentIndex]['title'] as String;
    }
    if (_currentStep == 1 && !_formKey.currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep == 1 && _selectedDocumentTitle != null) {
      context.go('/applications');
      return;
    }
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        for (final file in result.files) {
          final fileName = file.name;
          final alreadyExists = _uploadedFiles.any(
            (f) => f['name'] == fileName,
          );
          if (alreadyExists) continue;

          _uploadedFiles.add({
            'name': fileName,
            'size': _formatFileSize(file.size),
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick files: $e')));
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return unitIndex == 0
        ? '${size.toInt()} ${units[unitIndex]}'
        : '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a request.'),
        ),
      );
      return;
    }

    final docType =
        _selectedDocumentTitle ??
        (_selectedDocumentIndex >= 0
            ? _documentTypes[_selectedDocumentIndex]['title'] as String
            : '');

    if (docType.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an application type.')),
      );
      return;
    }

    final formData = _collectFormData();
    final request = RequestModel(
      id: '', // Generated by Firestore
      userId: user.uid,
      documentType: docType,
      fullName: _firstValueContaining(formData, ['full name', 'name']),
      nic: _firstValueContaining(formData, ['nic']),
      address: _firstValueContaining(formData, ['address', 'location']),
      reason: _firstValueContaining(formData, [
        'purpose',
        'reason',
        'issue',
        'description',
      ]),
      status: 'Pending',
      submittedAt: DateTime.now(),
      formData: formData,
      requiredFields: _activeFieldLabels,
    );

    try {
      await ref.read(documentRepositoryProvider).createRequest(request);
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/applications');
              }
            },
          ),
        ),
        title: Text(
          'Apply for Document',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border.withOpacity(0.3), height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: VcStepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: _stepLabels,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildDocumentTypeStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildUploadStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Document Type ─────────────────────────────────────────────
  Widget _buildDocumentTypeStep() {
    return SingleChildScrollView(
      key: const ValueKey('doc_step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Document Type',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the type of document you need to request from the GN office.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: _documentTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final isSelected = _selectedDocumentIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedDocumentIndex = index),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.04)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.15,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: AppColors.shadowLight.withOpacity(
                                        0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border.withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.12)
                                      : AppColors.surfaceGrey.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  doc['icon'] as IconData,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc['title'] as String,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doc['desc'] as String,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Details ───────────────────────────────────────────────────
  Widget _buildDetailsStep() {
    final fieldLabels = _activeFieldLabels;
    final selectedDocTitle = _activeDocumentType;

    return SingleChildScrollView(
      key: const ValueKey('doc_step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedDocTitle.isEmpty
                  ? 'Application Details'
                  : selectedDocTitle,
              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the required fields for this application.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ...fieldLabels.map((label) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildFormField(
                  label: label,
                  controller: _controllerForField(label),
                  hint: _hintForField(label),
                  icon: _iconForField(label),
                  keyboardType: _keyboardTypeForField(label),
                  maxLines: _isMultilineField(label) ? 3 : 1,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Upload ────────────────────────────────────────────────────
  Widget _buildUploadStep() {
    return SingleChildScrollView(
      key: const ValueKey('doc_step3'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Documents',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload clear photos or scans of your National Identity Card (NIC).',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Upload area
          GestureDetector(
            onTap: _pickFiles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tap to browse files',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JPG, PNG or PDF formats (max 5MB per file)',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          if (_uploadedFiles.isNotEmpty) ...[
            Text(
              'Uploaded Files',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ..._uploadedFiles.map(
              (file) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insert_drive_file_rounded,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['name']!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            file['size']!,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _uploadedFiles.remove(file)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 4: Confirm ───────────────────────────────────────────────────
  Widget _buildConfirmStep() {
    final formData = _collectFormData();
    final selectedDoc =
        _selectedDocumentTitle ??
        (_selectedDocumentIndex >= 0
            ? _documentTypes[_selectedDocumentIndex]['title'] as String
            : '');
    final docIcon = _selectedDocumentIndex >= 0
        ? _documentTypes[_selectedDocumentIndex]['icon'] as IconData
        : Icons.description;

    return SingleChildScrollView(
      key: const ValueKey('doc_step4'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your application carefully before submitting.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(docIcon, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Type',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedDoc,
                              style: AppTextStyles.h3.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ...formData.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            _buildDetailRow(item.key, item.value),
                            if (index != formData.length - 1)
                              const Divider(
                                height: 32,
                                color: AppColors.divider,
                              ),
                          ],
                        );
                      }),
                      if (formData.isNotEmpty)
                        const Divider(height: 32, color: AppColors.divider),
                      _buildDetailRow(
                        'Files Uploaded',
                        '${_uploadedFiles.length} file(s) attached',
                        valueColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          InkWell(
            onTap: () => setState(() => _confirmChecked = !_confirmChecked),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _confirmChecked
                    ? AppColors.primary.withOpacity(0.05)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _confirmChecked
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _confirmChecked,
                    onChanged: (v) =>
                        setState(() => _confirmChecked = v ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'I confirm that all the information provided is accurate and complete. I understand that providing false information may lead to rejection of my application.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Form field builder ────────────────────────────────────────────────
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            prefixIcon: Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 16 : 0),
              child: Icon(icon, color: AppColors.textMuted, size: 24),
            ),
            filled: true,
            fillColor: AppColors.surfaceGrey.withOpacity(0.5),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 16 : 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _previousStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: AppColors.border.withOpacity(0.8),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_canProceed
                      ? null
                      : (isLastStep ? _submitApplication : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastStep
                        ? AppColors.success
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceGrey,
                    disabledForegroundColor: AppColors.textMuted,
                    elevation: _canProceed && !_isSubmitting ? 4 : 0,
                    shadowColor:
                        (isLastStep ? AppColors.success : AppColors.primary)
                            .withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLastStep ? 'Submit Application' : 'Continue',
                          style: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success Dialog ────────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Application Submitted!',
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your application has been submitted securely to the GN office.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop(); // close dialog
                      context.go('/applications');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: AppTextStyles.button.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
