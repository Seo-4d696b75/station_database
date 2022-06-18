import Ajv from "ajv";
import {readFileSync} from "fs"
import { jsonLineList } from "./model/line";
import { station, stationList } from "./model/station";

const ajv = new Ajv()
const str = readFileSync("out/main/line.json").toString()
const validate = ajv.compile(jsonLineList)
const data = JSON.parse(str)
const result = validate(data)
console.log(result, validate.errors)