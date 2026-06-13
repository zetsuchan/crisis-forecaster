import Foundation
import CoreLocation
import WeatherKit

/// Live weather via Apple WeatherKit. Requires the WeatherKit entitlement and
/// location permission. Provides current pressure/humidity plus a 24h pressure
/// delta from the hourly forecast (a falling delta = incoming front).
struct WeatherKitService: WeatherProvider {
    func currentWeather() async throws -> WeatherSnapshot {
        let location = try await LocationProvider.shared.currentLocation()
        let weather = try await WeatherKit.WeatherService.shared.weather(for: location)

        let current = weather.currentWeather
        let pressureMb = current.pressure.converted(to: .hectopascals).value

        // 24h pressure delta from the hourly forecast.
        let now = Date()
        let in24h = now.addingTimeInterval(24 * 3600)
        let future = weather.hourlyForecast.first { $0.date >= in24h }
        let delta = future.map { $0.pressure.converted(to: .hectopascals).value - pressureMb }

        return WeatherSnapshot(
            capturedAt: now,
            pressure: pressureMb,
            pressureTrend: trendString(current.pressureTrend),
            deltaPressure24h: delta,
            humidity: current.humidity,
            temperatureC: current.temperature.converted(to: .celsius).value
        )
    }

    private func trendString(_ trend: PressureTrend) -> String {
        switch trend {
        case .rising: "rising"
        case .falling: "falling"
        case .steady: "steady"
        @unknown default: "steady"
        }
    }
}

/// One-shot async wrapper around CLLocationManager.
@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = LocationProvider()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    enum LocationError: Error { case denied, unavailable }

    func currentLocation() async throws -> CLLocation {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            throw LocationError.denied
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            guard let location = locations.last else {
                continuation?.resume(throwing: LocationError.unavailable)
                continuation = nil
                return
            }
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
