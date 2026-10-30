import 'package:equatable/equatable.dart';

import 'titipan.dart';

class TitipanFeed extends Equatable {
  const TitipanFeed({this.titipans = const [], this.recipients = const []});

  final List<Titipan> titipans;
  final List<TitipanRecipient> recipients;

  @override
  List<Object?> get props => [titipans, recipients];
}
