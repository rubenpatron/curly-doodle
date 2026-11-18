package com.habitloss.app.core.util

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

object DateUtils {
    private val ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE
    private val SPANISH_DISPLAY_FORMATTER = DateTimeFormatter.ofPattern("EEEE d 'de' MMMM", Locale("es", "MX"))
    private val SHORT_DAY_FORMATTER = DateTimeFormatter.ofPattern("EEE", Locale("es", "MX"))

    fun toIsoString(date: LocalDate): String = date.format(ISO_FORMATTER)

    fun fromIsoString(value: String): LocalDate = LocalDate.parse(value, ISO_FORMATTER)

    fun toSpanishDisplay(date: LocalDate): String =
        date.format(SPANISH_DISPLAY_FORMATTER).replaceFirstChar { it.uppercase() }

    fun toShortDayName(date: LocalDate): String =
        date.format(SHORT_DAY_FORMATTER).replaceFirstChar { it.uppercase() }
}
