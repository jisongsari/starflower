package com.songsari.starflower.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/** 2x2 위젯 리시버 */
class SmallWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SmallGlanceWidget()
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetScheduler.schedulePeriodic(context)
    }
}

/** 4x2 위젯 리시버 */
class MediumWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MediumGlanceWidget()
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetScheduler.schedulePeriodic(context)
    }
}

/** 위젯 갱신 스케줄링 */
object WidgetScheduler {
    const val WORK_NAME = "starflower_widget_update"

    fun schedulePeriodic(context: Context) {
        val req = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(1, TimeUnit.HOURS).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, req,
        )
    }

    fun updateNow(context: Context) {
        val req = OneTimeWorkRequestBuilder<WidgetUpdateWorker>().build()
        WorkManager.getInstance(context).enqueue(req)
    }
}

/** 위젯 데이터 재계산 + 다시 그리기 (두 위젯 모두 갱신) */
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        SmallGlanceWidget().updateAll(applicationContext)
        MediumGlanceWidget().updateAll(applicationContext)
        return Result.success()
    }
}