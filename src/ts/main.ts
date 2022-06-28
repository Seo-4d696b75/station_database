
import { readCsvSafe, readJsonSafe } from "./io";
import { csvLine, jsonLineList } from "./model/line";
import { csvStation, jsonStation, jsonStationList } from "./model/station";
import glob from "glob";
import {writeFileSync} from "fs"
import { jsonLineDetail } from "./model/lineDetail";

// station.json
writeFileSync("out/schema/station.schema.json", JSON.stringify(jsonStationList, undefined, 2))
// line.json
writeFileSync("out/schema/line.schema.json", JSON.stringify(jsonLineList, undefined, 2))
// line/*.json
writeFileSync("out/schema/line_detail.schema.json", JSON.stringify(jsonLineDetail, undefined, 2))