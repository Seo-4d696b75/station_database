
import { readCsvSafe, readJsonSafe } from "./io";
import { csvLine, jsonLineList } from "./model/line";
import { csvStation, jsonStation, jsonStationList } from "./model/station";
import glob from "glob";
import {writeFileSync} from "fs"

const schema = jsonStation
writeFileSync("out/schema/station.schema.json", JSON.stringify(schema, undefined, 2))