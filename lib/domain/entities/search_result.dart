enum SearchResultType {
  customer,
  plan,
  installment,
  payment,
  receipt,
  product,
  sale,
}

class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String route;
}
