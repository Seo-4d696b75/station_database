
import { writeFileSync } from "fs";
import { jsonDelaunayList } from "./model/delaunay";
import { jsonPolyline } from "./model/geo";
import { jsonLineList } from "./model/line";
import { jsonLineDetail } from "./model/lineDetail";
import { jsonStationList } from "./model/station";
import { jsonKdTree, jsonKdTreeSegment } from "./model/tree";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { Dataset, parseDataset } from "./model/dataset";
import { join } from "path";

// CLI引数の解析
const argv = yargs(hideBin(process.argv))
  .option('extra', {
    alias: 'e',
    type: 'boolean',
    description: 'extraデータセットを対象とします',
    default: false
  })
  .help()
  .argv

async function main() {
  const dataset: Dataset = (await Promise.resolve(argv)).extra ? 'extra' : 'main'
  const dir = `out/${dataset}/schema`

  // station.json
  writeFileSync(join(dir, "station.schema.json"), JSON.stringify(jsonStationList(dataset), undefined, 2))
  // line.json
  writeFileSync(join(dir, "line.schema.json"), JSON.stringify(jsonLineList(dataset), undefined, 2))
  // line/*.json
  writeFileSync(join(dir, "line_detail.schema.json"), JSON.stringify(jsonLineDetail(dataset), undefined, 2))
  // delaunay.json
  writeFileSync(join(dir, "delaunay.schema.json"), JSON.stringify(jsonDelaunayList, undefined, 2))
  // tree.json
  writeFileSync(join(dir, "tree.schema.json"), JSON.stringify(jsonKdTree, undefined, 2))
  // tree/*.json
  writeFileSync(join(dir, "tree_segment.schema.json"), JSON.stringify(jsonKdTreeSegment(dataset), undefined, 2))
  // polyline/*.json
  writeFileSync(join(dir, "polyline.schema.json"), JSON.stringify(jsonPolyline, undefined, 2))
}

main()