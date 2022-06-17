export const stationLineId = {
  type: "string",
  pattern: "[0-9a-f]{6}",
}

export const stationLineName = {
  type: "string",
  minLength: 1,
}

export const kanaName = {
  type: "string",
  pattern: "[\\p{sc=Hiragana}ー・\\p{gc=P}\\s]+",
}

export const dateString = {
  type: "string",
  pattern: "[0-9]{4}-[0-9]{2}-[0-9]{2}",
}