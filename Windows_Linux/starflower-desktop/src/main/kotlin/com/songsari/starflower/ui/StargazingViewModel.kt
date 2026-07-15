package com.songsari.starflower.ui

import com.songsari.starflower.calc.MoonCalculator
import com.songsari.starflower.calc.ScoreCalculator
import com.songsari.starflower.data.AirResponse
import com.songsari.starflower.data.LocationStore
import com.songsari.starflower.data.RecentSearchStore
import com.songsari.starflower.data.WeatherResponse
import com.songsari.starflower.data.WeatherService
import com.songsari.starflower.model.DayForecast
import com.songsari.starflower.model.GeoResult
import com.songsari.starflower.model.NightInputs
import com.songsari.starflower.model.SavedLocation
import com.songsari.starflower.model.SkyCondition
import com.songsari.starflower.model.StargazingData
import com.songsari.starflower.model.Daypart
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

/**
 * 안드로이드 StargazingViewModel 대응. AndroidViewModel 이 없어
 * 순수 클래스 + 자체 CoroutineScope 로 생명주기를 관리한다.
 * 위젯 관련 로직(WidgetScheduler 등)은 데스크탑 앱에서 제외.
 */
class StargazingViewModel {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    private val _data = MutableStateFlow<StargazingData?>(null)
    val data: StateFlow<StargazingData?> = _data.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _showSearch = MutableStateFlow(false)
    val showSearch: StateFlow<Boolean> = _showSearch.asStateFlow()

    private val _savedLocation = MutableStateFlow<SavedLocation?>(null)
    val savedLocation: StateFlow<SavedLocation?> = _savedLocation.asStateFlow()

    init {
        val loc = LocationStore.load()
        if (loc != null) {
            _savedLocation.value = loc
            scope.launch { loadData() }
        } else {
            _showSearch.value = true
        }
    }

    fun setShowSearch(v: Boolean) {
        _showSearch.value = v
    }

    fun selectLocation(r: GeoResult) {
        val loc = SavedLocation(r.name, r.admin1, r.country, r.latitude, r.longitude)
        _savedLocation.value = loc
        _showSearch.value = false
        _data.value = null
        scope.launch {
            LocationStore.save(loc)
            RecentSearchStore.add(r)
            loadData()
        }
    }

    fun refresh() {
        scope.launch { loadData() }
    }

    suspend fun loadData() {
        val loc = _savedLocation.value ?: return
        _isLoading.value = true
        _errorMessage.value = null
        try {
            val wx = WeatherService.fetchWeather(loc.latitude, loc.longitude)
            val air = WeatherService.fetchAir(loc.latitude, loc.longitude)
            _data.value = buildData(loc, wx, air)
        } catch (e: Exception) {
            _errorMessage.value = "날씨 정보를 불러오지 못했어요."
        }
        _isLoading.value = false
    }

    // ── 데이터 조립 (iOS/안드로이드와 완전히 동일한 로직) ──
    private fun cal() = Calendar.getInstance(TimeZone.getDefault())

    private fun buildData(loc: SavedLocation, wx: WeatherResponse, air: AirResponse?): StargazingData {
        val now = Date()
        val cur = wx.current
        val hourly = wx.hourly
        val lat = loc.latitude
        val lng = loc.longitude

        val c = cal().apply { time = now }
        val hour = c.get(Calendar.HOUR_OF_DAY)
        val todayEvening = if (hour < 6) addDays(now, -1) else now

        val forecast = mutableListOf<DayForecast>()
        for (i in 0 until 3) {
            val evening = addDays(todayEvening, i)
            val eStr = dateStr(evening)
            val mStr = dateStr(addDays(evening, 1))
            val idxs = nightIndices(hourly.time, eStr, mStr)
            val cloud = avg(idxs.map { hourly.cloudCover[it] })
            val hum = avg(idxs.map { hourly.relativeHumidity2m[it] })
            val wind = avg(idxs.map { hourly.windSpeed10m[it] })
            val pm = airAverage(air, hourly.time, idxs)

            val nStart = ymdToDate(eStr, 19)
            val nEnd = ymdToDate(mStr, 5)
            val nMid = ymdToDate(eStr, 24)
            val moonMid = MoonCalculator.illumination(nMid)
            val exposure = MoonCalculator.nightExposure(nStart, nEnd, lat, lng)
            val score = ScoreCalculator.compute(
                NightInputs(cloud, hum, pm, wind, moonMid.fraction, exposure)
            )
            val repIdx = idxs.firstOrNull { hourly.time[it].endsWith("T23:00") } ?: idxs.firstOrNull()
            val repCode = repIdx?.let { hourly.weatherCode[it] } ?: cur.weatherCode
            val condition = classifySky(repCode, cloud)

            val label = when (i) {
                0 -> "오늘"
                else -> weekdayLabel(evening)
            }
            forecast.add(DayForecast(evening, label, score, condition))
        }

        val idxsTonight = nightIndices(hourly.time, dateStr(todayEvening), dateStr(addDays(todayEvening, 1)))
        val nightCloud = avg(idxsTonight.map { hourly.cloudCover[it] })
        val nightHum = avg(idxsTonight.map { hourly.relativeHumidity2m[it] })
        val nightWind = avg(idxsTonight.map { hourly.windSpeed10m[it] })
        val nightPm = airAverage(air, hourly.time, idxsTonight)

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
        val chosenSunset = parseIsoDate(daily.sunset[if (isEarly) 0 else todayIdx])
        val chosenSunrise = parseIsoDate(
            daily.sunrise[if (isEarly) todayIdx else minOf(todayIdx + 1, daily.sunrise.size - 1)]
        )
        val moonRefDate = if (hour < 6) startOfDay(addDays(now, -1)) else startOfDay(now)
        val moonRS = MoonCalculator.moonRiseSet(moonRefDate, lat, lng)

        return StargazingData(
            location = loc,
            score = forecast[0].score,
            condition = forecast[0].condition,
            daypart = daypart,
            temperature = cur.temperature2m,
            pressure = cur.surfacePressure,
            nightCloud = nightCloud, nightHumidity = nightHum,
            nightWind = nightWind, nightPm25 = nightPm,
            sunrise = chosenSunrise, sunset = chosenSunset,
            moonIllum = moonNow.fraction, moonPhase = moonNow.phase, moonAltitude = moonPos.altitude,
            moonName = ScoreCalculator.moonPhaseName(moonNow.phase),
            moonrise = moonRS.rise, moonset = moonRS.set,
            forecast = forecast,
            updatedAt = now,
        )
    }

    // ── 유틸 (안드로이드 WidgetRepository와 동일 패턴) ────
    private val ymdFmt = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        .apply { timeZone = TimeZone.getDefault() }
    private val isoFmt = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm", java.util.Locale.US)
        .apply { timeZone = TimeZone.getDefault() }
    private val weekdays = listOf("일", "월", "화", "수", "목", "금", "토")

    private fun dateStr(d: Date) = ymdFmt.format(d)
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
    private fun weekdayLabel(d: Date): String {
        val c = cal().apply { time = d }
        return weekdays[c.get(Calendar.DAY_OF_WEEK) - 1]
    }
    private fun nightIndices(times: List<String>, eveningDate: String, morningDate: String): List<Int> =
        times.indices.filter { i ->
            val t = times[i]
            val d = t.take(10)
            val h = t.drop(11).take(2).toIntOrNull() ?: return@filter false
            (d == eveningDate && h >= 19) || (d == morningDate && h <= 5)
        }
    private fun avg(v: List<Double>): Double {
        val f = v.filter { it.isFinite() }
        return if (f.isEmpty()) 0.0 else f.sum() / f.size
    }
    private fun airAverage(air: AirResponse?, times: List<String>, indices: List<Int>): Double {
        if (air == null) return 0.0
        val vals = indices.mapNotNull { i ->
            if (i >= times.size) return@mapNotNull null
            val j = air.hourly.time.indexOf(times[i])
            if (j >= 0) air.hourly.pm25.getOrNull(j) else null
        }
        return avg(vals)
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
    private fun parseIsoDate(s: String): Date =
        try { isoFmt.parse(s) ?: Date() } catch (e: Exception) { Date() }
}
