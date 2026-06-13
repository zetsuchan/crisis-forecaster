import Foundation

/// Local weather signals relevant to VOC risk. Barometric pressure drops and
/// low humidity are documented triggers.
struct WeatherSnapshot: Codable, Sendable, Hashable {
    var capturedAt: Date
    /// millibars / hPa
    var pressure: Double?
    var pressureTrend: String?
    /// change over the next 24h (mb); negative = dropping front incoming
    var deltaPressure24h: Double?
    /// relative humidity 0–1
    var humidity: Double?
    var temperatureC: Double?

    init(
        capturedAt: Date = Date(),
        pressure: Double? = nil,
        pressureTrend: String? = nil,
        deltaPressure24h: Double? = nil,
        humidity: Double? = nil,
        temperatureC: Double? = nil
    ) {
        self.capturedAt = capturedAt
        self.pressure = pressure
        self.pressureTrend = pressureTrend
        self.deltaPressure24h = deltaPressure24h
        self.humidity = humidity
        self.temperatureC = temperatureC
    }
}
