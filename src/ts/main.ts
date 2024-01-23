import axios from "axios"
import { JSDOM } from "jsdom"

async function getNewsPath(dom: JSDOM) {
  const list = dom.window.document.querySelectorAll(".news-list > .news-item")
  const paths: string[] = []
  for (const e of list) {
    const label = e.querySelector(".news-category-label")?.textContent
    if (label !== "アプリ情報") {
      continue
    }
    const title = e.querySelector(".news-title")?.textContent
    const href = e.querySelector("a")?.getAttribute("href")
    if (title?.includes("駅情報更新のお知らせ") && href) {
      paths.push(href)
    }
  }
  return paths
}

(async () => {
  const body = (await axios.get<string>("https://ekimemo.com/news?page=8")).data
  const dom = new JSDOM(body)
  const paths = await getNewsPath(dom)
  console.log(paths.length)
})()