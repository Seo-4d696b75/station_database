import axios from "axios"
import dotenv from "dotenv"
import { JSDOM } from "jsdom"
import { Octokit } from "octokit"
import path from "path"

// お知らせ一覧から駅情報更新のpathを抽出
async function getNewsPath() {
  const body = (await axios.get<string>("https://ekimemo.com/news?page=1")).data
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
      console.log(`駅情報更新が見つかりました: ${href}`)
    }
  }
  return paths
}

// 駅情報更新の日付をお知らせ詳細から取得
function getUpdateDate(dom: JSDOM, publish: Date): Date {
  const list = dom.window.document.querySelectorAll(".news-body > p")
  for (const e of list) {
    const m = e.textContent?.match(/(?<month>[0-9]{1,2})\/(?<day>[0-9]{1,2})に以下の内容にて駅情報の更新を予定/)
    if (m && m.groups) {
      const month = parseInt(m.groups["month"])
      const day = parseInt(m.groups["day"])
      const date = new Date(publish.getFullYear(), month - 1, day)
      while (date.getTime() < publish.getDate()) {
        date.setFullYear(date.getFullYear() + 1)
      }
      return date
    }
  }
  throw Error("update date not found")
}

// 駅情報更新の登録済みissueを取得
async function getUpdateIssues(octokit: Octokit): Promise<Set<number>> {
  const res = await octokit.request("GET /repos/{owner}/{repo}/issues", {
    owner: "Seo-4d696b75",
    repo: "station_database",
    state: "all",
    labels: "駅情報更新",
  })
  const set = new Set<number>()
  res
    .data
    .forEach(issue => {
      const m = issue.title.match(/(?<date>[0-9]{4}\/[0-9]{2}\/[0-9]{2})/)
      if (m && m.groups) {
        const d = new Date(m.groups["date"])
        set.add(d.getTime())
      }
    })
  return set
}

// 駅情報更新のお知らせを確認＆必要ならissue登録
async function processNewsItem(path: string, issues: Set<number>, octokit: Octokit) {
  const url = `https://ekimemo.com${path}`
  const body = (await axios.get<string>(url)).data
  const dom = new JSDOM(body)
  const publish = new Date(dom.window.document.querySelector(".news-status > .news-publish-time")?.getAttribute("datetime")!)
  const update = getUpdateDate(dom, publish)
  const newsBody = dom.window.document.querySelector(".news-body")?.innerHTML

  const title = update.toLocaleDateString("ja-JP", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })

  if (!issues.has(update.getTime())) {
    const body = `
# 駅情報更新

このissueはGitHubActionsによって自動生成されました.
更新の詳細は[公式のお知らせ](${url})を参照してください.

以下はissueの登録時点におけるお知らせの掲載内容です

--------------------

${newsBody?.replace(/^\s+/, "")}
    `
    await octokit.request("POST /repos/{owner}/{repo}/issues", {
      owner: "Seo-4d696b75",
      repo: "station_database",
      title: title,
      body: body,
      labels: ["駅情報更新"],
    })
    console.log(`issueを登録しました: ${title}`)
  } else {
    console.log(`issueが登録済み: ${title}`)
  }
}

(async () => {

  process.env.TZ = "Asia/Tokyo"

  // get news
  const paths = await getNewsPath()
  if (paths.length === 0) {
    return
  }

  // get issues
  dotenv.config({ path: path.resolve(__dirname, "../.env.local") })
  const octokit = new Octokit({
    auth: process.env.GITHUB_ACCESS_TOKEN,
  })
  const issues = await getUpdateIssues(octokit)

  // check each news, register an issue if needed
  for (const path of paths) {
    await processNewsItem(path, issues, octokit)
  }
})()