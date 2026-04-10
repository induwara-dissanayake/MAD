import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/pagination_state.dart';
import '../repositories/official_repository.dart';

class PendingRequestsNotifier extends StateNotifier<PaginationState> {
  final OfficialRepository repository;

  PendingRequestsNotifier(this.repository) : super(PaginationState.initial()) {
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      repository.getPendingRequests().listen((requests) {
        final hasMore = requests.length > OfficialRepository.pageSize;
        final documents = hasMore
            ? requests.sublist(0, OfficialRepository.pageSize)
            : requests;

        state = state.copyWith(
          documents: documents,
          hasMore: hasMore,
          isLoading: false,
        );
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
      state = state.copyWith(isLoading: true, error: null);

      final lastDoc = await repository.getLastDocumentSnapshot(state.documents);
      if (lastDoc == null) {
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      repository.getPendingRequests(lastDocument: lastDoc).listen((requests) {
        if (requests.isEmpty) {
          state = state.copyWith(isLoading: false, hasMore: false);
          return;
        }

        final hasMore = requests.length > OfficialRepository.pageSize;
        final newDocuments = hasMore
            ? requests.sublist(0, OfficialRepository.pageSize)
            : requests;

        state = state.copyWith(
          documents: [...state.documents, ...newDocuments],
          hasMore: hasMore,
          isLoading: false,
        );
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more requests: $e',
      );
    }
  }

  void filterByDocumentType(String? documentType) {
    if (documentType == null || documentType.isEmpty) {
      _loadInitialPage();
      return;
    }

    final filtered = state.documents
        .where(
          (req) =>
              req.documentType.toLowerCase() ==
              documentType.toLowerCase(),
        )
        .toList();

    state = state.copyWith(documents: filtered);
  }

  void searchByName(String query) {
    if (query.isEmpty) {
      _loadInitialPage();
      return;
    }

    final filtered = state.documents
        .where(
          (req) =>
              req.fullName.toLowerCase().contains(query.toLowerCase()) ||
              req.nic.contains(query),
        )
        .toList();

    state = state.copyWith(documents: filtered);
  }

  void clearFilters() {
    _loadInitialPage();
  }
}

final pendingRequestsNotifierProvider =
    StateNotifierProvider<PendingRequestsNotifier, PaginationState>((ref) {
  final repository = ref.watch(officialRepositoryProvider);
  return PendingRequestsNotifier(repository);
});
