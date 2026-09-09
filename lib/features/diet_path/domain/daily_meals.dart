class DailyMeals {
  final bool breakfast;
  final bool lunch;
  final bool afternoonSnack;
  final bool dinner;

  const DailyMeals({
    this.breakfast = false,
    this.lunch = false,
    this.afternoonSnack = false,
    this.dinner = false,
  });

  bool get isAllCompleted => breakfast && lunch && afternoonSnack && dinner;

  DailyMeals copyWith({
    bool? breakfast,
    bool? lunch,
    bool? afternoonSnack,
    bool? dinner,
  }) {
    return DailyMeals(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      afternoonSnack: afternoonSnack ?? this.afternoonSnack,
      dinner: dinner ?? this.dinner,
    );
  }
}
