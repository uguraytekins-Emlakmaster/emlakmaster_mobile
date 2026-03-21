/// USD bazlı döviz API'leri için saf matematik (ağ yok; test edilebilir).
///
/// `base=USD` iken `rates['TRY']` = 1 USD kaç TRY, `rates['EUR']` = 1 USD kaç EUR.
/// **EUR/TRY** = TRY/USD ÷ EUR/USD.
double eurTryFromUsdBaseRates(double tryPerUsd, double eurPerUsd) {
  if (eurPerUsd.abs() <= 1e-9) return 0;
  return tryPerUsd / eurPerUsd;
}
