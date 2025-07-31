class FeatureCardModel {
  final String id;
  final String icon;
  final String title;
  final String description;
  final String buttonText;
  final Function() onPressed;
  final bool isEnabled;

  const FeatureCardModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    this.isEnabled = true,
  });
}
