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

    Timer {
        id: refreshTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!priceProcess.running) {
                priceProcess.running = true
            }
        }
    }

    Process {
        id: priceProcess
        command: ["curl", "-sS", "--fail", "--connect-timeout", "5", "--max-time", "10",
                  "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,flow&vs_currencies=usd"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const json = JSON.parse(data)
                    if (json.bitcoin && json.bitcoin.usd) {
                        const btc = json.bitcoin.usd
                        root.btcPrice = btc >= 1000 ? Math.round(btc).toLocaleString() : btc.toFixed(2)
                    }
                    if (json.flow && json.flow.usd) {
                        const flow = json.flow.usd
                        root.flowPrice = flow >= 1 ? flow.toFixed(2) : flow.toFixed(4)
                    }
                    root.loading = false
                } catch (e) {
                    console.log("CryptoPriceWidget: Failed to parse response: " + e)
                }
            }
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRect.width
            implicitHeight: parent.widgetThickness

            StyledRect {
                id: pillRect
                width: priceRow.implicitWidth + Theme.spacingM * 2
                height: parent.height
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Row {
                    id: priceRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    Row {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
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

                    StyledText {
                        text: "|"
                        color: Theme.surfaceTextMuted
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
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
                    onClicked: {
                        if (!priceProcess.running) {
                            root.loading = true
                            priceProcess.running = true
                        }
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: parent.widgetThickness
            implicitHeight: pillRectV.height

            StyledRect {
                id: pillRectV
                width: parent.width
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
                    onClicked: {
                        if (!priceProcess.running) {
                            root.loading = true
                            priceProcess.running = true
                        }
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
