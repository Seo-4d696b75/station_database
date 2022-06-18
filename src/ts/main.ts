import Ajv from "ajv";
import {readFileSync} from "fs"
import { jsonLineList } from "./model/line";
import { jsonStation, jsonStationList } from "./model/station";

const ajv = new Ajv()
const str = readFileSync("out/main/line.json").toString()
const validate = ajv.compile(jsonLineList)
const data = JSON.parse(str)
if(validate(data)){
  console.log(data[0])
}
