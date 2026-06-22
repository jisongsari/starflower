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
        // 기본 인수
        let L = rad * (218.316 + 13.176396 * d)   // 평균 황경
        let M = rad * (134.963 + 13.064993 * d)   // 평균 근점 이각
        let F = rad * (93.272  + 13.229350 * d)   // 위도 인수
        let D = rad * (297.850 + 12.190749 * d)   // 평균 이각 (태양-달)
        let Ms = rad * (357.529 + 0.985600 * d)   // 태양 평균 근점 이각

        // 황경 섭동 (주요 항 추가)
        let dL = rad * (
              6.289 * sin(M)
            - 1.274 * sin(2*D - M)          // evection
            + 0.658 * sin(2*D)              // variation
            - 0.186 * sin(Ms)               // 연주 방정식
            - 0.059 * sin(2*M - 2*D)
            - 0.057 * sin(M - 2*D + Ms)
            + 0.053 * sin(M + 2*D)
            + 0.046 * sin(2*D - Ms)
            + 0.041 * sin(M - Ms)
            - 0.035 * sin(D)
            - 0.031 * sin(M + Ms)
            - 0.015 * sin(2*F - 2*D)
            + 0.011 * sin(M - 4*D)
        )
        // 황위 섭동
        let dB = rad * (
              5.128 * sin(F)
            + 0.280 * sin(M + F)
            + 0.277 * sin(M - F)
            + 0.173 * sin(2*D - F)
            + 0.055 * sin(2*D - M + F)
            + 0.046 * sin(2*D - M - F)
            - 0.046 * sin(2*D + F)
            + 0.030 * sin(M + 2*D - F)
        )
        // 거리 섭동 (km)
        let dist = 385001
            - 20905 * cos(M)
            - 3699  * cos(2*D - M)
            - 2956  * cos(2*D)
            + 570   * cos(2*M)
            - 246   * cos(2*M - 2*D)
            + 205   * cos(Ms - 2*D)
            + 171   * cos(M + 2*D)

        let l = L + dL
        let b = dB

        return (rightAscension(l, b), declination(l, b), Double(dist))
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
    
    // ── 월출·월몰 (고도가 0을 교차하는 시각 탐색) ──────────
    // 기준 시각부터 24시간 내, 10분 간격으로 부호 변화 탐색
    // ── 월출·월몰 (기준일 기반, 익일 보완 포함) ──────────────
    // referenceDate: 계산 기준이 되는 날짜 (0~6시엔 전일을 넘겨야 함)
    static func moonRiseSet(
        referenceDate: Date,
        lat: Double,
        lng: Double
    ) -> (rise: Date?, set: Date?) {
        let cal = Calendar.current
        // 기준일 00:00 ~ 24:00
        let startOfDay = cal.startOfDay(for: referenceDate)
        let endOfDay   = startOfDay.addingTimeInterval(24 * 3600)

        var rise: Date?, set: Date?
        let step: TimeInterval = 60
        var t = startOfDay.timeIntervalSince1970
        var prevAlt = position(date: Date(timeIntervalSince1970: t), lat: lat, lng: lng).altitude

        while t < endOfDay.timeIntervalSince1970 {
            t += step
            let d = Date(timeIntervalSince1970: t)
            let alt = position(date: d, lat: lat, lng: lng).altitude
            if prevAlt < 0 && alt >= 0 && rise == nil { rise = d }
            if prevAlt >= 0 && alt < 0 && set  == nil { set  = d }
            prevAlt = alt
        }

        // 익일 보완 검색
        func nextDaySearch(from searchStart: Date) -> (rise: Date?, set: Date?) {
            var nr: Date?, ns: Date?
            var t2 = searchStart.timeIntervalSince1970
            var prev = position(date: Date(timeIntervalSince1970: t2), lat: lat, lng: lng).altitude
            let limit = t2 + 26 * 3600
            while t2 < limit {
                t2 += step
                let d = Date(timeIntervalSince1970: t2)
                let a = position(date: d, lat: lat, lng: lng).altitude
                if prev < 0 && a >= 0 && nr == nil { nr = d }
                if prev >= 0 && a < 0  && ns == nil { ns = d }
                if nr != nil && ns != nil { break }
                prev = a
            }
            return (nr, ns)
        }

        // 둘 다 있으면
        if let r = rise, let s = set {
            if r < s {
                // 월출이 월몰보다 빠름 → 그대로 사용
                return (r, s)
            } else {
                // 월몰이 월출보다 빠름 → 월몰을 익일로 교체
                let next = nextDaySearch(from: endOfDay)
                return (r, next.set)
            }
        }
        // 월출만 있음 → 월몰을 익일에서 찾기
        if let r = rise, set == nil {
            let next = nextDaySearch(from: endOfDay)
            return (r, next.set)
        }
        // 월몰만 있음 → 월출을 익일에서 찾기
        if rise == nil, let s = set {
            let next = nextDaySearch(from: endOfDay)
            return (next.rise, s)
        }
        // 둘 다 없음 → 익일에서 둘 다 찾기
        let next = nextDaySearch(from: endOfDay)
        return (next.rise, next.set)
    }
}
