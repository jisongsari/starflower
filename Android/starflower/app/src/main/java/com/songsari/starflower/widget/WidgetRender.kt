package com.songsari.starflower.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import com.songsari.starflower.R
import androidx.core.content.ContextCompat
import com.songsari.starflower.calc.ScoreCalculator
import com.songsari.starflower.model.SkyCondition
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * 위젯 콘텐츠 전체를 하나의 비트맵으로 렌더(KWGT 방식).
 * Glance 레이아웃 제약을 우회해 iOS 와 거의 동일한 타이포/정렬을 낸다.
 * 배경·달은 기존 비트맵 재사용, 모든 텍스트는 Pretendard.
 */
object WidgetRender {

    private fun hhmm(d: Date?): String =
        if (d == null) "—" else SimpleDateFormat("HH:mm", Locale.US).format(d)

    private fun w(a: Float) = Color.argb((a * 255).roundToInt(), 255, 255, 255)

    private fun tp(context: Context, weight: WidgetFonts.W, spSize: Float, d: Float, argb: Int): TextPaint =
        TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = WidgetFonts.get(context, weight)
            textSize = spSize * d
            color = argb
            isSubpixelText = true
        }

    private fun lineH(p: Paint): Float {
        val fm = p.fontMetrics
        return fm.descent - fm.ascent
    }

    /** top 기준으로 한 줄 그리기 (baseline 자동 변환) */
    private fun drawTop(canvas: Canvas, text: String, x: Float, top: Float, p: Paint) {
        val fm = p.fontMetrics
        canvas.drawText(text, x, top - fm.ascent, p)
    }

    private fun weatherRes(c: SkyCondition): Int = when (c) {
        SkyCondition.CLEAR -> R.drawable.ic_w_clear
        SkyCondition.PARTLY -> R.drawable.ic_w_partly
        SkyCondition.CLOUDY, SkyCondition.OVERCAST, SkyCondition.FOG -> R.drawable.ic_w_cloud
        SkyCondition.RAIN -> R.drawable.ic_w_rain
        SkyCondition.SNOW -> R.drawable.ic_w_snow
    }

    private fun drawWeatherIcon(context: Context, canvas: Canvas, c: SkyCondition, left: Float, top: Float, sizePx: Float, argb: Int) {
        val dr = ContextCompat.getDrawable(context, weatherRes(c))?.mutate() ?: return
        dr.setTint(argb)
        dr.setBounds(left.roundToInt(), top.roundToInt(), (left + sizePx).roundToInt(), (top + sizePx).roundToInt())
        dr.draw(canvas)
    }

    // ── 2x2 ───────────────────────────────────────────────
    fun renderSmall(context: Context, e: WidgetEntry, wPx: Int, hPx: Int, d: Float): Bitmap {
        val bmp = Bitmap.createBitmap(wPx.coerceAtLeast(1), hPx.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        canvas.drawBitmap(renderSkyBitmap(e.condition, e.daypart, wPx, hPx), 0f, 0f, null)

        val pad = 16 * d
        val left = pad
        val contentW = wPx - pad * 2

        val pLoc = tp(context, WidgetFonts.W.SEMIBOLD, 15f, d, w(0.8f))
        val pScore = tp(context, WidgetFonts.W.THIN, 66f, d, w(1f)).apply { letterSpacing = -0.04f }
        val pPct = tp(context, WidgetFonts.W.REGULAR, 26f, d, w(0.85f))
        val pVerd = tp(context, WidgetFonts.W.MEDIUM, 14f, d, w(0.85f))
        val pBot = tp(context, WidgetFonts.W.MEDIUM, 12f, d, w(0.55f))

        val iconSz = 16 * d
        val verdLeft = left + iconSz + 5 * d
        val verdWidth = (contentW - iconSz - 5 * d).toInt().coerceAtLeast(1)
        val verdLayout = staticLayout(ScoreCalculator.verdict(e.score), pVerd, verdWidth, 2)

        val locH = lineH(pLoc)
        val scoreH = lineH(pScore)
        val verdH = max(iconSz, verdLayout.height.toFloat())
        val botH = lineH(pBot)
        val g1 = 8 * d; val g2 = 5 * d; val g3 = 8 * d
        val total = locH + g1 + scoreH + g2 + verdH + g3 + botH
        var y = (hPx - total) / 2f

        drawTop(canvas, e.locationName, left, y, pLoc); y += locH + g1

        // 점수 + %
        drawTop(canvas, "${e.score}", left, y, pScore)
        val scoreW = pScore.measureText("${e.score}")
        drawTop(canvas, "%", left + scoreW + 2 * d, y + scoreH * 0.16f, pPct)
        y += scoreH + g2

        // 아이콘 + 한줄평(최대 2줄)
        drawWeatherIcon(context, canvas, e.condition, left, y + (verdH - iconSz) / 2f, iconSz, w(0.8f))
        canvas.save()
        canvas.translate(verdLeft, y + (verdH - verdLayout.height) / 2f)
        verdLayout.draw(canvas)
        canvas.restore()
        y += verdH + g3

        drawTop(canvas, "기온 ${e.temperature.roundToInt()}° · ${hhmm(Date())}", left, y, pBot)
        return bmp
    }

    // ── 4x2 ───────────────────────────────────────────────
    fun renderMedium(context: Context, e: WidgetEntry, wPx: Int, hPx: Int, d: Float): Bitmap {
        val bmp = Bitmap.createBitmap(wPx.coerceAtLeast(1), hPx.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        canvas.drawBitmap(renderSkyBitmap(e.condition, e.daypart, wPx, hPx), 0f, 0f, null)

        val pad = 16 * d
        val leftW = wPx * 0.4f
        val gap = 14 * d
        val rightX = pad + (leftW - pad) + gap
        val rightW = wPx - rightX - pad

        drawLeft(context, canvas, e, pad, leftW - pad, hPx, d)
        drawRight(context, canvas, e, rightX, rightW, hPx, d)
        return bmp
    }

    private fun drawLeft(context: Context, canvas: Canvas, e: WidgetEntry, left: Float, contentW: Float, hPx: Int, d: Float) {
        val pLoc = tp(context, WidgetFonts.W.SEMIBOLD, 14f, d, w(0.8f))
        val pScore = tp(context, WidgetFonts.W.THIN, 58f, d, w(1f)).apply { letterSpacing = -0.04f }
        val pPct = tp(context, WidgetFonts.W.REGULAR, 23f, d, w(0.85f))
        val pVerd = tp(context, WidgetFonts.W.MEDIUM, 13f, d, w(0.85f))
        val pBot = tp(context, WidgetFonts.W.MEDIUM, 12f, d, w(0.55f))

        val iconSz = 14 * d
        val verdLeft = left + iconSz + 5 * d
        val verdWidth = (contentW - iconSz - 5 * d).toInt().coerceAtLeast(1)
        val verdLayout = staticLayout(ScoreCalculator.verdict(e.score), pVerd, verdWidth, 2)

        val locH = lineH(pLoc); val scoreH = lineH(pScore)
        val verdH = max(iconSz, verdLayout.height.toFloat()); val botH = lineH(pBot)
        val g1 = 6 * d; val g2 = 5 * d; val g3 = 6 * d
        val total = locH + g1 + scoreH + g2 + verdH + g3 + botH
        var y = (hPx - total) / 2f

        drawTop(canvas, e.locationName, left, y, pLoc); y += locH + g1
        drawTop(canvas, "${e.score}", left, y, pScore)
        val sw = pScore.measureText("${e.score}")
        drawTop(canvas, "%", left + sw + 2 * d, y + scoreH * 0.16f, pPct)
        y += scoreH + g2
        drawWeatherIcon(context, canvas, e.condition, left, y + (verdH - iconSz) / 2f, iconSz, w(0.8f))
        canvas.save()
        canvas.translate(verdLeft, y + (verdH - verdLayout.height) / 2f)
        verdLayout.draw(canvas)
        canvas.restore()
        y += verdH + g3
        drawTop(canvas, hhmm(Date()), left, y, pBot)
    }

    private fun drawRight(context: Context, canvas: Canvas, e: WidgetEntry, x: Float, width: Float, hPx: Int, d: Float) {
        val moonSz = 52 * d
        val pMoonPct = tp(context, WidgetFonts.W.REGULAR, 21f, d, w(1f))
        val pMoonName = tp(context, WidgetFonts.W.REGULAR, 12f, d, w(0.62f))
        val pRiseLbl = tp(context, WidgetFonts.W.REGULAR, 11f, d, w(0.55f))
        val pRiseVal = tp(context, WidgetFonts.W.MEDIUM, 13f, d, w(1f))
        val pMetLbl = tp(context, WidgetFonts.W.REGULAR, 11f, d, w(0.58f))
        val pMetVal = tp(context, WidgetFonts.W.MEDIUM, 14f, d, w(1f))

        // 블록 높이 계산 (수직 중앙)
        val moonRowH = moonSz
        val metLblH = lineH(pMetLbl); val metValH = lineH(pMetVal)
        val gridRowH = metLblH + 3 * d + metValH
        val gMoon = 12 * d; val gGrid = 11 * d
        val total = moonRowH + gMoon + gridRowH + gGrid + gridRowH
        var y = (hPx - total) / 2f

        // 달 행
        val moonBmp = renderMoonBitmap(e.moonIllum, e.moonPhase < 0.5, moonSz.roundToInt())
        canvas.drawBitmap(moonBmp, x, y + (moonRowH - moonSz) / 2f, null)
        // 달 오른쪽: 조도 % + 위상명
        val infoX = x + moonSz + 4 * d
        val pctH = lineH(pMoonPct); val nameH = lineH(pMoonName)
        val infoStack = pctH + 1 * d + nameH
        var iy = y + (moonRowH - infoStack) / 2f
        drawTop(canvas, "${(e.moonIllum * 100).roundToInt()}%", infoX, iy, pMoonPct); iy += pctH + 1 * d
        drawTop(canvas, e.moonName, infoX, iy, pMoonName)

        // 월출/월몰: 섹터 전체는 우측 정렬, 내부는 좌측 정렬(라벨 왼쪽 일렬)
        val rightEdge = x + width - 6 * d       // #4 오른쪽 여백 확보
        pRiseLbl.textAlign = Paint.Align.LEFT
        pRiseVal.textAlign = Paint.Align.LEFT
        val lblW = pRiseLbl.measureText("월출 ")
        val valW = max(pRiseVal.measureText(hhmm(e.moonrise)), pRiseVal.measureText(hhmm(e.moonset)))
        val blockLeft = rightEdge - (lblW + valW)
        val lineGap = 5 * d
        val riseH = lineH(pRiseVal)
        val lblDy = (riseH - lineH(pRiseLbl)) / 2f   // 작은 라벨을 값 줄 높이에 맞춰 중앙
        val stackH = riseH * 2 + lineGap
        var ry = y + (moonRowH - stackH) / 2f

        drawTop(canvas, "월출 ", blockLeft, ry + lblDy, pRiseLbl)
        drawTop(canvas, hhmm(e.moonrise), blockLeft + lblW, ry, pRiseVal)
        ry += riseH + lineGap
        drawTop(canvas, "월몰 ", blockLeft, ry + lblDy, pRiseLbl)
        drawTop(canvas, hhmm(e.moonset), blockLeft + lblW, ry, pRiseVal)

        y += moonRowH + gMoon

        // 그리드 1
        drawGridRow(context, canvas, x, width, y, d, pMetLbl, pMetVal, listOf(
            "일몰" to hhmm(e.sunset), "일출" to hhmm(e.sunrise),
            "운량" to "${e.nightCloud.roundToInt()}%", "습도" to "${e.nightHumidity.roundToInt()}%",
        ))
        y += gridRowH + gGrid
        drawGridRow(context, canvas, x, width, y, d, pMetLbl, pMetVal, listOf(
            "풍속" to "${String.format(Locale.US, "%.1f", e.nightWind)}㎧",
            "기압" to "${e.pressure.roundToInt()}h",
            "미세먼지" to "${e.nightPm25.roundToInt()}㎍",
            "기온" to "${e.temperature.roundToInt()}°",
        ))
    }

    private fun drawGridRow(
        context: Context, canvas: Canvas, x: Float, width: Float, top: Float, d: Float,
        pLbl: TextPaint, pVal: TextPaint, cells: List<Pair<String, String>>,
    ) {
        val colW = width / cells.size
        val lblH = lineH(pLbl)
        val savedL = pLbl.textAlign; val savedV = pVal.textAlign
        pLbl.textAlign = Paint.Align.CENTER; pVal.textAlign = Paint.Align.CENTER
        cells.forEachIndexed { i, (label, value) ->
            val cx = x + colW * i + colW / 2f
            val fmL = pLbl.fontMetrics
            canvas.drawText(label, cx, top - fmL.ascent, pLbl)
            val fmV = pVal.fontMetrics
            canvas.drawText(value, cx, top + lblH + 3 * d - fmV.ascent, pVal)
        }
        pLbl.textAlign = savedL; pVal.textAlign = savedV
    }

    private fun staticLayout(text: String, paint: TextPaint, width: Int, maxLines: Int): StaticLayout =
        StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setMaxLines(maxLines)
            .setEllipsize(TextUtils.TruncateAt.END)
            .setIncludePad(false)
            .setLineSpacing(0f, 1f)
            .build()
}