package com.songsari.starflower.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.songsari.starflower.calc.MoonCalculator
import com.songsari.starflower.calc.ScoreCalculator
import com.songsari.starflower.data.AirResponse
import com.songsari.starflower.data.LocationStore
import com.songsari.starflower.data.WeatherResponse
import com.songsari.starflower.data.WeatherService
import com.songsari.starflower.model.DayForecast
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.GeoResult
import com.songsari.starflower.model.NightInputs
import com.songsari.starflower.model.SavedLocation
import com.songsari.starflower.model.SkyCondition
import com.songsari.starflower.model.StargazingData
import com.songsari.starflower.widget.WidgetScheduler
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class StargazingViewModel(app: Application) : AndroidViewModel(app) {

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

    private val weekdays = listOf("일", "월", "화", "수", "목", "금", "토")
    private fun cal() = Calendar.getInstance(TimeZone.getDefault())

    init {
        viewModelScope.launch {
            val loc = LocationStore.load(getApplication())
            if (loc != null) {
                _savedLocation.value = loc
                loadData()
            } else {
                _showSearch.value = true
            }
        }
    }

    fun setShowSearch(v: Boolean) { _showSearch.value = v }

    fun selectLocation(r: GeoResult) {
        val loc = SavedLocation(r.name, r.admin1, r.country, r.latitude, r.longitude)
        _savedLocation.value = loc
        _showSearch.value = false
        _data.value = null   // 이전 데이터 치워 로딩창 표시
        viewModelScope.launch {
            LocationStore.save(getApplication(), loc)
            WidgetScheduler.updateNow(getApplication())
            loadData()
        }
    }

    fun loadData() {
        val loc = _savedLocation.value ?: return
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                val wxDeferred = async { WeatherService.fetchWeather(loc.latitude, loc.longitude) }
                val airDeferred = async { WeatherService.fetchAir(loc.latitude, loc.longitude) }
                val wx = wxDeferred.await()
                val air = airDeferred.await()
                _data.value = buildData(loc, wx, air)
                // 데이터 갱신 후
                WidgetScheduler.updateNow(getApplication())
            } catch (e: Exception) {
                _errorMessage.value = "날씨 정보를 불러오지 못했어요."
            } finally {
                _isLoading.value = false
            }
        }
    }

    // ── 데이터 조립 (iOS buildData 1:1) ───────────────────
    private fun buildData(loc: SavedLocation, wx: WeatherResponse, air: AirResponse?): StargazingData {
        val now = Date()
        val cur = wx.current
        val hourly = wx.hourly
        val lat = loc.latitude
        val lng = loc.longitude

        val c = cal().apply { time = now }
        val hour = c.get(Calendar.HOUR_OF_DAY)
        val todayEvening = if (hour < 6) addDays(now, -1) else now

        val forecast = ArrayList<DayForecast>()
        var n0Cloud = cur.cloudCover
        var n0Hum = cur.relativeHumidity2m
        var n0Wind = cur.windSpeed10m
        var n0Pm = 0.0

        for (i in 0 until 3) {
            val evening = addDays(todayEvening, i)
            val eStr = dateStr(evening)
            val mStr = dateStr(addDays(evening, 1))
            val idxs = nightIndices(hourly.time, eStr, mStr)

            val cloud = avg(idxs.map { hourly.cloudCover[it] })
            val hum = avg(idxs.map { hourly.relativeHumidity2m[it] })
            val wind = avg(idxs.map { hourly.windSpeed10m[it] })
            val pm = airAvg(air, hourly.time, idxs)
            if (i == 0) { n0Cloud = cloud; n0Hum = hum; n0Wind = wind; n0Pm = pm }

            val moonMid = MoonCalculator.illumination(nightMidnight(eStr))
            val exposure = MoonCalculator.nightExposure(nightStart(eStr), nightEnd(eStr), lat, lng)
            val score = ScoreCalculator.compute(
                NightInputs(cloud, hum, pm, wind, moonMid.fraction, exposure)
            )
            val repIdx = idxs.firstOrNull { hourly.time[it].endsWith("T23:00") } ?: idxs.firstOrNull() ?: -1
            val repCode = if (repIdx >= 0) hourly.weatherCode[repIdx] else cur.weatherCode
            val cond = classifySky(repCode, cloud)
            val label = if (i == 0) "오늘" else weekdays[weekdayIndex(evening)]
            forecast.add(DayForecast(evening, label, score, cond))
        }

        val moonNow = MoonCalculator.illumination(now)
        val moonPos = MoonCalculator.position(now, lat, lng)
        val condition = forecast.firstOrNull()?.condition ?: classifySky(cur.weatherCode, cur.cloudCover)

        // 낮/밤/노을
        val sunNow = MoonCalculator.getSunAltitude(now, lat, lng)
        val sunLater = MoonCalculator.getSunAltitude(Date(now.time + 600_000), lat, lng)
        val tw = 0.12
        val daypart = when {
            sunNow > tw -> Daypart.DAY
            sunNow < -tw -> Daypart.NIGHT
            else -> if (sunLater > sunNow) Daypart.DAWN else Daypart.DUSK
        }

        // past_days=1 → daily[0]=어제, [1]=오늘, [2]=내일
        val daily = wx.daily
        val todayIdx = 1
        val isEarly = hour < 6
        val chosenSunset = parseDate(daily.sunset[if (isEarly) 0 else todayIdx])
        val chosenSunrise = parseDate(
            daily.sunrise[if (isEarly) todayIdx else minOf(todayIdx + 1, daily.sunrise.size - 1)]
        )

        // 월출·월몰: 0~6시면 전일 기준, 그 외 오늘 기준
        val moonRefDate: Date = if (hour < 6) startOfDay(addDays(now, -1)) else startOfDay(now)
        val moonRS = MoonCalculator.moonRiseSet(moonRefDate, lat, lng)

        return StargazingData(
            location = loc,
            score = forecast.firstOrNull()?.score ?: 0,
            condition = condition,
            daypart = daypart,
            temperature = cur.temperature2m,
            pressure = cur.surfacePressure,
            nightCloud = n0Cloud,
            nightHumidity = n0Hum,
            nightWind = n0Wind,
            nightPm25 = n0Pm,
            sunrise = chosenSunrise,
            sunset = chosenSunset,
            moonIllum = moonNow.fraction,
            moonPhase = moonNow.phase,
            moonAltitude = moonPos.altitude,
            moonName = ScoreCalculator.moonPhaseName(moonNow.phase),
            moonrise = moonRS.rise,
            moonset = moonRS.set,
            forecast = forecast,
            updatedAt = now,
        )
    }

    // ── 유틸 ──────────────────────────────────────────────
    private val ymdFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }
    private val isoFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }

    private fun dateStr(d: Date): String = ymdFmt.format(d)

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

    private fun weekdayIndex(d: Date): Int {
        val c = cal().apply { time = d }
        return c.get(Calendar.DAY_OF_WEEK) - 1   // 일=1 → 0
    }

    private fun nightIndices(times: List<String>, e: String, m: String): List<Int> =
        times.indices.filter { i ->
            val t = times[i]
            val d = t.take(10)
            val h = t.drop(11).take(2).toIntOrNull() ?: return@filter false
            (d == e && h >= 19) || (d == m && h <= 5)
        }

    private fun ymdToDate(s: String, hour: Int, addDay: Int = 0): Date {
        val parts = s.split("-").mapNotNull { it.toIntOrNull() }
        val c = cal()
        c.clear()
        c.set(parts[0], parts[1] - 1, parts[2] + addDay, hour, 0, 0)
        return c.time
    }

    private fun nightStart(e: String) = ymdToDate(e, 19)
    private fun nightMidnight(e: String) = ymdToDate(e, 24)      // 다음날 00:00
    private fun nightEnd(e: String) = ymdToDate(e, 5, addDay = 1)

    private fun avg(v: List<Double>): Double {
        val f = v.filter { it.isFinite() }
        return if (f.isEmpty()) 0.0 else f.sum() / f.size
    }

    private fun airAvg(air: AirResponse?, times: List<String>, idxs: List<Int>): Double {
        if (air == null) return 0.0
        val vals = idxs.mapNotNull { i ->
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

    private fun parseDate(s: String): Date = try {
        isoFmt.parse(s) ?: Date()
    } catch (e: Exception) {
        Date()
    }
}
