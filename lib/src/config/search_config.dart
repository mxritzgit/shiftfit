/// Configuration for the self-hosted OpenFoodFacts mirror search proxy
/// (Cloud Run, backed by Meilisearch on GCP). Override at build time with
/// `--dart-define=OFF_PROXY_URL=https://...`.
///
/// Kill-Switch: Der Mirror läuft auf einer GCP-Free-Trial, die am 2026-08-29
/// endet. Danach (oder bei jedem Mirror-Ausfall) den Mirror deaktivieren mit
/// `--dart-define=OFF_PROXY_URL=` (leer) -> die App nutzt direkt die live
/// OpenFoodFacts-API, ohne pro Suche erst in den Mirror-Timeout zu laufen.
class SearchConfig {
  const SearchConfig._();

  static const String proxyBaseUrl = String.fromEnvironment(
    'OFF_PROXY_URL',
    defaultValue:
        'https://off-search-proxy-647795772770.europe-west3.run.app',
  );

  /// True, solange eine Mirror-URL konfiguriert ist. Leer => Mirror aus,
  /// direkt OpenFoodFacts (siehe Kill-Switch oben).
  static bool get mirrorEnabled => proxyBaseUrl.trim().isNotEmpty;
}
