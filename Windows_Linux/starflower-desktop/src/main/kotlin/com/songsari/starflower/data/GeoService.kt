package com.songsari.starflower.data

import com.songsari.starflower.model.GeoResult
import com.squareup.moshi.Json
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.net.URLEncoder

/**
 * 지오코딩. Nominatim 을 우선 쓰고(한국어는 한국 우선 + 전세계 병렬),
 * 실패 시 Open-Meteo 백업. iOS/Android GeoService 와 동일한 동작.
 */
object GeoService {

    private val client = OkHttpClient()
    private val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()

    private val placeTypes = setOf(
        "city", "town", "village", "hamlet", "municipality",
        "suburb", "neighbourhood", "quarter", "borough",
        "city_district", "district", "county", "province",
        "state", "region", "administrative", "island"
    )

    private fun isKorean(s: String): Boolean = s.any {
        val v = it.code
        (v in 0xAC00..0xD7A3) || (v in 0x1100..0x11FF) || (v in 0x3130..0x318F)
    }

    suspend fun search(query: String): List<GeoResult> {
        val q = query.trim()
        if (q.length < 2) return emptyList()
        runCatching { searchNominatim(q) }.getOrNull()?.let { if (it.isNotEmpty()) return it }
        return runCatching { searchOpenMeteo(q) }.getOrNull() ?: emptyList()
    }

    // ── Nominatim ─────────────────────────────────────────
    private suspend fun searchNominatim(q: String): List<GeoResult> = coroutineScope {
        if (isKorean(q)) {
            val kr = async { runCatching { nominatimFetch(q, "kr") }.getOrDefault(emptyList()) }
            val all = async { runCatching { nominatimFetch(q, null) }.getOrDefault(emptyList()) }
            val krItems = kr.await()
            val allItems = all.await()
            val krIds = krItems.map { it.placeId }.toSet()
            parseItems(krItems + allItems.filter { it.placeId !in krIds })
        } else {
            parseItems(nominatimFetch(q, null))
        }
    }

    private suspend fun nominatimFetch(q: String, countryCode: String?): List<NominatimItem> =
        withContext(Dispatchers.IO) {
            val sb = StringBuilder("https://nominatim.openstreetmap.org/search")
            sb.append("?q=").append(URLEncoder.encode(q, "UTF-8"))
            sb.append("&format=jsonv2&addressdetails=1&accept-language=ko&limit=10")
            if (countryCode != null) sb.append("&countrycodes=").append(countryCode)

            val req = Request.Builder()
                .url(sb.toString())
                .header("Accept-Language", "ko")
                .header("User-Agent", "Starflower/1.0 (stargazing app)")
                .build()

            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) throw RuntimeException("http ${resp.code}")
                val body = resp.body?.string() ?: "[]"
                val type = Types.newParameterizedType(List::class.java, NominatimItem::class.java)
                val adapter = moshi.adapter<List<NominatimItem>>(type)
                adapter.fromJson(body) ?: emptyList()
            }
        }

    private fun parseItems(items: List<NominatimItem>): List<GeoResult> {
        val sorted = items.sortedByDescending { it.importance ?: 0.0 }
        val seen = HashSet<String>()
        val out = ArrayList<GeoResult>()
        for (it in sorted) {
            val kind = it.addresstype ?: it.type ?: ""
            val isPlace = kind in placeTypes || it.category == "place" || it.category == "boundary"
            if (!isPlace) continue
            val lat = it.lat.toDoubleOrNull() ?: continue
            val lon = it.lon.toDoubleOrNull() ?: continue
            val a = it.address
            val name = it.name
                ?: a?.city ?: a?.town ?: a?.village
                ?: it.displayName.split(",").firstOrNull()?.trim()
                ?: ""
            val admin1 = a?.state ?: a?.province
            val country = a?.country
            val key = "$name|${admin1 ?: ""}|${country ?: ""}"
            if (key in seen) continue
            seen.add(key)
            out.add(GeoResult(it.placeId, name, admin1, country, lat, lon))
            if (out.size >= 6) break
        }
        return out
    }

    // ── Open-Meteo 백업 ───────────────────────────────────
    private suspend fun searchOpenMeteo(q: String): List<GeoResult> =
        withContext(Dispatchers.IO) {
            val url = "https://geocoding-api.open-meteo.com/v1/search" +
                "?name=${URLEncoder.encode(q, "UTF-8")}&count=6&language=ko&format=json"
            val req = Request.Builder().url(url).build()
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string() ?: "{}"
                val parsed = moshi.adapter(OpenMeteoGeoResponse::class.java).fromJson(body)
                parsed?.results?.map {
                    GeoResult(it.id, it.name, it.admin1, it.country, it.latitude, it.longitude)
                } ?: emptyList()
            }
        }
}

data class NominatimItem(
    @Json(name = "place_id") val placeId: Int,
    val lat: String,
    val lon: String,
    val name: String?,
    @Json(name = "display_name") val displayName: String,
    val addresstype: String?,
    val type: String?,
    val category: String?,
    val importance: Double?,
    val address: NominatimAddress?,
)

data class NominatimAddress(
    val city: String?,
    val town: String?,
    val village: String?,
    val county: String?,
    val state: String?,
    val province: String?,
    val country: String?,
)

data class OpenMeteoGeoResponse(val results: List<OpenMeteoGeoItem>?)

data class OpenMeteoGeoItem(
    val id: Int,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val country: String?,
    val admin1: String?,
)
