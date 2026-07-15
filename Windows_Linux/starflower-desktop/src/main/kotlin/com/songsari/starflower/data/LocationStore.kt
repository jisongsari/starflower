package com.songsari.starflower.data

import com.songsari.starflower.model.SavedLocation
import java.util.prefs.Preferences

/**
 * 안드로이드 DataStore 대응. 데스크탑은 java.util.prefs.Preferences 사용
 * (OS별로 실제 저장 위치가 다르지만 API 는 동일 — 윈도우는 레지스트리, 리눅스는 ~/.java 계열)
 */
object LocationStore {
    private val prefs = Preferences.userRoot().node("com/songsari/starflower")

    private const val KEY_NAME = "locationName"
    private const val KEY_ADMIN1 = "admin1"
    private const val KEY_COUNTRY = "country"
    private const val KEY_LAT = "latitude"
    private const val KEY_LNG = "longitude"

    fun load(): SavedLocation? {
        val name = prefs.get(KEY_NAME, null) ?: return null
        val lat = prefs.getDouble(KEY_LAT, Double.NaN)
        val lng = prefs.getDouble(KEY_LNG, Double.NaN)
        if (lat.isNaN() || lng.isNaN()) return null
        return SavedLocation(
            name = name,
            admin1 = prefs.get(KEY_ADMIN1, null),
            country = prefs.get(KEY_COUNTRY, null),
            latitude = lat,
            longitude = lng,
        )
    }

    fun save(loc: SavedLocation) {
        prefs.put(KEY_NAME, loc.name)
        if (loc.admin1 != null) prefs.put(KEY_ADMIN1, loc.admin1) else prefs.remove(KEY_ADMIN1)
        if (loc.country != null) prefs.put(KEY_COUNTRY, loc.country) else prefs.remove(KEY_COUNTRY)
        prefs.putDouble(KEY_LAT, loc.latitude)
        prefs.putDouble(KEY_LNG, loc.longitude)
    }
}
