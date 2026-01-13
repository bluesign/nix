import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string btcPrice: "..."
    property string flowPrice: "..."
    property bool loading: true

    // Fetch prices on startup and every 60 seconds
    Timer {
        id: refreshTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchPrices()
    }

    function fetchPrices() {
        priceProcess.running = true
    }

    Process {
        id: priceProcess
        command: ["sh", "-c", "curl -s 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,flow&vs_currencies=usd' | jq -r '.bitcoin.usd, .flow.usd'"]
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                if (lines.length >= 2) {
                    const btc = parseFloat(lines[0])
                    const flow = parseFloat(lines[1])
                    root.btcPrice = btc >= 1000 ? Math.round(btc).toLocaleString() : btc.toFixed(2)
                    root.flowPrice = flow >= 1 ? flow.toFixed(2) : flow.toFixed(4)
                    root.loading = false
                }
            }
        }
    }

    horizontalBarPill: Component {
        StyledRect {
            id: pill
            width: priceRow.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Row {
                id: priceRow
                anchors.centerIn: parent
                spacing: Theme.spacingM

                // Bitcoin
                Row {
                    spacing: Theme.spacingXS
                    DankIcon {
                        name: "currency_bitcoin"
                        size: Theme.fontSizeMedium
                        color: "#F7931A"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: root.loading ? "..." : "$" + root.btcPrice
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Separator
                StyledText {
                    text: "|"
                    color: Theme.surfaceTextMuted
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Flow
                Row {
                    spacing: Theme.spacingXS
                    StyledText {
                        text: "FLOW"
                        color: "#00EF8B"
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: root.loading ? "..." : "$" + root.flowPrice
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: refreshTimer.triggered()
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            height: priceCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: priceCol
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                StyledText {
                    text: "BTC"
                    color: "#F7931A"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: root.loading ? "..." : "$" + root.btcPrice
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: "FLOW"
                    color: "#00EF8B"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: root.loading ? "..." : "$" + root.flowPrice
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: refreshTimer.triggered()
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
