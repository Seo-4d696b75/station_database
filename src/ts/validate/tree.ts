import { JSONKdTreeSegmentNode } from "../model/tree";
import { Assert } from "./assert";

export function validateTreeSegment(
  segment: { root: number, node_list: JSONKdTreeSegmentNode[] },
  assert: Assert,
) {
  const map = new Map<number, JSONKdTreeSegmentNode>()
  segment.node_list.forEach(node => map.set(node.code, node))
  const queue = [segment.root]
  while (queue.length > 0) {
    const code = queue.shift() ?? 0
    const node = map.get(code)
    assert(node, "nodeが見つからない code:" + code)
    if (node) {
      map.delete(code)
      if (node.segment) {

      } else {
        if (node.left) queue.push(node.left)
        if (node.right) queue.push(node.right)
      }
    }
  }
  assert(map.size === 0, "treeのグラフ構造が連結でない")
}