import puppeteer, { Page } from "puppeteer"

async function getNewsPath(page: Page) {
  await page.goto("https://ekimemo.com/news?page=8")
  const size = await page.evaluate(() => document.querySelectorAll(".news-list > .news-item").length)

  const paths: string[] = []
  for (let idx = 0; idx < size; idx++) {
    const label = await page.evaluate((i) => document.querySelectorAll(".news-list > .news-item")[i].querySelector(".news-category-label")?.textContent, idx)
    if (label !== "アプリ情報") {
      continue
    }
    const title = await page.evaluate((i) => document.querySelectorAll(".news-list > .news-item")[i].querySelector(".news-title")?.textContent, idx)
    const href = await page.evaluate((i) => document.querySelectorAll(".news-list > .news-item")[i].querySelector("a")?.getAttribute("href"), idx)
    if (title?.includes("駅情報更新のお知らせ") && href) {
      paths.push(href)
    }
  }
  return paths
}

(async () => {
  const browser = await puppeteer.launch({
    headless: "new"
  })
  const page = await browser.newPage()
  const paths = await getNewsPath(page)
  browser.close()
  console.log(paths.length)
})()