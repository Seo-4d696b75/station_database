
import { readCsvSafe, readJsonSafe } from "./io";
import { csvLine, jsonLineList } from "./model/line";
import { csvStation, jsonStation, jsonStationList } from "./model/station";

let list = readCsvSafe("out/main/line.csv", csvLine)
console.log(list[0])
