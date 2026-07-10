package com.songsari.starflower.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Box
import androidx.glance.layout.ContentScale
import androidx.glance.layout.fillMaxSize
import com.songsari.starflower.MainActivity
import kotlin.math.roundToInt

private const val WIDGET_CORNER_DP = 28   // #10 곡률 확대

@Composable
private fun FullBitmapWidget(bmp: android.graphics.Bitmap) {
    val ctx = LocalContext.current
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .cornerRadius(WIDGET_CORNER_DP.dp)
            .clickable(
                actionStartActivity(
                    Intent(ctx, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            )
    ) {
        Image(
            provider = ImageProvider(bmp),
            contentDescription = "오늘 밤 관측 지수",
            contentScale = ContentScale.FillBounds,
            modifier = GlanceModifier.fillMaxSize(),
        )
    }
}

/** 2x2 위젯 */
class SmallGlanceWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entry = WidgetRepository.load(context)
        provideContent {
            val size = LocalSize.current
            val ctx = LocalContext.current
            val d = ctx.resources.displayMetrics.density
            val wPx = (size.width.value * d).roundToInt().coerceAtLeast(1)
            val hPx = (size.height.value * d).roundToInt().coerceAtLeast(1)
            FullBitmapWidget(WidgetRender.renderSmall(ctx, entry, wPx, hPx, d))
        }
    }

}

/** 4x2 위젯 */
class MediumGlanceWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entry = WidgetRepository.load(context)
        provideContent {
            val size = LocalSize.current
            val ctx = LocalContext.current
            val d = ctx.resources.displayMetrics.density
            val wPx = (size.width.value * d).roundToInt().coerceAtLeast(1)
            val hPx = (size.height.value * d).roundToInt().coerceAtLeast(1)
            FullBitmapWidget(WidgetRender.renderMedium(ctx, entry, wPx, hPx, d))
        }
    }

}