export const EKIMEMO_USER_AGENT =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 station_database/1.0"

/**
 * 駅メモ公式のWebサーバーをスクレイピングするための設定
 * 
 * @see https://github.com/Seo-4d696b75/station_database/issues/211
 */
export const ekimemoGetConfig = { headers: { "User-Agent": EKIMEMO_USER_AGENT } }
