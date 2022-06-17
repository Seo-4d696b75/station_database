import Ajv from "ajv";
import {readFileSync} from "fs"
import { station, stationList } from "./model/station";

const ajv = new Ajv()
const str = readFileSync("out/main/station.json").toString()
const validate = ajv.compile(stationList)
const data = JSON.parse(str)
const result = validate(data)
console.log(result, validate.errors)