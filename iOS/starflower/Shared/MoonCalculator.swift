import Foundation

struct MoonPosition {
    var altitude: Double    // 라디안
    var azimuth: Double
}

struct MoonIllumination {
    var fraction: Double    // 밝은 면 비율 0~1
    var phase: Double       // 0~1 (0=삭, 0.25=상현, 0.5=망, 0.75=하현)
    var waxing: Bool
}

// SunCalc 알고리즘을 그대로 옮긴 구현 (웹앱과 동일한 결과)
struct MoonCalculator {

    private static let rad = Double.pi / 180
    private static let e   = (Double.pi / 180) * 23.4397   // 황도 경사

    // ── 시간 변환 ─────────────────────────────────────────
    private static func toDays(_ date: Date) -> Double {
        // J2000.0 기준 (율리우스일 - 2451545)
        let J1970 = 2440588.0
        let J2000 = 2451545.0
        let julian = date.timeIntervalSince1970 / 86400.0 - 0.5 + J1970
        return julian - J2000
    }

    // ── 좌표 변환 헬퍼 ────────────────────────────────────
    private static func rightAscension(_ l: Double, _ b: Double) -> Double {
        atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))
    }
    private static func declination(_ l: Double, _ b: Double) -> Double {
        asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l))
    }

    // ── 태양 좌표 ─────────────────────────────────────────
    private static func solarMeanAnomaly(_ d: Double) -> Double {
        rad * (357.5291 + 0.98560028 * d)
    }
    private static func eclipticLongitude(_ M: Double) -> Double {
        let C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M))
        let P = rad * 102.9372
        return M + C + P + .pi
    }
    private static func sunCoords(_ d: Double) -> (dec: Double, ra: Double) {
        let M = solarMeanAnomaly(d)
        let L = eclipticLongitude(M)
        return (declination(L, 0), rightAscension(L, 0))
    }

    // ── 달 좌표 ───────────────────────────────────────────
    private static func moonCoords(_ d: Double) -> (ra: Double, dec: Double, dist: Double) {
        let L = rad * (218.316 + 13.176396 * d)
        let M = rad * (134.963 + 13.064993 * d)
        let F = rad * (93.272  + 13.229350 * d)
        let l = L + rad * 6.289 * sin(M)
        let b = rad * 5.128 * sin(F)
        let dt = 385001 - 20905 * cos(M)
        return (rightAscension(l, b), declination(l, b), dt)
    }

    // ── 달 위상 (SunCalc.getMoonIllumination) ─────────────
    static func illumination(date: Date) -> MoonIllumination {
        let d = toDays(date)
        let s = sunCoords(d)
        let m = moonCoords(d)
        let sdist = 149_598_000.0  // 태양까지 거리 (km)

        let phi = acos(
            sin(s.dec) * sin(m.dec) +
            cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra)
        )
        let inc = atan2(sdist * sin(phi), m.dist - sdist * cos(phi))
        let angle = atan2(
            cos(s.dec) * sin(s.ra - m.ra),
            sin(s.dec) * cos(m.dec) - cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra)
        )

        let fraction = (1 + cos(inc)) / 2
        let phase = 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / .pi

        return MoonIllumination(
            fraction: fraction,
            phase: phase,
            waxing: phase < 0.5
        )
    }

    // ── 달 위치 (SunCalc.getMoonPosition) ─────────────────
    static func position(date: Date, lat: Double, lng: Double) -> MoonPosition {
        let lw  = rad * -lng
        let phi = rad * lat
        let d   = toDays(date)
        let c   = moonCoords(d)

        let H = siderealTime(d, lw) - c.ra
        var h = altitude(H, phi, c.dec)
        h += astroRefraction(h)  // 대기 굴절 보정

        let az = atan2(
            sin(H),
            cos(H) * sin(phi) - tan(c.dec) * cos(phi)
        )

        return MoonPosition(altitude: h, azimuth: az + .pi)
    }

    private static func siderealTime(_ d: Double, _ lw: Double) -> Double {
        rad * (280.16 + 360.9856235 * d) - lw
    }
    private static func altitude(_ H: Double, _ phi: Double, _ dec: Double) -> Double {
        asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H))
    }
    private static func astroRefraction(_ h0: Double) -> Double {
        let h = max(0, h0)
        return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179))
    }

    // ── 밤 동안 달 노출도 (30분 샘플링 평균) ──────────────
    static func nightExposure(start: Date, end: Date, lat: Double, lng: Double) -> Double {
        let step: Double = 30 * 60
        var sum = 0.0, count = 0
        var t = start.timeIntervalSince1970
        while t <= end.timeIntervalSince1970 {
            let pos = position(date: Date(timeIntervalSince1970: t), lat: lat, lng: lng)
            sum += max(0, sin(pos.altitude))
            count += 1
            t += step
        }
        return count > 0 ? sum / Double(count) : 0
    }

    // ── 태양 고도 (낮/밤/노을 판정용) ─────────────────────
    static func getSunAltitude(date: Date, lat: Double, lng: Double) -> Double {
        let lw  = rad * -lng
        let phi = rad * lat
        let d   = toDays(date)
        let c   = sunCoords(d)
        let H   = siderealTime(d, lw) - c.ra
        return altitude(H, phi, c.dec)
    }
}
