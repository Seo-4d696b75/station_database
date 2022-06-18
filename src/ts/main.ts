
import { readCsvSafe, readJsonSafe } from "./io";
import { csvLine, jsonLineList } from "./model/line";
import { csvStation, jsonStation, jsonStationList } from "./model/station";
import glob from "glob";

let list = readCsvSafe("out/main/line.csv", csvLine)
const files = glob.sync("out/main/line/*.json")
console.log(files.length, files[0])
