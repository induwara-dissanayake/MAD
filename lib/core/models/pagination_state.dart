import '../models/request_model.dart';

class PaginationState {
  final List<RequestModel> documents;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  PaginationState({
    required this.documents,
    required this.hasMore,
    required this.isLoading,
    this.error,
  });

  factory PaginationState.initial() {
    return PaginationState(
      documents: [],
      hasMore: true,
      isLoading: false,
    );
  }

  PaginationState copyWith({
    List<RequestModel>? documents,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PaginationState(
      documents: documents ?? this.documents,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
