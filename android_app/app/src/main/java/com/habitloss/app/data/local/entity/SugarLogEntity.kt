package com.habitloss.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.habitloss.app.domain.model.SugarTrafficLight
import java.time.LocalDate

/**
 * Entidad Room para el semáforo diario de azúcar:
 * - GREEN: "0 azúcares hoy" (Limpio: sin refrescos, galletas ni papas procesadas)
 * - AMBER: "Bebida dulce" (Refresco con azúcar, jugo industrial o café endulzado)
 * - RED: "Snack procesado" (Galletas, papas/Sabritas, frituras o bollería)
 *
 * Se indexa de forma única por fecha para permitir actualizaciones reactivas directas
 * y consulta rápida de semanas/meses.
 */
@Entity(
    tableName = "sugar_logs",
    indices = [
        Index(value = ["date"], unique = true)
    ]
)
data class SugarLogEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "date")
    val date: LocalDate,

    @ColumnInfo(name = "sugar_traffic_light")
    val sugarTrafficLight: SugarTrafficLight,

    @ColumnInfo(name = "notes")
    val notes: String? = null,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long = System.currentTimeMillis()
)
