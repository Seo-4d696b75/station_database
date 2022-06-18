
import { readCsvSafe, readJsonSafe } from "./io";
import { jsonLineList } from "./model/line";
import { csvStation, jsonStation, jsonStationList } from "./model/station";

let list = readCsvSafe("out/extra/station.csv", csvStation)
console.log(list[0])
