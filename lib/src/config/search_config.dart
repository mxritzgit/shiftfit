/// Configuration for the self-hosted OpenFoodFacts mirror search proxy
/// (Cloud Run, backed by Meilisearch on GCP). Override at build time with
/// `--dart-define=OFF_PROXY_URL=https://...`.
class SearchConfig {
  const SearchConfig._();

  static const String proxyBaseUrl = String.fromEnvironment(
    'OFF_PROXY_URL',
    defaultValue:
        'https://off-search-proxy-647795772770.europe-west3.run.app',
  );
}
