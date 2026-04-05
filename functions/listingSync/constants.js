/**
 * Owned listing sync — resmi bağlantı / içe aktarma odaklı (scraping varsayımı yok).
 */
const COL_LISTING_SOURCES = "listing_sources";
const COL_LISTING_SYNC_RUNS = "listing_sync_runs";
const COL_LISTING_SYNC_ERRORS = "listing_sync_errors";
const COL_LISTINGS = "listings";
const COL_EXTERNAL_CONNECTIONS = "external_connections";

/** @typedef {'official_api'|'file_import'|'internal'} ConnectorType */

module.exports = {
  COL_LISTING_SOURCES,
  COL_LISTING_SYNC_RUNS,
  COL_LISTING_SYNC_ERRORS,
  COL_LISTINGS,
  COL_EXTERNAL_CONNECTIONS,
};
