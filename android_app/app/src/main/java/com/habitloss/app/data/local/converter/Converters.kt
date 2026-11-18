package com.habitloss.app.data.local.converter

import androidx.room.TypeConverter
import com.habitloss.app.domain.model.RoutineDifficulty
import com.habitloss.app.domain.model.SugarTrafficLight
import java.time.LocalDate

/**
 * Conversores de tipos para la base de datos Room 100% offline.
 * Transforma LocalDate, Enums (SugarTrafficLight, RoutineDifficulty) y List<String>
 * a representaciones primitivas de SQLite (TEXT/VARCHAR).
 */
class Converters {

    // --- LocalDate Converters (ISO-8601 YYYY-MM-DD) ---

    @TypeConverter
    fun fromLocalDate(date: LocalDate?): String? {
        return date?.toString()
    }

    @TypeConverter
    fun toLocalDate(value: String?): LocalDate? {
        return value?.let {
            runCatching { LocalDate.parse(it) }.getOrNull()
        }
    }

    // --- SugarTrafficLight Enum Converters ---

    @TypeConverter
    fun fromSugarTrafficLight(trafficLight: SugarTrafficLight?): String? {
        return trafficLight?.name
    }

    @TypeConverter
    fun toSugarTrafficLight(value: String?): SugarTrafficLight? {
        return value?.let {
            runCatching { SugarTrafficLight.valueOf(it) }.getOrDefault(SugarTrafficLight.GREEN)
        }
    }

    // --- RoutineDifficulty Enum Converters ---

    @TypeConverter
    fun fromRoutineDifficulty(difficulty: RoutineDifficulty?): String? {
        return difficulty?.name
    }

    @TypeConverter
    fun toRoutineDifficulty(value: String?): RoutineDifficulty? {
        return value?.let {
            runCatching { RoutineDifficulty.valueOf(it) }.getOrDefault(RoutineDifficulty.GENTLE)
        }
    }

    // --- List<String> Converters (Delimited with ||| for zero overhead & crash-free parsing) ---

    @TypeConverter
    fun fromStringList(list: List<String>?): String? {
        if (list == null) return null
        return list.joinToString(separator = DELIMITER)
    }

    @TypeConverter
    fun toStringList(value: String?): List<String> {
        if (value.isNullOrBlank()) return emptyList()
        return value.split(DELIMITER).filter { it.isNotBlank() }
    }

    companion object {
        private const val DELIMITER = "|||"
    }
}
