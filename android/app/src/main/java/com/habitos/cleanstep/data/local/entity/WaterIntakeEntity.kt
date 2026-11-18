package com.habitos.cleanstep.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(tableName = "water_intake")
data class WaterIntakeEntity(
    @PrimaryKey
    @ColumnInfo(name = "date")
    val date: LocalDate,

    @ColumnInfo(name = "glasses_count")
    val glassesCount: Int = 0,

    @ColumnInfo(name = "target_glasses")
    val targetGlasses: Int = 8,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long = System.currentTimeMillis()
)
