import com.seo4d696b75.diagram.station.calculateStationDiagram

/**
 * JSON形式ファイルの入出力で図形計算を行うコンソールアプリケーション
 *
 * [参考：サンプル実装](https://github.com/Seo-4d696b75/diagram/blob/main/sample/README.md)
 */
fun main(args: Array<String>) {
    require(args.size >= 2) {
        "[src] and [dst] args required."
    }
    calculateStationDiagram(args[0], args[1])
}