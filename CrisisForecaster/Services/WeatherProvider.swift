import Foundation

/// Weather seam, mirroring HealthDataSource. Demo Mode uses a scripted incoming
/// cold front; Live Mode (WeatherService) uses WeatherKit.
protocol WeatherProvider: Sendable {
    func currentWeather() async throws -> WeatherSnapshot
}

/// Scripted "pressure dropping 15mb tonight" front for the demo.
struct DemoWeatherProvider: WeatherProvider {
    func currentWeather() async throws -> WeatherSnapshot {
        WeatherSnapshot(
            capturedAt: Date(),
            pressure: 1004,
            pressureTrend: "falling",
            deltaPressure24h: -15,
            humidity: 0.34,
            temperatureC: 4
        )
    }
}
