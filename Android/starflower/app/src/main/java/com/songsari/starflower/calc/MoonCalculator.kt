package com.songsari.starflower.calc

import java.util.Calendar
import java.util.Date
import java.util.TimeZone
import kotlin.math.PI
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.acos
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.tan

data class MoonPosition(val altitude: Double, val azimuth: Double)

data class MoonIllumination(
    val fraction: Double,  // 밝은 면 비율 0~1
    val phase: Double,     // 0~1 (0=삭, 0.25=상현, 0.5=망, 0.75=하현)
    val waxing: Boolean,
)

/**
 * SunCalc 알고리즘을 그대로 옮긴 구현 (iOS MoonCalculator 와 동일한 결과).
 * 달 좌표에는 주요 섭동항을 포함해 스텔라리움 대비 ±2~3분 정밀도.
 */
object MoonCalculator {

    private const val rad = PI / 180.0
    private val e = (PI / 180.0) * 23.4397   // 황도 경사

    // ── 시간 변환 ─────────────────────────────────────────
    private fun toDays(date: Date): Double {
        val j1970 = 2440588.0
        val j2000 = 2451545.0
        val julian = date.time / 86_400_000.0 - 0.5 + j1970
        return julian - j2000
    }

    // ── 좌표 변환 헬퍼 ────────────────────────────────────
    private fun rightAscension(l: Double, b: Double): Double =
        atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))

    private fun declination(l: Double, b: Double): Double =
        asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l))

    // ── 태양 좌표 ─────────────────────────────────────────
    private fun solarMeanAnomaly(d: Double): Double = rad * (357.5291 + 0.98560028 * d)

    private fun eclipticLongitude(m: Double): Double {
        val c = rad * (1.9148 * sin(m) + 0.02 * sin(2 * m) + 0.0003 * sin(3 * m))
        val p = rad * 102.9372
        return m + c + p + PI
    }

    private data class SunCoords(val dec: Double, val ra: Double)

    private fun sunCoords(d: Double): SunCoords {
        val m = solarMeanAnomaly(d)
        val l = eclipticLongitude(m)
        return SunCoords(declination(l, 0.0), rightAscension(l, 0.0))
    }

    // ── 달 좌표 (섭동항 포함) ─────────────────────────────
    private data class MoonCoords(val ra: Double, val dec: Double, val dist: Double)

    private fun moonCoords(d: Double): MoonCoords {
        val L = rad * (218.316 + 13.176396 * d)
        val M = rad * (134.963 + 13.064993 * d)
        val F = rad * (93.272 + 13.229350 * d)
        val D = rad * (297.850 + 12.190749 * d)
        val Ms = rad * (357.529 + 0.985600 * d)

        val dL = rad * (
            6.289 * sin(M)
                - 1.274 * sin(2 * D - M)
                + 0.658 * sin(2 * D)
                - 0.186 * sin(Ms)
                - 0.059 * sin(2 * M - 2 * D)
                - 0.057 * sin(M - 2 * D + Ms)
                + 0.053 * sin(M + 2 * D)
                + 0.046 * sin(2 * D - Ms)
                + 0.041 * sin(M - Ms)
                - 0.035 * sin(D)
                - 0.031 * sin(M + Ms)
                - 0.015 * sin(2 * F - 2 * D)
                + 0.011 * sin(M - 4 * D)
            )
        val dB = rad * (
            5.128 * sin(F)
                + 0.280 * sin(M + F)
                + 0.277 * sin(M - F)
                + 0.173 * sin(2 * D - F)
                + 0.055 * sin(2 * D - M + F)
                + 0.046 * sin(2 * D - M - F)
                - 0.046 * sin(2 * D + F)
                + 0.030 * sin(M + 2 * D - F)
            )
        val dist = 385001.0 -
            20905 * cos(M) -
            3699 * cos(2 * D - M) -
            2956 * cos(2 * D) +
            570 * cos(2 * M) -
            246 * cos(2 * M - 2 * D) +
            205 * cos(Ms - 2 * D) +
            171 * cos(M + 2 * D)

        val l = L + dL
        val b = dB
        return MoonCoords(rightAscension(l, b), declination(l, b), dist)
    }

    // ── 달 위상 ───────────────────────────────────────────
    fun illumination(date: Date): MoonIllumination {
        val d = toDays(date)
        val s = sunCoords(d)
        val m = moonCoords(d)
        val sdist = 149_598_000.0

        val phi = acos(
            sin(s.dec) * sin(m.dec) +
                cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra)
        )
        val inc = atan2(sdist * sin(phi), m.dist - sdist * cos(phi))
        val angle = atan2(
            cos(s.dec) * sin(s.ra - m.ra),
            sin(s.dec) * cos(m.dec) - cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra)
        )

        val fraction = (1 + cos(inc)) / 2
        val phase = 0.5 + 0.5 * inc * (if (angle < 0) -1 else 1) / PI
        return MoonIllumination(fraction, phase, phase < 0.5)
    }

    // ── 달 위치 ───────────────────────────────────────────
    fun position(date: Date, lat: Double, lng: Double): MoonPosition {
        val lw = rad * -lng
        val phi = rad * lat
        val d = toDays(date)
        val c = moonCoords(d)

        val h0 = siderealTime(d, lw) - c.ra
        var h = altitude(h0, phi, c.dec)
        h += astroRefraction(h)

        val az = atan2(
            sin(h0),
            cos(h0) * sin(phi) - tan(c.dec) * cos(phi)
        )
        return MoonPosition(h, az + PI)
    }

    private fun siderealTime(d: Double, lw: Double): Double = rad * (280.16 + 360.9856235 * d) - lw

    private fun altitude(h: Double, phi: Double, dec: Double): Double =
        asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(h))

    private fun astroRefraction(h0: Double): Double {
        val h = max(0.0, h0)
        return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179))
    }

    // ── 밤 동안 달 노출도 (30분 샘플링 평균) ──────────────
    fun nightExposure(start: Date, end: Date, lat: Double, lng: Double): Double {
        val step = 30 * 60 * 1000L
        var sum = 0.0
        var count = 0
        var t = start.time
        while (t <= end.time) {
            val pos = position(Date(t), lat, lng)
            sum += max(0.0, sin(pos.altitude))
            count++
            t += step
        }
        return if (count > 0) sum / count else 0.0
    }

    // ── 태양 고도 ─────────────────────────────────────────
    fun getSunAltitude(date: Date, lat: Double, lng: Double): Double {
        val lw = rad * -lng
        val phi = rad * lat
        val d = toDays(date)
        val c = sunCoords(d)
        val h = siderealTime(d, lw) - c.ra
        return altitude(h, phi, c.dec)
    }

    // ── 월출·월몰 (기준일 기반, 익일 보완 포함) ────────────
    data class RiseSet(val rise: Date?, val set: Date?)

    fun moonRiseSet(referenceDate: Date, lat: Double, lng: Double): RiseSet {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.time = referenceDate
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val startOfDay = cal.timeInMillis
        val endOfDay = startOfDay + 24 * 3600 * 1000L

        var rise: Date? = null
        var set: Date? = null
        val step = 60 * 1000L
        var t = startOfDay
        var prevAlt = position(Date(t), lat, lng).altitude

        while (t < endOfDay) {
            t += step
            val alt = position(Date(t), lat, lng).altitude
            if (prevAlt < 0 && alt >= 0 && rise == null) rise = Date(t)
            if (prevAlt >= 0 && alt < 0 && set == null) set = Date(t)
            prevAlt = alt
        }

        fun nextDaySearch(searchStart: Long): RiseSet {
            var nr: Date? = null
            var ns: Date? = null
            var t2 = searchStart
            var prev = position(Date(t2), lat, lng).altitude
            val limit = t2 + 26 * 3600 * 1000L
            while (t2 < limit) {
                t2 += step
                val a = position(Date(t2), lat, lng).altitude
                if (prev < 0 && a >= 0 && nr == null) nr = Date(t2)
                if (prev >= 0 && a < 0 && ns == null) ns = Date(t2)
                if (nr != null && ns != null) break
                prev = a
            }
            return RiseSet(nr, ns)
        }

        // 둘 다 있으면
        if (rise != null && set != null) {
            return if (rise.before(set)) {
                RiseSet(rise, set)                       // 월출이 빠름 → 그대로
            } else {
                RiseSet(rise, nextDaySearch(endOfDay).set) // 월몰이 빠름 → 월몰 익일
            }
        }
        if (rise != null && set == null) {
            return RiseSet(rise, nextDaySearch(endOfDay).set)
        }
        if (rise == null && set != null) {
            return RiseSet(nextDaySearch(endOfDay).rise, set)
        }
        val next = nextDaySearch(endOfDay)
        return RiseSet(next.rise, next.set)
    }
}
