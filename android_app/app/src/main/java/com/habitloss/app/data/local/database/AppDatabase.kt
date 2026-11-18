package com.habitloss.app.data.local.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.sqlite.db.SupportSQLiteDatabase
import com.habitloss.app.data.local.converter.Converters
import com.habitloss.app.data.local.dao.HabitStreakDao
import com.habitloss.app.data.local.dao.NightRoutineDao
import com.habitloss.app.data.local.dao.SugarLogDao
import com.habitloss.app.data.local.dao.WaterIntakeDao
import com.habitloss.app.data.local.entity.HabitStreakEntity
import com.habitloss.app.data.local.entity.NightRoutineEntity
import com.habitloss.app.data.local.entity.SugarLogEntity
import com.habitloss.app.data.local.entity.WaterIntakeEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDate

/**
 * Base de datos Room 100% offline para la aplicación HabitLoss / Cero Chatarra.
 * Esquema versión 1 con soporte reactivo integral mediante Flows.
 */
@Database(
    entities = [
        HabitStreakEntity::class,
        SugarLogEntity::class,
        WaterIntakeEntity::class,
        NightRoutineEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {

    abstract fun habitStreakDao(): HabitStreakDao
    abstract fun sugarLogDao(): SugarLogDao
    abstract fun waterIntakeDao(): WaterIntakeDao
    abstract fun nightRoutineDao(): NightRoutineDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        private const val DATABASE_NAME = "habit_loss_offline.db"

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    DATABASE_NAME
                )
                    .fallbackToDestructiveMigration()
                    .addCallback(PrepopulateCallback())
                    .build()
                INSTANCE = instance
                instance
            }
        }

        private class PrepopulateCallback : RoomDatabase.Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        val today = LocalDate.now()

                        // Racha inicial limpia
                        database.habitStreakDao().insertOrUpdate(
                            HabitStreakEntity(
                                id = 1L,
                                currentStreak = 0,
                                bestStreak = 0,
                                lastCleanDate = null,
                                startDate = today,
                                lastUpdatedTimestamp = System.currentTimeMillis()
                            )
                        )

                        // Meta inicial de agua (8 vasos = 2L)
                        database.waterIntakeDao().insertOrUpdate(
                            WaterIntakeEntity(
                                date = today,
                                glassesCount = 0,
                                targetGlasses = 8,
                                timestamp = System.currentTimeMillis()
                            )
                        )
                    }
                }
            }
        }
    }
}
