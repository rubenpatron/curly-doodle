package com.habitos.cleanstep.data.local.converter

import androidx.room.TypeConverter
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import java.time.LocalDate

class Converters {

    @TypeConverter
    fun fromLocalDate(date: LocalDate?): String? = date?.toString()

    @TypeConverter
    fun toLocalDate(value: String?): LocalDate? = value?.let {
        runCatching { LocalDate.parse(it) }.getOrNull()
    }

    @TypeConverter
    fun fromSugarTrafficLight(value: SugarTrafficLight?): String? = value?.name

    @TypeConverter
    fun toSugarTrafficLight(value: String?): SugarTrafficLight? = value?.let {
        runCatching { SugarTrafficLight.valueOf(it) }.getOrDefault(SugarTrafficLight.NONE)
    }

    @TypeConverter
    fun fromStringList(list: List<String>?): String? = list?.joinToString(separator = "|||")

    @TypeConverter
    fun toStringList(value: String?): List<String> {
        if (value.isNullOrBlank()) return emptyList()
        return value.split("|||").filter { it.isNotBlank() }
    }
}
