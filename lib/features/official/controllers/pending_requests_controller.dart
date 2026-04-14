import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/pagination_state.dart';
import '../repositories/official_repository.dart';

class PendingRequestsNotifier extends StateNotifier<PaginationState> {
  final OfficialRepository repository;
  StreamSubscription<List<RequestModel>>? _subscription;
  List<RequestModel> _allRequests = [];
  String _searchQuery = '';
  String? _selectedDocumentType;
  int _currentPage = 1;

  PendingRequestsNotifier(this.repository) : super(PaginationState.initial()) {
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _subscription?.cancel();
      _subscription = repository.getPendingRequests().listen((requests) {
        _allRequests = requests;
        _currentPage = 1;
        _updateVisibleDocuments();
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load requests: $e',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    try {
      _currentPage += 1;
      _updateVisibleDocuments();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more requests: $e',
      );
    }
  }

  void filterByDocumentType(String? documentType) {
    _selectedDocumentType =
        (documentType == null || documentType.isEmpty) ? null : documentType;
    _currentPage = 1;
    _updateVisibleDocuments();
  }

  void searchByName(String query) {
    _searchQuery = query.trim();
    _currentPage = 1;
    _updateVisibleDocuments();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDocumentType = null;
    _currentPage = 1;
    _updateVisibleDocuments();
  }

  void _updateVisibleDocuments() {
    final query = _searchQuery.toLowerCase();

    final filtered = _allRequests.where((req) {
      final matchesType = _selectedDocumentType == null ||
          req.documentType.toLowerCase() == _selectedDocumentType!.toLowerCase();

      final matchesSearch = query.isEmpty ||
          req.fullName.toLowerCase().contains(query) ||
          req.nic.toLowerCase().contains(query);

      return matchesType && matchesSearch;
    }).toList();

    final visibleCount = (_currentPage * OfficialRepository.pageSize)
        .clamp(0, filtered.length);
    final documents = filtered.take(visibleCount).toList();

    state = state.copyWith(
      documents: documents,
      hasMore: visibleCount < filtered.length,
      isLoading: false,
      error: null,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final pendingRequestsNotifierProvider =
    StateNotifierProvider<PendingRequestsNotifier, PaginationState>((ref) {
  final repository = ref.watch(officialRepositoryProvider);
  return PendingRequestsNotifier(repository);
});
