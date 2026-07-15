package com.songsari.starflower.model

import java.util.Date

/** 하늘 상태 (배경 테마 결정에 사용) */
enum class SkyCondition {
    CLEAR, PARTLY, CLOUDY, OVERCAST, FOG, RAIN, SNOW
}

/** 낮/밤/새벽/노을 */
enum class Daypart {
    DAY, NIGHT, DAWN, DUSK
}

/** 저장되는 위치 정보 */
data class SavedLocation(
    val name: String,
    val admin1: String? = null,
    val country: String? = null,
    val latitude: Double,
    val longitude: Double,
)

/** 지오코딩 검색 결과 한 건 */
data class GeoResult(
    val id: Int,
    val name: String,
    val admin1: String?,
    val country: String?,
    val latitude: Double,
    val longitude: Double,
) {
    val displayName: String
        get() = listOfNotNull(admin1, country).joinToString(", ")
}

/** 지수 계산에 들어가는 한 밤의 평균 입력값 */
data class NightInputs(
    val cloud: Double,
    val humidity: Double,
    val pm25: Double,
    val wind: Double,
    val moonIllum: Double,
    val moonExposure: Double,
)

/** 하루치 예보 카드 요약 */
data class DayForecast(
    val date: Date,
    val label: String,       // 오늘 / 토 / 일 ...
    val score: Int,
    val condition: SkyCondition,
)

/** 메인 화면에 필요한 모든 데이터 */
data class StargazingData(
    val location: SavedLocation,
    val score: Int,
    val condition: SkyCondition,
    val daypart: Daypart,
    val temperature: Double,
    val pressure: Double,
    val nightCloud: Double,
    val nightHumidity: Double,
    val nightWind: Double,
    val nightPm25: Double,
    val sunrise: Date,
    val sunset: Date,
    val moonIllum: Double,
    val moonPhase: Double,
    val moonAltitude: Double,
    val moonName: String,
    val moonrise: Date?,
    val moonset: Date?,
    val forecast: List<DayForecast>,
    val updatedAt: Date,
)
