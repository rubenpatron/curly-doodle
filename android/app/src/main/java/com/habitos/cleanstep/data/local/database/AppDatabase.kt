package com.habitos.cleanstep.data.local.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.habitos.cleanstep.data.local.converter.Converters
import com.habitos.cleanstep.data.local.dao.HabitStreakDao
import com.habitos.cleanstep.data.local.dao.NightRoutineDao
import com.habitos.cleanstep.data.local.dao.SugarLogDao
import com.habitos.cleanstep.data.local.dao.WaterIntakeDao
import com.habitos.cleanstep.data.local.entity.HabitStreakEntity
import com.habitos.cleanstep.data.local.entity.NightRoutineEntity
import com.habitos.cleanstep.data.local.entity.SugarLogEntity
import com.habitos.cleanstep.data.local.entity.WaterIntakeEntity

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

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "cleanstep_habits.db"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
