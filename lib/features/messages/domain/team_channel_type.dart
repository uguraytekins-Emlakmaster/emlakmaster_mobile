enum TeamChannelType {
  general,
  direct,
}

TeamChannelType? parseTeamChannelType(String? raw) {
  switch (raw) {
    case 'general':
      return TeamChannelType.general;
    case 'direct':
      return TeamChannelType.direct;
    default:
      return null;
  }
}

String teamChannelTypeToFirestore(TeamChannelType type) => type.name;
