package com.songsari.starflower.data

import com.songsari.starflower.model.GeoResult
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import java.util.prefs.Preferences

/** 최근 검색한 지역 (최대 10개, 최신순). */
object RecentSearchStore {
    private val prefs = Preferences.userRoot().node("com/songsari/starflower")
    private const val KEY = "recentSearches"
    private const val MAX = 10

    private val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
    private val listType = Types.newParameterizedType(List::class.java, GeoResult::class.java)
    private val adapter = moshi.adapter<List<GeoResult>>(listType)

    fun load(): List<GeoResult> {
        val json = prefs.get(KEY, null) ?: return emptyList()
        return try {
            adapter.fromJson(json) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun add(result: GeoResult) {
        val current = load().toMutableList()
        current.removeAll { it.name == result.name && it.admin1 == result.admin1 && it.country == result.country }
        current.add(0, result)
        val trimmed = current.take(MAX)
        prefs.put(KEY, adapter.toJson(trimmed))
    }

    fun remove(result: GeoResult) {
        val current = load().toMutableList()
        current.removeAll { it.name == result.name && it.admin1 == result.admin1 && it.country == result.country }
        prefs.put(KEY, adapter.toJson(current))
    }

    fun clear() {
        prefs.remove(KEY)
    }
}
