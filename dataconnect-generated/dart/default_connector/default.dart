library default_connector;

class DefaultConnector {
  final String region;
  final String name;
  final String projectId;

  DefaultConnector({
    required this.region,
    required this.name,
    required this.projectId,
  });

  static DefaultConnector get instance {
    return DefaultConnector(
      region: 'us-central1',
      name: 'default',
      projectId: 'soilnutrition',
    );
  }
}
