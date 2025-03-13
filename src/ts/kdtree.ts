import { JSONSchemaType } from 'ajv'
import { jsonVoronoi, JSONVoronoiGeo } from './model/geo'
import { JSONKdTreeNode, JSONKdTreeSegment, JSONKdTreeSegmentNode } from './model/tree'

// src/diagram/build/diagram*.json
export interface JSONDiagramStations {
  root: number
  node_list: JSONDiagramStation[]
}

export type JSONDiagramStation = JSONKdTreeNode & {
  next: number[]
  voronoi: JSONVoronoiGeo
}

export const jsonDiagramStations: JSONSchemaType<JSONDiagramStations> = {
  type: 'object',
  properties: {
    root: { type: 'number' },
    node_list: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          code: { type: 'number' },
          name: { type: 'string' },
          lat: { type: 'number' },
          lng: { type: 'number' },
          left: { type: 'number', nullable: true },
          right: { type: 'number', nullable: true },
          next: { type: 'array', items: { type: 'number' } },
          voronoi: jsonVoronoi,
        },
        required: ['code', 'name', 'lat', 'lng', 'next', 'voronoi']
      },
    },
  },
  required: ['root', 'node_list']
}

export class KdTreeParser {
  private code: number
  private depth: number
  private left: KdTreeParser | null
  private right: KdTreeParser | null
  private lat: number
  private lng: number
  private name: string

  constructor(data: JSONDiagramStation, depth: number, map: Map<number, JSONDiagramStation>) {
    this.code = data.code
    this.lat = data.lat
    this.lng = data.lng
    this.name = data.name
    this.depth = depth
    this.left = data.left ? new KdTreeParser(map.get(data.left)!, depth + 1, map) : null
    this.right = data.right ? new KdTreeParser(map.get(data.right)!, depth + 1, map) : null
  }

  serialize(depth = 4): JSONKdTreeSegment[] {
    const segments: JSONKdTreeSegment[] = []
    const root: JSONKdTreeSegment = {
      name: 'root',
      root: this.code,
      node_list: [],
    }
    segments.push(root)
    this.toSegment(depth, root.node_list, segments)
    console.log(`tree-segment name:root depth:${depth}`)
    return segments
  }

  private toSegment(depth: number, nodes: JSONKdTreeSegmentNode[], segments: JSONKdTreeSegment[]) {
    const node: JSONKdTreeSegmentNode = {
      code: this.code,
      name: this.name,
      lat: this.lat,
      lng: this.lng,
      segment: undefined,
      left: this.left?.code,
      right: this.right?.code
    }
    nodes.push(node)

    if (this.depth === depth) {
      const name = `segment${segments.length}`
      node.segment = name
      const segment: JSONKdTreeSegment = {
        name: name,
        root: this.code,
        node_list: [],
      }
      segments.push(segment)
      this.toSegment(-1, segment.node_list, segments)
      console.log(`tree-segment name:${name} size:${segment.node_list.length}`)
    } else {
      this.left?.toSegment(depth, nodes, segments)
      this.right?.toSegment(depth, nodes, segments)
    }
  }
} 