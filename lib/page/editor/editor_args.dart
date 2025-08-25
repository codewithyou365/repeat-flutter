import 'dart:ui';

class EditorArgs {
  VoidCallback? onAdvancedEdit;
  VoidCallback? onHistory;
  String title;
  Future<void> Function(String) save;
  String value;

  EditorArgs({
    this.onAdvancedEdit,
    this.onHistory,
    required this.title,
    required this.save,
    required this.value,
  });
}
