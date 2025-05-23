import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common"

Item {
    id: weatherWidget
    width: weatherRow.width
    height: parent.height

    property string weatherLocation: "City"
    property var weatherData: ({
        currentTemp: "",
        feelsLike: "",
        currentEmoji: "❓"
    })

    Timer {
        interval: 600000  // Update every 10 minutes
        running: true
        repeat: true
        onTriggered: loadWeather()
    }

    Component.onCompleted: {
        loadWeather()
    }

    RowLayout {
        id: weatherRow
        height: parent.height
        spacing: 8
        anchors {
            centerIn: parent
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -8
        }

        Text {
            id: weatherIcon
            text: weatherData.currentEmoji || "❓"
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer0
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: temperature
                text: weatherData.currentTemp || "?"
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: feelsLike
                text: weatherData.feelsLike ? "(" + weatherData.feelsLike + ")" : ""
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                opacity: 0.8
                Layout.alignment: Qt.AlignVCenter
                visible: weatherData.feelsLike !== ""
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        ToolTip.visible: containsMouse
        ToolTip.text: weatherData.currentCondition || "Weather"
        ToolTip.delay: 500
    }

    function getWeatherEmoji(condition) {
        if (!condition) return "❓"
        condition = condition.toLowerCase()

        if (condition.includes("clear")) return "☀️"
        if (condition.includes("mainly clear")) return "🌤️"
        if (condition.includes("partly cloudy")) return "⛅"
        if (condition.includes("cloud") || condition.includes("overcast")) return "☁️"
        if (condition.includes("fog") || condition.includes("mist")) return "🌫️"
        if (condition.includes("drizzle")) return "🌦️"
        if (condition.includes("rain") || condition.includes("showers")) return "🌧️"
        if (condition.includes("freezing rain")) return "🌧️❄️"
        if (condition.includes("snow") || condition.includes("snow grains") || condition.includes("snow showers")) return "❄️"
        if (condition.includes("thunderstorm")) return "⛈️"
        if (condition.includes("wind")) return "🌬️"
        return "❓"
    }

    function mapWeatherCode(code) {
        switch(code) {
            case 0: return "Clear sky";
            case 1: return "Mainly clear";
            case 2: return "Partly cloudy";
            case 3: return "Overcast";
            case 45: return "Fog";
            case 48: return "Depositing rime fog";
            case 51: return "Light drizzle";
            case 53: return "Moderate drizzle";
            case 55: return "Dense drizzle";
            case 56: return "Light freezing drizzle";
            case 57: return "Dense freezing drizzle";
            case 61: return "Slight rain";
            case 63: return "Moderate rain";
            case 65: return "Heavy rain";
            case 66: return "Light freezing rain";
            case 67: return "Heavy freezing rain";
            case 71: return "Slight snow fall";
            case 73: return "Moderate snow fall";
            case 75: return "Heavy snow fall";
            case 77: return "Snow grains";
            case 80: return "Slight rain showers";
            case 81: return "Moderate rain showers";
            case 82: return "Violent rain showers";
            case 85: return "Slight snow showers";
            case 86: return "Heavy snow showers";
            case 95: return "Thunderstorm";
            case 96: return "Thunderstorm with slight hail";
            case 99: return "Thunderstorm with heavy hail";
            default: return "Unknown";
        }
    }

    function loadWeather() {
        var geocodeXhr = new XMLHttpRequest();
        var geocodeUrl = "https://nominatim.openstreetmap.org/search?format=json&q=" + encodeURIComponent(weatherLocation);

        geocodeXhr.onreadystatechange = function() {
            if (geocodeXhr.readyState === XMLHttpRequest.DONE) {
                if (geocodeXhr.status === 200) {
                    try {
                        var geoData = JSON.parse(geocodeXhr.responseText);
                        if (geoData.length > 0) {
                            var latitude = parseFloat(geoData[0].lat);
                            var longitude = parseFloat(geoData[0].lon);
                            fetchWeather(latitude, longitude);
                        } else {
                            fallbackWeatherData("City not found");
                        }
                    } catch (e) {
                        console.error("Geocoding error:", e);
                        fallbackWeatherData("Error");
                    }
                } else {
                    console.error("Geocoding request failed:", geocodeXhr.status);
                    fallbackWeatherData("Error");
                }
            }
        };

        geocodeXhr.open("GET", geocodeUrl);
        geocodeXhr.setRequestHeader("User-Agent", "StatusBar_Ly-sec/1.0");
        geocodeXhr.send();
    }

    function fetchWeather(latitude, longitude) {
        var xhr = new XMLHttpRequest();
        var url = "https://api.open-meteo.com/v1/forecast?" +
                "latitude=" + latitude +
                "&longitude=" + longitude +
                "&current=temperature_2m,apparent_temperature,weather_code" +
                "&timezone=auto";

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        console.log("Weather data:", JSON.stringify(data));

                        var currentTemp = Math.round(parseFloat(data.current.temperature_2m));
                        var feelsLikeTemp = Math.round(parseFloat(data.current.apparent_temperature));
                        var weatherCode = data.current.weather_code;

                        weatherData = {
                            currentTemp: currentTemp + "°C",
                            feelsLike: feelsLikeTemp + "°C",
                            currentEmoji: getWeatherEmoji(mapWeatherCode(weatherCode)),
                            currentCondition: mapWeatherCode(weatherCode)
                        };

                        console.log("Processed weather data:", JSON.stringify(weatherData));
                    } catch (e) {
                        console.error("Weather parsing error:", e);
                        fallbackWeatherData("Error");
                    }
                } else {
                    console.error("Weather request failed:", xhr.status);
                    fallbackWeatherData("Error");
                }
            }
        };

        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "StatusBar_Ly-sec/1.0");
        xhr.send();
    }

    function fallbackWeatherData(message) {
        weatherData = {
            currentTemp: "?",
            feelsLike: "",
            currentEmoji: "❓",
            currentCondition: message
        };
    }
} 