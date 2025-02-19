import 'package:equatable/equatable.dart';

class SplitInfo extends Equatable {
  final String personName;
  final double share;

  const SplitInfo({
    required this.personName,
    required this.share,
  });

  Map<String, dynamic> toJson() => {
        'personName': personName,
        'share': share,
      };

  factory SplitInfo.fromJson(Map<String, dynamic> json) {
    return SplitInfo(
      personName: json['personName'] as String,
      share: (json['share'] as num).toDouble(),
    );
  }

  @override
  List<Object> get props => [personName, share];
}
