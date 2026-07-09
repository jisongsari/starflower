package com.songsari.starflower.data

import android.content.Context
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.songsari.starflower.model.SavedLocation
import kotlinx.coroutines.flow.first

private val Context.dataStore by preferencesDataStore(name = "starflower")

/**
 * 저장된 관측 위치를 보관한다. iOS 의 App Group UserDefaults 와 동일한 역할.
 * 위젯(Glance)도 같은 DataStore 를 읽어 데이터를 공유한다.
 */
object LocationStore {

    private val KEY_NAME = stringPreferencesKey("locationName")
    private val KEY_ADMIN1 = stringPreferencesKey("admin1")
    private val KEY_COUNTRY = stringPreferencesKey("country")
    private val KEY_LAT = doublePreferencesKey("latitude")
    private val KEY_LNG = doublePreferencesKey("longitude")

    suspend fun load(context: Context): SavedLocation? {
        val p = context.dataStore.data.first()
        val name = p[KEY_NAME] ?: return null
        val lat = p[KEY_LAT] ?: return null
        val lng = p[KEY_LNG] ?: return null
        return SavedLocation(
            name = name,
            admin1 = p[KEY_ADMIN1],
            country = p[KEY_COUNTRY],
            latitude = lat,
            longitude = lng,
        )
    }

    suspend fun save(context: Context, loc: SavedLocation) {
        context.dataStore.edit { p ->
            p[KEY_NAME] = loc.name
            if (loc.admin1 != null) p[KEY_ADMIN1] = loc.admin1 else p.remove(KEY_ADMIN1)
            if (loc.country != null) p[KEY_COUNTRY] = loc.country else p.remove(KEY_COUNTRY)
            p[KEY_LAT] = loc.latitude
            p[KEY_LNG] = loc.longitude
        }
    }
}
