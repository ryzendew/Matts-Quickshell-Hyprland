import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "root:/modules/common"

Item {
    id: root
    anchors.fill: parent

    // Use WeatherForecast as a hidden data provider
    Loader {
        id: weatherLoader
        source: "../weather/WeatherForecast.qml"
        visible: false
        onLoaded: {
            if (item) {
                root.forecastData = item.forecastData
                root.locationDisplay = item.locationDisplay
                root.currentTemp = item.currentTemp
                root.feelsLike = item.feelsLike
                item.forecastDataChanged.connect(function() { 
                    root.forecastData = item.forecastData
                    console.log("Weather forecast updated. Days available:", item.forecastData.length)
                })
                item.locationDisplayChanged.connect(function() { root.locationDisplay = item.locationDisplay })
                item.currentTempChanged.connect(function() { root.currentTemp = item.currentTemp })
                item.feelsLikeChanged.connect(function() { root.feelsLike = item.feelsLike })
                // Force a fresh load to ensure we get 7 days
                item.loadWeather()
            }
        }
    }

    property var forecastData: []
    property string locationDisplay: ""
    property string lastUpdated: Qt.formatDateTime(new Date(), "hh:mm AP")
    property string currentTemp: "--"
    property string feelsLike: "--"
    property string airQuality: "--"
    property real latitude: 44.65 // Halifax default
    property real longitude: -63.57
    property var weatherAlerts: []

    // Function to manually refresh weather data
    function refreshWeather() {
        root.lastUpdated = Qt.formatDateTime(new Date(), "hh:mm AP")
        if (weatherLoader.item) {
            weatherLoader.item.clearCache()
            weatherLoader.item.loadWeather()
        }
        // Also refresh air quality
        airQualityLoader.active = false
        airQualityLoader.active = true
        // Refresh weather alerts
        weatherAlertsLoader.active = false
        weatherAlertsLoader.active = true
    }

    // Loader to fetch air quality from Open-Meteo
    Loader {
        id: airQualityLoader
        active: true
        asynchronous: true
        sourceComponent: QtObject {
            Component.onCompleted: {
                var xhr = new XMLHttpRequest();
                var url = `https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${root.latitude}&longitude=${root.longitude}&hourly=us_aqi`;
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            try {
                                var data = JSON.parse(xhr.responseText);
                                if (data.hourly && data.hourly.us_aqi && data.hourly.us_aqi.length > 0) {
                                    var aqiValue = data.hourly.us_aqi[0];
                                    root.airQuality = (aqiValue !== undefined && aqiValue !== null) ? String(aqiValue) : "--";
                                } else {
                                    root.airQuality = "--";
                                }
                            } catch (e) { root.airQuality = "--"; }
                        } else { root.airQuality = "--"; }
                    }
                };
                xhr.open("GET", url);
                xhr.send();
            }
        }
    }

    // Loader to fetch weather alerts from Open-Meteo
    Loader {
        id: weatherAlertsLoader
        active: true
        asynchronous: true
        sourceComponent: QtObject {
            Component.onCompleted: {
                var xhr = new XMLHttpRequest();
                var url = `https://api.open-meteo.com/v1/forecast?latitude=${root.latitude}&longitude=${root.longitude}&current_weather=true&alerts=true`;
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            try {
                                var data = JSON.parse(xhr.responseText);
                                if (data.alerts && data.alerts.length > 0) {
                                    root.weatherAlerts = data.alerts;
                                } else {
                                    root.weatherAlerts = [];
                                }
                            } catch (e) { root.weatherAlerts = []; }
                        } else { root.weatherAlerts = []; }
                    }
                };
                xhr.open("GET", url);
                xhr.send();
            }
        }
    }

    // Isolated weather tab content
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Layout.margins: 0

        // Header with location and refresh button
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: Appearance.colors.colLayer2
            radius: 0
            border.color: Appearance.colors.colOnLayer0
            border.width: 0
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: root.locationDisplay
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        horizontalAlignment: Text.AlignLeft
                        Layout.alignment: Qt.AlignLeft
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.lastUpdated ? qsTr("Updated ") + root.lastUpdated : ""
                        font.pixelSize: Appearance.font.pixelSize.tiny
                        color: Appearance.colors.colOnLayer1
                        opacity: 0.7
                        horizontalAlignment: Text.AlignLeft
                        Layout.alignment: Qt.AlignLeft
                        elide: Text.ElideRight
                    }
                }
                
                // Refresh button
                Rectangle {
                    width: 28
                    height: 28
                    radius: Appearance.rounding.small
                    color: "transparent"
                    border.width: 0
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.refreshWeather()
                        onEntered: parent.color = Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.15)
                        onExited: parent.color = "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "🔄"
                            font.pixelSize: 12
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.6
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOnLayer0
            opacity: 0.2
        }

        // Current weather info section
        Rectangle {
            Layout.fillWidth: true
            height: 64
            color: Appearance.colors.colLayer1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16
                
                // Current temp and feels like
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { 
                        text: qsTr("Current")
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.tiny
                        font.weight: Font.Medium
                        opacity: 0.8
                    }
                    RowLayout {
                        spacing: 8
                        Text { 
                            text: root.currentTemp
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                        }
                        Text { 
                            text: qsTr("feels ") + root.feelsLike
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                            opacity: 0.7
                        }
                    }
                }
                
                // Vertical separator
                Rectangle {
                    width: 1
                    height: 40
                    color: Appearance.colors.colOnLayer0
                    opacity: 0.2
                }
                
                // Wind and humidity
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        spacing: 12
                        ColumnLayout {
                            spacing: 2
                            Text { 
                                text: qsTr("Wind")
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.tiny
                                opacity: 0.8
                            }
                            Text { 
                                text: root.forecastData.length > 0 && root.forecastData[0].wind ? root.forecastData[0].wind + " km/h" : "--"
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { 
                                text: qsTr("Humidity")
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.tiny
                                opacity: 0.8
                            }
                            Text { 
                                text: root.forecastData.length > 0 && root.forecastData[0].humidity ? root.forecastData[0].humidity + "%" : "--"
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOnLayer0
            opacity: 0.2
        }

        // Weather Alerts Box (shows only if there are alerts)
        Rectangle {
            visible: root.weatherAlerts.length > 0
            Layout.fillWidth: true
            implicitHeight: alertColumn.implicitHeight + 16
            color: Qt.rgba(1, 0.3, 0.2, 0.1)
            border.color: Qt.rgba(1, 0.3, 0.2, 0.3)
            border.width: 1
            
            ColumnLayout {
                id: alertColumn
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                Repeater {
                    model: root.weatherAlerts
                    delegate: ColumnLayout {
                        spacing: 2
                        Text {
                            text: modelData.event || "Weather Alert"
                            font.bold: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Qt.rgba(1, 0.3, 0.2, 1)
                        }
                        Text {
                            text: modelData.description || modelData.sender || ""
                            font.pixelSize: Appearance.font.pixelSize.tiny
                            color: Appearance.colors.colOnLayer1
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }

        // 7-day forecast section
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 0

                // Section header
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: Appearance.colors.colLayer2
                    
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("7-Day Forecast")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        opacity: 0.9
                    }
                }

                // Forecast items
                Repeater {
                    model: Math.min(7, root.forecastData.length)
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 80
                        color: index % 2 === 0 ? Appearance.colors.colLayer1 : Qt.rgba(Appearance.colors.colLayer2.r, Appearance.colors.colLayer2.g, Appearance.colors.colLayer2.b, 0.3)
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 20
                            
                            // Day name
                            Text {
                                Layout.preferredWidth: 60
                                text: root.forecastData[index].date
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer1
                                horizontalAlignment: Text.AlignLeft
                            }
                            
                            // Weather emoji
                            Text {
                                Layout.preferredWidth: 40
                                text: root.forecastData[index].emoji
                                font.pixelSize: 32
                                horizontalAlignment: Text.AlignCenter
                            }
                            
                            // Condition
                            Text {
                                Layout.fillWidth: true
                                text: root.forecastData[index].condition
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.85
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }
                            
                            // Temperature
                            Text {
                                Layout.preferredWidth: 80
                                text: root.forecastData[index].temp
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer1
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        
                        // Bottom separator for each item except last
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.1
                            visible: index < Math.min(7, root.forecastData.length) - 1
                        }
                    }
                }
                
                // Placeholder if no data
                Item {
                    visible: !root.forecastData || root.forecastData.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 32
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.3
                            horizontalAlignment: Text.AlignHCenter
                            text: "☁️"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.5
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("No forecast data")
                        }
                    }
                }
            }
        }
    }
} 