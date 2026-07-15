package com.songsari.starflower.calc

import com.songsari.starflower.model.NightInputs
import com.songsari.starflower.model.SkyCondition
import kotlin.math.pow

/**
 * 별 관측 지수 계산. iOS/Android ScoreCalculator 와 완전히 동일한 공식.
 *
 *   I = max(0, B - Δhum - Δpm - Δwind - Δmoon)
 */
object ScoreCalculator {

    fun compute(i: NightInputs): Int {
        val cloud = i.cloud.coerceIn(0.0, 100.0)
        val base = 100 * (1 - cloud / 100).pow(1.5)
        val dHum = 20 * (((i.humidity - 40) / 60).coerceAtLeast(0.0)).pow(1.5)
        val dPm = 10 * (i.pm25 / 75).coerceIn(0.0, 1.0).pow(0.8)
        val dWind = 7 * (((i.wind - 3) / 12).coerceAtLeast(0.0)).pow(2.0).coerceIn(0.0, 1.0)
        val dMoon = 8 * i.moonIllum.coerceIn(0.0, 1.0) * i.moonExposure.coerceIn(0.0, 1.0)
        val s = (base - dHum - dPm - dWind - dMoon).coerceIn(0.0, 100.0)
        return Math.round(s).toInt()
    }

    fun verdict(score: Int): String = when (score) {
        in 80..100 -> "최상의 관측 조건"
        in 60..79 -> "관측하기 좋아요"
        in 40..59 -> "그럭저럭 볼 만해요"
        in 20..39 -> "관측이 어려워요"
        else -> "오늘은 별 보기 힘들어요"
    }

    fun moonPhaseName(phase: Double): String {
        val p = ((phase % 1.0) + 1.0) % 1.0
        return when {
            p < 0.03 || p >= 0.97 -> "삭월"
            p < 0.22 -> "초승달"
            p < 0.28 -> "상현달"
            p < 0.47 -> "상현망간의 달"
            p < 0.53 -> "보름달"
            p < 0.72 -> "하현망간의 달"
            p < 0.78 -> "하현달"
            else -> "그믐달"
        }
    }

    fun pmLabel(pm: Double): String = when {
        pm < 15 -> "좋음"
        pm < 35 -> "보통"
        pm < 75 -> "나쁨"
        else -> "매우 나쁨"
    }

    fun conditionLabel(c: SkyCondition): String = when (c) {
        SkyCondition.CLEAR -> "맑음"
        SkyCondition.PARTLY -> "구름 조금"
        SkyCondition.CLOUDY -> "구름 많음"
        SkyCondition.OVERCAST -> "흐림"
        SkyCondition.FOG -> "안개"
        SkyCondition.RAIN -> "비"
        SkyCondition.SNOW -> "눈"
    }

    /** 운량 라벨 (classifySky 경계 15/50/85 와 일치) */
    fun cloudLabel(v: Double): String = when {
        v < 15 -> "맑음"
        v < 50 -> "구름 조금"
        v < 85 -> "구름 많음"
        else -> "흐림"
    }

    fun humLabel(v: Double): String = when {
        v < 50 -> "건조"
        v < 75 -> "보통"
        else -> "습함"
    }

    fun windLabel(v: Double): String = when {
        v < 3 -> "잔잔"
        v < 8 -> "약풍"
        else -> "강풍"
    }
}
