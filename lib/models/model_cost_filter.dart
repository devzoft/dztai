enum ModelCostFilter {
  all,
  free,
  paid;

  bool includes(bool isFree) => switch (this) {
    ModelCostFilter.all => true,
    ModelCostFilter.free => isFree,
    ModelCostFilter.paid => !isFree,
  };

  static ModelCostFilter fromName(String? name) {
    return ModelCostFilter.values.firstWhere(
      (filter) => filter.name == name,
      orElse: () => ModelCostFilter.all,
    );
  }
}
