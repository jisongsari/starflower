package com.songsari.starflower.widget

import android.content.Context
import com.songsari.starflower.calc.MoonCalculator
import com.songsari.starflower.calc.ScoreCalculator
import com.songsari.starflower.data.AirResponse
import com.songsari.starflower.data.LocationStore
import com.songsari.starflower.data.WeatherService
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.NightInputs
import com.songsari.starflower.model.SkyCondition
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** 위젯에 표시할 계산된 데이터 (iOS StargazingEntry 대응) */
data class WidgetEntry(
    val score: Int,
    val locationName: String,
    val condition: SkyCondition,
    val daypart: Daypart,
    val moonIllum: Double,
    val moonPhase: Double,
    val moonAltitude: Double,
    val temperature: Double,
    val pressure: Double,
    val nightCloud: Double,
    val nightHumidity: Double,
    val nightWind: Double,
    val nightPm25: Double,
    val sunrise: Date,
    val sunset: Date,
    val moonName: String,
    val moonrise: Date?,
    val moonset: Date?,
    val hasData: Boolean,
)

object WidgetRepository {

    private fun cal() = Calendar.getInstance(TimeZone.getDefault())
    private val ymdFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { timeZone = TimeZone.getDefault() }
    private val isoFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm", Locale.US).apply { timeZone = TimeZone.getDefault() }

    fun dummy(): WidgetEntry = WidgetEntry(
        score = 72, locationName = "수원시",
        condition = SkyCondition.CLEAR, daypart = Daypart.NIGHT,
        moonIllum = 0.3, moonPhase = 0.2, moonAltitude = 0.5,
        temperature = 12.0, pressure = 1013.0,
        nightCloud = 10.0, nightHumidity = 45.0, nightWind = 2.0, nightPm25 = 15.0,
        sunrise = Date(), sunset = Date(), moonName = "초승달",
        moonrise = Date(), moonset = Date(), hasData = false,
    )

    /** 저장된 위치를 읽어 날씨를 받아 지수를 계산. 실패 시 dummy(hasData=false) */
    suspend fun load(context: Context): WidgetEntry {
        val loc = LocationStore.load(context) ?: return dummy()
        val lat = loc.latitude
        val lng = loc.longitude
        val wx = runCatching { WeatherService.fetchWeather(lat, lng) }.getOrNull()
            ?: return dummy().copy(locationName = loc.name)
        val air = WeatherService.fetchAir(lat, lng)

        val now = Date()
        val cur = wx.current
        val hourly = wx.hourly
        val c = cal().apply { time = now }
        val hour = c.get(Calendar.HOUR_OF_DAY)
        val todayEvening = if (hour < 6) addDays(now, -1) else now

        val eStr = ymdFmt.format(todayEvening)
        val mStr = ymdFmt.format(addDays(todayEvening, 1))
        val idxs = hourly.time.indices.filter { i ->
            val t = hourly.time[i]
            val d = t.take(10)
            val h = t.drop(11).take(2).toIntOrNull() ?: return@filter false
            (d == eStr && h >= 19) || (d == mStr && h <= 5)
        }

        val cloud = avg(idxs.map { hourly.cloudCover[it] })
        val hum = avg(idxs.map { hourly.relativeHumidity2m[it] })
        val wind = avg(idxs.map { hourly.windSpeed10m[it] })
        val pm = if (air != null) {
            avg(idxs.mapNotNull { i ->
                if (i >= hourly.time.size) return@mapNotNull null
                val j = air.hourly.time.indexOf(hourly.time[i])
                if (j >= 0) air.hourly.pm25.getOrNull(j) else null
            })
        } else 0.0

        val moonMid = MoonCalculator.illumination(ymdToDate(eStr, 24))
        val exposure = MoonCalculator.nightExposure(ymdToDate(eStr, 19), ymdToDate(eStr, 5, 1), lat, lng)
        val score = ScoreCalculator.compute(NightInputs(cloud, hum, pm, wind, moonMid.fraction, exposure))

        val repIdx = idxs.firstOrNull { hourly.time[it].endsWith("T23:00") } ?: idxs.firstOrNull() ?: -1
        val repCode = if (repIdx >= 0) hourly.weatherCode[repIdx] else cur.weatherCode
        val condition = classifySky(repCode, cloud)

        val moonNow = MoonCalculator.illumination(now)
        val moonPos = MoonCalculator.position(now, lat, lng)

        val sunNow = MoonCalculator.getSunAltitude(now, lat, lng)
        val sunLater = MoonCalculator.getSunAltitude(Date(now.time + 600_000), lat, lng)
        val tw = 0.12
        val daypart = when {
            sunNow > tw -> Daypart.DAY
            sunNow < -tw -> Daypart.NIGHT
            else -> if (sunLater > sunNow) Daypart.DAWN else Daypart.DUSK
        }

        val daily = wx.daily
        val isEarly = hour < 6
        val todayIdx = 1
        val chosenSunset = parseDate(daily.sunset[if (isEarly) 0 else todayIdx])
        val chosenSunrise = parseDate(
            daily.sunrise[if (isEarly) todayIdx else minOf(todayIdx + 1, daily.sunrise.size - 1)]
        )
        val moonRefDate = if (hour < 6) startOfDay(addDays(now, -1)) else startOfDay(now)
        val moonRS = MoonCalculator.moonRiseSet(moonRefDate, lat, lng)

        return WidgetEntry(
            score = score, locationName = loc.name,
            condition = condition, daypart = daypart,
            moonIllum = moonNow.fraction, moonPhase = moonNow.phase, moonAltitude = moonPos.altitude,
            temperature = cur.temperature2m, pressure = cur.surfacePressure,
            nightCloud = cloud, nightHumidity = hum, nightWind = wind, nightPm25 = pm,
            sunrise = chosenSunrise, sunset = chosenSunset,
            moonName = ScoreCalculator.moonPhaseName(moonNow.phase),
            moonrise = moonRS.rise, moonset = moonRS.set, hasData = true,
        )
    }

    // ── 유틸 (ViewModel 과 동일) ──────────────────────────
    private fun addDays(d: Date, n: Int): Date {
        val c = cal().apply { time = d }
        c.add(Calendar.DAY_OF_MONTH, n)
        return c.time
    }
    private fun startOfDay(d: Date): Date {
        val c = cal().apply { time = d }
        c.set(Calendar.HOUR_OF_DAY, 0); c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0); c.set(Calendar.MILLISECOND, 0)
        return c.time
    }
    private fun ymdToDate(s: String, hour: Int, addDay: Int = 0): Date {
        val parts = s.split("-").mapNotNull { it.toIntOrNull() }
        val c = cal()
        c.clear()
        c.set(parts[0], parts[1] - 1, parts[2] + addDay, hour, 0, 0)
        return c.time
    }
    private fun avg(v: List<Double>): Double {
        val f = v.filter { it.isFinite() }
        return if (f.isEmpty()) 0.0 else f.sum() / f.size
    }
    private fun classifySky(code: Int, cloud: Double): SkyCondition = when {
        code >= 95 -> SkyCondition.RAIN
        code in 71..77 || code == 85 || code == 86 -> SkyCondition.SNOW
        code in 51..67 || code in 80..82 -> SkyCondition.RAIN
        code == 45 || code == 48 -> SkyCondition.FOG
        cloud < 15 -> SkyCondition.CLEAR
        cloud < 50 -> SkyCondition.PARTLY
        cloud < 85 -> SkyCondition.CLOUDY
        else -> SkyCondition.OVERCAST
    }
    private fun parseDate(s: String): Date = try { isoFmt.parse(s) ?: Date() } catch (e: Exception) { Date() }
}
