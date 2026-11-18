package com.habitloss.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

/**
 * Entidad Room para el seguimiento diario de hidratación.
 * Cada vaso equivale a ~250 ml (Meta predeterminada: 8 vasos = 2 Litros).
 * Clave primaria: `date` (un registro consolidado por fecha).
 */
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
