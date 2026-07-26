package com.songsari.starflower.data

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.os.Build
import com.songsari.starflower.model.GeoResult
import com.squareup.moshi.Json
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.net.URLEncoder
import java.util.Locale
import kotlin.coroutines.resume
import kotlin.math.abs

/**
 * 지오코딩. Geocoder(구글 백엔드) + Photon(자동완성형 접두 일치)
 * + Open-Meteo(한글 외국 지명·접미사 변형) 3소스 병렬 병합.
 * 병합·랭킹·상위 지명 로직은 iOS GeoService(Photon 최종본) 이식.
 */
object GeoService {

    private val client = OkHttpClient()
    private val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()

    // Geocoder 용 컨텍스트 — Application/MainActivity 에서 init(context) 호출 필요.
    // 미호출 시 Geocoder 소스만 조용히 비활성 (Photon + Open-Meteo 는 동작)
    @Volatile private var appContext: Context? = null
    fun init(context: Context) { appContext = context.applicationContext }

    // 행정 접미사 (긴 것부터 검사해야 '광역시'가 '시'보다 먼저 떨어진다)
    private val adminSuffixes = listOf(
        "특별자치시", "특별자치도", "광역시", "특별시", "도",
        "시", "군", "구", "동", "읍", "면", "리", "가"
    )

    // 이스터에그: 트리거 포함 시 경기과학고를 결과 최상단에 삽입
    private val easterEggTriggers = listOf(
        "경기과학고등학교", "경기과학", "경기과고", "경곽", "송죽학", "펑죽",
        "SRC", "학술정보관", "우정1관", "우정2관", "아름관", "창조관", "학습관"
    )
    private const val EASTER_EGG_QUERY = "경기과학고등학교"

    private fun isKorean(s: String): Boolean = s.any {
        val v = it.code
        (v in 0xAC00..0xD7A3) || (v in 0x1100..0x11FF) || (v in 0x3130..0x318F)
    }

    suspend fun search(query: String): List<GeoResult> = coroutineScope {
        val q = query.trim()
        if (q.length < 2) return@coroutineScope emptyList()

        val normalized = q.replace(" ", "")
        val isEgg = easterEggTriggers.any { normalized.contains(it, ignoreCase = true) }

        val egg = async { if (isEgg) searchEasterEgg() else null }
        val gc = async { runCatching { geocoderSearch(q) }.getOrDefault(emptyList()) }
        val ph = async { runCatching { searchPhoton(q) }.getOrDefault(emptyList()) }
        val om = async { runCatching { searchOpenMeteoExpanded(q) }.getOrDefault(emptyList()) }

        // Geocoder(구글) 결과를 동점 시 우선
        val merged = merge(q, listOf(gc.await(), ph.await(), om.await()))

        val eggResult = egg.await() ?: return@coroutineScope merged
        val eggKey = "${eggResult.name}|${eggResult.admin1 ?: ""}|${eggResult.country ?: ""}"
        (listOf(eggResult) + merged.filterNot {
            "${it.name}|${it.admin1 ?: ""}|${it.country ?: ""}" == eggKey
        }).take(6)
    }

    // ── 이스터에그: Geocoder 우선, 실패 시 Photon POI 폴백 ─
    private suspend fun searchEasterEgg(): GeoResult? {
        runCatching { geocoderSearch(EASTER_EGG_QUERY) }.getOrNull()
            ?.firstOrNull { it.name.contains("경기과학고") }?.let { return it }
        return runCatching { searchPhoton(EASTER_EGG_QUERY, placesOnly = false) }.getOrNull()
            ?.firstOrNull { it.name.contains("경기과학고") }
    }

    // ── 병합·랭킹 (iOS 이식) ──────────────────────────────
    private fun merge(query: String, lists: List<List<GeoResult>>): List<GeoResult> {
        // 1) 키 기준 1차 중복 제거 (입력 순서 유지)
        val seen = HashSet<String>()
        val deduped = ArrayList<GeoResult>()
        for (r in lists.flatten()) {
            val key = "${r.name}|${r.admin1 ?: ""}|${r.country ?: ""}"
            if (!seen.add(key)) continue
            deduped.add(r)
        }

        // 2) (명칭 일치도 → 행정 단위 크기 → 원래 순서) 정렬
        val sorted = deduped.withIndex().sortedWith(
            compareByDescending<IndexedValue<GeoResult>> { matchScore(it.value.name, query) }
                .thenByDescending { levelWeight(it.value.name) }
                .thenBy { it.index }
        ).map { it.value }

        // 3) 접미사 제거 후 이름이 같고 좌표가 근접한 항목 제거
        val out = ArrayList<GeoResult>()
        for (r in sorted) {
            val n = stripAdminSuffix(r.name)
            val dup = out.any {
                stripAdminSuffix(it.name) == n &&
                        abs(it.latitude - r.latitude) < 0.25 &&
                        abs(it.longitude - r.longitude) < 0.25
            }
            if (dup) continue
            out.add(r)
            if (out.size >= 6) break
        }
        return out
    }

    /** 3: 정확 일치(접미사 무시), 2: 접두 일치, 1: 포함, 0: 무관 */
    private fun matchScore(name: String, query: String): Int {
        if (name == query) return 3
        val n = stripAdminSuffix(name)
        val qn = stripAdminSuffix(query)
        if (n == qn) return 3
        if (name.startsWith(query) || n.startsWith(qn)) return 2
        if (name.contains(query)) return 1
        return 0
    }

    /** 행정 단위 크기 가중치 (동점 정렬용) */
    private fun levelWeight(name: String): Int = when {
        name.endsWith("특별자치도") -> 8
        name.endsWith("특별자치시") || name.endsWith("광역시") || name.endsWith("특별시") -> 7
        name.endsWith("도") -> 8
        name.endsWith("시") -> 6
        name.endsWith("군") -> 5
        name.endsWith("구") -> 4
        name.endsWith("동") || name.endsWith("읍") -> 3
        name.endsWith("면") -> 2
        name.endsWith("리") || name.endsWith("가") -> 1
        else -> 4   // 접미사 없음(외국 도시·POI 등)은 중간
    }

    private fun stripAdminSuffix(s: String): String {
        for (suf in adminSuffixes) {
            if (s.length > suf.length && s.endsWith(suf)) return s.dropLast(suf.length)
        }
        return s
    }

    /** 결과 자체가 시 미만(구·동·읍·면·리) 등급인지 판별 */
    private fun isSubCity(name: String, type: String, osmValue: String): Boolean {
        if (type in setOf("city", "state", "county", "country")) return false
        if (isKorean(name)) {
            for (suf in listOf("특별자치시", "특별자치도", "광역시", "특별시")) {
                if (name.endsWith(suf)) return false
            }
            if (name.endsWith("시") || name.endsWith("군") || name.endsWith("도")) return false
            for (suf in listOf("구", "동", "읍", "면", "리", "가")) {
                if (name.endsWith(suf)) return true
            }
        }
        return type in setOf("district", "locality", "other") ||
                osmValue in setOf(
            "suburb", "neighbourhood", "quarter", "borough",
            "village", "hamlet", "city_district", "district"
        )
    }

    // ── Geocoder (구글 백엔드, GMS 기기) ──────────────────
    private suspend fun geocoderSearch(q: String): List<GeoResult> {
        val ctx = appContext ?: return emptyList()
        if (!Geocoder.isPresent()) return emptyList()
        val geocoder = Geocoder(ctx, Locale.KOREA)

        val addresses: List<Address> =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                suspendCancellableCoroutine { cont ->
                    geocoder.getFromLocationName(q, 6, object : Geocoder.GeocodeListener {
                        override fun onGeocode(result: MutableList<Address>) {
                            cont.resume(result)
                        }
                        override fun onError(errorMessage: String?) {
                            cont.resume(emptyList())
                        }
                    })
                }
            } else {
                // minSdk 31~32: 동기 API (deprecated 지만 동작)
                withContext(Dispatchers.IO) {
                    @Suppress("DEPRECATION")
                    runCatching { geocoder.getFromLocationName(q, 6) ?: emptyList<Address>() }
                        .getOrDefault(emptyList())
                }
            }
        return addresses.mapNotNull { addressToResult(it) }
    }

    private fun addressToResult(a: Address): GeoResult? {
        if (!a.hasLatitude() || !a.hasLongitude()) return null

        val feature = a.featureName?.trim()?.takeIf { it.isNotEmpty() }
        // 번지·건물번호 등 순수 주소 결과 제외 (지명·POI 만 통과)
        val name: String = when {
            feature != null &&
                    feature != a.subThoroughfare &&
                    feature != a.thoroughfare &&
                    !feature.all { it.isDigit() || it == '-' } -> feature
            a.thoroughfare == null ->
                a.subLocality ?: a.locality ?: return null
            else -> return null
        }

        // 행정 위계 사다리 (좁은 단위 → 넓은 단위)
        // 예: 역곡동 → [역곡동, 부천시, 경기도] / 남산타워 → [용산동2가, 서울특별시]
        val ladder = listOfNotNull(a.subLocality, a.locality, a.subAdminArea, a.adminArea)
            .filter { it.isNotBlank() }.distinct()
        val idx = ladder.indexOf(name)
        val admin1 = if (idx >= 0 && idx + 1 < ladder.size) ladder[idx + 1]
        else ladder.firstOrNull { it != name }

        val id = "$name|%.3f|%.3f".format(a.latitude, a.longitude).hashCode() and 0x7FFFFFFF
        return GeoResult(id, name, admin1, a.countryName, a.latitude, a.longitude)
    }

    // ── Photon ────────────────────────────────────────────
    private suspend fun searchPhoton(q: String, placesOnly: Boolean = true): List<GeoResult> =
        withContext(Dispatchers.IO) {
            val lang = if (isKorean(q)) "default" else "en"
            val url = "https://photon.komoot.io/api/" +
                    "?q=${URLEncoder.encode(q, "UTF-8")}&limit=10&lang=$lang"
            val req = Request.Builder().url(url)
                .header("User-Agent", "Starflower/1.0 (stargazing app)")
                .build()

            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) throw RuntimeException("http ${resp.code}")
                val body = resp.body?.string() ?: "{}"
                val parsed = moshi.adapter(PhotonResponse::class.java).fromJson(body)

                val out = ArrayList<GeoResult>()
                for (f in parsed?.features.orEmpty()) {
                    val p = f.properties ?: continue
                    val key = p.osmKey ?: ""
                    val type = p.type ?: ""
                    if (placesOnly) {
                        // 지명만 통과 (이스터에그 해석 시에는 POI 허용)
                        if (key != "place" && key != "boundary") continue
                        if (type == "street" || type == "house") continue
                    }
                    val coords = f.geometry?.coordinates ?: continue
                    if (coords.size < 2) continue
                    val name = p.name?.takeIf { it.isNotEmpty() } ?: continue

                    // 상위 지명: 시 미만 등급이면 시(city) 우선, 시·군 등급이면 도(state)
                    val admin1 = if (isSubCity(name, type, p.osmValue ?: "")) {
                        p.city ?: p.district ?: p.county ?: p.state
                    } else {
                        p.state ?: p.county
                    }

                    // osm_id 는 Int 범위를 넘을 수 있어 Long 으로 받고 축약
                    val id = p.osmId?.let { (it and 0x7FFFFFFF).toInt() }
                        ?: (name.hashCode() and 0x7FFFFFFF)
                    out.add(GeoResult(id, name, admin1, p.country, coords[1], coords[0]))
                }
                out
            }
        }

    // ── Open-Meteo ────────────────────────────────────────
    /** 접미사 없는 한글 검색어는 행정 접미사 변형을 함께 병렬 조회 */
    private suspend fun searchOpenMeteoExpanded(q: String): List<GeoResult> = coroutineScope {
        val queries = buildList {
            add(q)
            if (isKorean(q) && stripAdminSuffix(q) == q) {
                listOf("시", "군", "구", "동", "읍", "면", "리", "도").forEach { add(q + it) }
            }
        }
        queries.map { query ->
            async { runCatching { searchOpenMeteo(query) }.getOrDefault(emptyList()) }
        }.flatMap { it.await() }
    }

    private suspend fun searchOpenMeteo(q: String): List<GeoResult> =
        withContext(Dispatchers.IO) {
            val url = "https://geocoding-api.open-meteo.com/v1/search" +
                    "?name=${URLEncoder.encode(q, "UTF-8")}&count=6&language=ko&format=json"
            val req = Request.Builder().url(url).build()
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string() ?: "{}"
                val parsed = moshi.adapter(OpenMeteoGeoResponse::class.java).fromJson(body)
                parsed?.results?.map { item ->
                    // 상위 지명: 시 미만 등급이면 admin2(시·군) 우선, 아니면 admin1(도)
                    val admin1 = if (isSubCity(item.name, "", "")) {
                        item.admin2 ?: item.admin1
                    } else {
                        item.admin1
                    }
                    GeoResult(item.id, item.name, admin1, item.country,
                        item.latitude, item.longitude)
                } ?: emptyList()
            }
        }
}

// ── 응답 구조 ─────────────────────────────────────────────
private data class PhotonResponse(val features: List<PhotonFeature>?)
private data class PhotonFeature(
    val geometry: PhotonGeometry?,
    val properties: PhotonProps?,
)
private data class PhotonGeometry(val coordinates: List<Double>?)   // [lon, lat]
private data class PhotonProps(
    @Json(name = "osm_id") val osmId: Long?,
    val name: String?,
    val country: String?,
    val state: String?,
    val county: String?,
    val city: String?,
    val district: String?,
    @Json(name = "osm_key") val osmKey: String?,
    @Json(name = "osm_value") val osmValue: String?,
    val type: String?,
)

private data class OpenMeteoGeoResponse(val results: List<OpenMeteoGeoItem>?)
private data class OpenMeteoGeoItem(
    val id: Int,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val country: String?,
    val admin1: String?,
    val admin2: String?,
)