package com.songsari.starflower.data

import com.squareup.moshi.Json
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query

// ── 응답 데이터 구조 ──────────────────────────────────────
data class WeatherResponse(
    val current: CurrentWeather,
    val hourly: HourlyWeather,
    val daily: DailyWeather,
)

data class CurrentWeather(
    val time: String,
    @Json(name = "temperature_2m") val temperature2m: Double,
    @Json(name = "relative_humidity_2m") val relativeHumidity2m: Double,
    @Json(name = "cloud_cover") val cloudCover: Double,
    @Json(name = "wind_speed_10m") val windSpeed10m: Double,
    @Json(name = "surface_pressure") val surfacePressure: Double,
    @Json(name = "weather_code") val weatherCode: Int,
    @Json(name = "is_day") val isDay: Int,
)

data class HourlyWeather(
    val time: List<String>,
    @Json(name = "cloud_cover") val cloudCover: List<Double>,
    @Json(name = "relative_humidity_2m") val relativeHumidity2m: List<Double>,
    @Json(name = "wind_speed_10m") val windSpeed10m: List<Double>,
    @Json(name = "temperature_2m") val temperature2m: List<Double>,
    @Json(name = "weather_code") val weatherCode: List<Int>,
)

data class DailyWeather(
    val time: List<String>,
    val sunrise: List<String>,
    val sunset: List<String>,
)

data class AirResponse(val hourly: AirHourly)

data class AirHourly(
    val time: List<String>,
    @Json(name = "pm2_5") val pm25: List<Double?>,
)

// ── Retrofit API ──────────────────────────────────────────
private interface OpenMeteoApi {
    @GET("v1/forecast")
    suspend fun forecast(
        @Query("latitude") lat: Double,
        @Query("longitude") lng: Double,
        @Query("current") current: String,
        @Query("hourly") hourly: String,
        @Query("daily") daily: String,
        @Query("wind_speed_unit") windUnit: String,
        @Query("timezone") timezone: String,
        @Query("forecast_days") forecastDays: Int,
        @Query("past_days") pastDays: Int,
    ): WeatherResponse
}

private interface AirQualityApi {
    @GET("v1/air-quality")
    suspend fun air(
        @Query("latitude") lat: Double,
        @Query("longitude") lng: Double,
        @Query("hourly") hourly: String,
        @Query("timezone") timezone: String,
        @Query("forecast_days") forecastDays: Int,
    ): AirResponse
}

// ── WeatherService ─────────────────────────────────────────
object WeatherService {

    private val moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()

    private val weatherApi: OpenMeteoApi = Retrofit.Builder()
        .baseUrl("https://api.open-meteo.com/")
        .addConverterFactory(MoshiConverterFactory.create(moshi))
        .build()
        .create(OpenMeteoApi::class.java)

    private val airApi: AirQualityApi = Retrofit.Builder()
        .baseUrl("https://air-quality-api.open-meteo.com/")
        .addConverterFactory(MoshiConverterFactory.create(moshi))
        .build()
        .create(AirQualityApi::class.java)

    suspend fun fetchWeather(lat: Double, lng: Double): WeatherResponse =
        weatherApi.forecast(
            lat = lat,
            lng = lng,
            current = "temperature_2m,relative_humidity_2m,cloud_cover,wind_speed_10m,surface_pressure,weather_code,is_day",
            hourly = "cloud_cover,relative_humidity_2m,wind_speed_10m,temperature_2m,weather_code",
            daily = "sunrise,sunset",
            windUnit = "ms",
            timezone = "auto",
            forecastDays = 4,
            pastDays = 1,
        )

    /** 대기질은 실패해도 진행 (null 반환) */
    suspend fun fetchAir(lat: Double, lng: Double): AirResponse? =
        try {
            airApi.air(
                lat = lat,
                lng = lng,
                hourly = "pm2_5",
                timezone = "auto",
                forecastDays = 4,
            )
        } catch (e: Exception) {
            null
        }
}
