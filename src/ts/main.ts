import axios from "axios"
import { JSDOM } from "jsdom"
import { Octokit } from "octokit"

async function getNewsPath() {
  const body = (await axios.get<string>("https://ekimemo.com/news?page=8")).data
  const dom = new JSDOM(body)
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

function getUpdateDate(dom: JSDOM, publish: Date): Date {
  const list = dom.window.document.querySelectorAll(".news-body > p")
  for (const e of list) {
    const m = e.textContent?.match(/(?<month>[0-9]{1,2})\/(?<day>[0-9]{1,2})に以下の内容にて駅情報の更新を予定/)
    if (m && m.groups) {
      const month = parseInt(m.groups["month"])
      const day = parseInt(m.groups["day"])
      const date = new Date(publish.getFullYear(), month, day)
      while (date.getTime() < publish.getDate()) {
        date.setFullYear(date.getFullYear() + 1)
      }
      return date
    }
  }
  throw Error("update date not found")
}

async function processNewsItem(path: string) {
  const body = (await axios.get<string>(`https://ekimemo.com${path}`)).data
  const dom = new JSDOM(body)
  const publish = new Date(dom.window.document.querySelector(".news-status > .news-publish-time")?.getAttribute("datetime")!)
  const update = getUpdateDate(dom, publish)
  const newsBody = dom.window.document.querySelector(".news-body")?.innerHTML
  console.log(publish, update)
}

(async () => {

  process.env.TZ = "Asia/Tokyo"
  await import("dotenv/config")

  const octokit = new Octokit({
    auth: process.env.GITHUB_ACCESS_TOKEN,
  })
  const d = await octokit.request("GET /repos/{owner}/{repo}/issues", {
    owner: "Seo-4d696b75",
    repo: "station_database",
    state: "open",
    labels: "駅情報更新",
  })
  const paths = await getNewsPath()
  for (const path of paths) {
    await processNewsItem(path)
  }
})()