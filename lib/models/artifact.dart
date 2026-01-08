import 'hero_model.dart';

abstract class Artifact {
  String get id;
  String get name;
  String get description;

  // Hooks - Default to doing nothing
  double modifyGoldGain(double current) => current;
  int modifyQuestDuration(int seconds) => seconds;
  bool preventDeath(HeroModel hero) => false;
}

class GreedCoin extends Artifact {
  @override
  String get id => 'greed_coin';
  @override
  String get name => 'Greed Coin';
  @override
  String get description => 'Doubles Gold Gain.';

  @override
  double modifyGoldGain(double current) => current * 2.0;
}

class ChronoDial extends Artifact {
  @override
  String get id => 'chrono_dial';
  @override
  String get name => 'Chrono Dial';
  @override
  String get description => 'Halves Quest Duration.';

  @override
  int modifyQuestDuration(int seconds) => (seconds / 2).round();
}

class PhoenixFeather extends Artifact {
  @override
  String get id => 'phoenix_feather';
  @override
  String get name => 'Phoenix Feather';
  @override
  String get description => 'Prevents Death once (Consumable).';

  @override
  bool preventDeath(HeroModel hero) => true;
}
