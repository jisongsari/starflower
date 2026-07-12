package com.songsari.starflower.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.songsari.starflower.model.GeoResult
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.flow.first

private val Context.recentSearchDataStore by preferencesDataStore(name = "starflower_recent_search")

/** 최근 검색한 지역 (최대 10개, 최신순). */
object RecentSearchStore {
    private val KEY = stringPreferencesKey("recentSearches")
    private const val MAX = 10

    private val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
    private val listType = Types.newParameterizedType(List::class.java, GeoResult::class.java)
    private val adapter = moshi.adapter<List<GeoResult>>(listType)

    suspend fun load(context: Context): List<GeoResult> {
        val json = context.recentSearchDataStore.data.first()[KEY] ?: return emptyList()
        return try {
            adapter.fromJson(json) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun add(context: Context, result: GeoResult) {
        val current = load(context).toMutableList()
        current.removeAll { it.name == result.name && it.admin1 == result.admin1 && it.country == result.country }
        current.add(0, result)
        val trimmed = current.take(MAX)
        context.recentSearchDataStore.edit { p -> p[KEY] = adapter.toJson(trimmed) }
    }

    suspend fun remove(context: Context, result: GeoResult) {
        val current = load(context).toMutableList()
        current.removeAll { it.name == result.name && it.admin1 == result.admin1 && it.country == result.country }
        context.recentSearchDataStore.edit { p -> p[KEY] = adapter.toJson(current) }
    }

    suspend fun clear(context: Context) {
        context.recentSearchDataStore.edit { p -> p.remove(KEY) }
    }
}