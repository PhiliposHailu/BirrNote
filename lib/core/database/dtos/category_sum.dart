// THE WHY: This is a pure DTO (Data Transfer Object). 
// It does not inherit from Drift or touch the database. 
// It is just a lightweight container to transport category total calculations to our UI.
class CategorySum {
  final String category;
  final double total;

  CategorySum(this.category, this.total);
}