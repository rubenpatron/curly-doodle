package com.habitos.cleanstep.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import java.time.LocalDate

@Entity(
    tableName = "sugar_logs",
    indices = [Index(value = ["date"], unique = true)]
)
data class SugarLogEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "date")
    val date: LocalDate,

    @ColumnInfo(name = "traffic_light")
    val trafficLight: SugarTrafficLight,

    @ColumnInfo(name = "notes")
    val notes: String? = null,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long = System.currentTimeMillis()
)
