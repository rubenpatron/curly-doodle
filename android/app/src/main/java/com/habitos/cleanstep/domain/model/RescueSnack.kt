package com.habitos.cleanstep.domain.model

/**
 * Categorías científicas de saciedad basadas en mecanismos fisiológicos y neuroquímicos.
 */
enum class SatietyMechanism(
    val categoryName: String,
    val badgeLabel: String,
    val primaryHormoneTarget: String,
    val physiologicalSummary: String,
    val colorHex: Long
) {
    PROTEIN_GHRELIN_BLOCKER(
        categoryName = "Proteína Pura",
        badgeLabel = "Grelina OFF • PYY ON",
        primaryHormoneTarget = "Grelina (suprimida) y PYY / GLP-1 (estimulados)",
        physiologicalSummary = "La proteína es el macronutriente con mayor efecto térmico y saciante. Al llegar al duodeno estimula el péptido YY y el GLP-1, apagando la producción de grelina en el fondo gástrico por 4 a 6 horas.",
        colorHex = 0xFF10B981 // Emerald Green
    ),
    GASTRIC_STRETCH_VOLUME(
        categoryName = "Volumen y Crujido Mecánico",
        badgeLabel = "Mecanorreceptores Gástricos",
        primaryHormoneTarget = "Vago aferente (distensión gástrica)",
        physiologicalSummary = "El 95% de agua y fibra soluble distienden las paredes estomacales activando los mecanorreceptores que comunican saciedad al hipotálamo. Además, la masticación crujiente (sonora) satisface la fase cefálica de recompensa dopaminérgica.",
        colorHex = 0xFF06B6D4 // Cyan
    ),
    CARBONATION_SENSORY_SWAP(
        categoryName = "Gas Carbónico y Acidez",
        badgeLabel = "Gas + Cero Azúcar",
        primaryHormoneTarget = "Distensión antral + estimulación salival",
        physiologicalSummary = "El ácido carbónico distiende rápidamente el antro gástrico y la acidez del limón activa las glándulas salivares, replicando la mordida sensorial y bucal de un refresco sin disparar insulina ni aportar calorías.",
        colorHex = 0xFF3B82F6 // Blue
    ),
    ILEAL_BRAKE_LIPID(
        categoryName = "Grasa Monoinsaturada",
        badgeLabel = "Freno Ileal • Retardo Gástrico",
        primaryHormoneTarget = "Colecistoquinina (CCK) y vaciado gástrico lento",
        physiologicalSummary = "Las grasas vegetales saludables activan el mecanismo del 'freno ileal' en el intestino delgado, enlenteciendo el vaciado gástrico. Esto evita hipoglucemias reactivas y estabiliza el estado de ánimo.",
        colorHex = 0xFFF59E0B // Amber
    ),
    VAGAL_THERMAL_SOOTHING(
        categoryName = "Calor y Distracción Sensorial",
        badgeLabel = "Estimulación Vagal Parasimpática",
        primaryHormoneTarget = "Nervio Vago (eje intestino-cerebro)",
        physiologicalSummary = "La temperatura caliente obliga al sorbo pausado, activando el tono parasimpático que reduce el cortisol y frena el impulso compulsivo de comer por aburrimiento o ansiedad.",
        colorHex = 0xFF8B5CF6 // Purple
    )
}

/**
 * Modelo de datos para las opciones de snack de rescate realistas, baratas y mexicanas.
 */
data class RescueSnack(
    val id: String,
    val name: String,
    val shortSubtitle: String,
    val emoji: String,
    val replacesJunkFood: String,
    val mechanism: SatietyMechanism,
    val whyItWorksScience: String,
    val preparationTime: String,
    val estimatedCostMxn: String,
    val caloriesApprox: String,
    val ingredients: List<String>,
    val preparationTip: String,
    val mexicanContextTip: String
)

/**
 * Catálogo canónico de snacks de rescate mexicanos (cero azúcar añadida, económicos y de alta saciedad).
 */
object MexicanRescueSnacksCatalog {
    val snacks = listOf(
        RescueSnack(
            id = "mineral_water_lemon",
            name = "Agua Mineral con Limón y Sal",
            shortSubtitle = "El clon del refresco sin azúcar ni químicos",
            emoji = "🍋🫧",
            replacesJunkFood = "Coca-Cola, refrescos azucarados o bebidas energéticas",
            mechanism = SatietyMechanism.CARBONATION_SENSORY_SWAP,
            whyItWorksScience = "El gas carbónico distiende el estómago de inmediato calmando la sensación de vacío. La combinación de ácido cítrico y cloruro de sodio (sal) repone microelectrolitos y engaña al cerebro que buscaba el golpe sensorial de un refresco frío.",
            preparationTime = "30 segundos",
            estimatedCostMxn = "$8 - $12 MXN",
            caloriesApprox = "~0 kcal",
            ingredients = listOf(
                "1 vaso grande o botella de agua mineral bien fría (Peñafiel, Tehuacán o Topo Chico)",
                "Jugo de 1 o 2 limones frescos",
                "1 pizca pequeña de sal de mesa",
                "Hielos abundantes"
            ),
            preparationTip = "Sírvelo en un vaso de vidrio con mucho hielo. El sonido del gas y el frío intenso potencian la saciedad psicológica inmediata.",
            mexicanContextTip = "Cualquier tiendita de la esquina o súper vende agua mineral por menos de $15 pesos. Es la mejor alternativa cuando tienes sed engañada por antojo de soda."
        ),
        RescueSnack(
            id = "cucumber_jicama_crunch",
            name = "Pepino o Jícama con Limón y Sal",
            shortSubtitle = "Crujido saciante: el asesino de las Sabritas",
            emoji = "🥒🌶️",
            replacesJunkFood = "Papas fritas, Doritos, Cheetos o botanas con grasa trans",
            mechanism = SatietyMechanism.GASTRIC_STRETCH_VOLUME,
            whyItWorksScience = "La masticación repetitiva y crujiente ('crunch acoustic feedback') activa receptores auditivos y vestibulares que le avisan al cerebro que estamos ingiriendo alimentos densos. Al ser 95% agua y fibra, genera distensión mecánica gástrica con casi cero impacto glucémico.",
            preparationTime = "2 minutos",
            estimatedCostMxn = "$5 - $10 MXN",
            caloriesApprox = "~25 - 35 kcal",
            ingredients = listOf(
                "1 pepino mediano rebanado en rodajas gruesas o 1 taza de jícama en tiras",
                "Jugo de 1 limón verde",
                "Pizca de sal",
                "Chile piquín o Tajín bajo en sodio (sin azúcar añadida)"
            ),
            preparationTip = "Corta las rodajas gruesas para forzar a que cada mordida sea sonora y tarde más tiempo. Masticar despacio duplica la saciedad.",
            mexicanContextTip = "El pepino y la jícama están disponibles todo el año en mercados sobre ruedas y tienditas a precios muy económicos en México."
        ),
        RescueSnack(
            id = "boiled_eggs_protein",
            name = "1 o 2 Huevos Cocidos",
            shortSubtitle = "El interruptor biológico del hambre real",
            emoji = "🥚🧂",
            replacesJunkFood = "Galletas, pan dulce, barritas de cereal o garnachas",
            mechanism = SatietyMechanism.PROTEIN_GHRELIN_BLOCKER,
            whyItWorksScience = "Contiene 12-14 gramos de proteína con el valor biológico más alto de la naturaleza (albúmina y aminoácidos esenciales). Dispara la colecistoquinina (CCK) y suprime la grelina gástrica. Regla de oro: Si no se te antoja un huevo cocido, no tienes hambre estomacal, tienes aburrimiento.",
            preparationTime = "8-10 min (o 0 seg si los tienes ya listos en refri)",
            estimatedCostMxn = "$6 - $12 MXN",
            caloriesApprox = "~140 kcal (2 huevos)",
            ingredients = listOf(
                "1 o 2 huevos de gallina cocidos (hervidos durante 9 minutos)",
                "Pizca de sal y pimienta negra o gotas de salsa Valentina/Tamannera (cero azúcar)"
            ),
            preparationTip = "Cocina 4 huevos duros el domingo por la noche y guárdalos con cáscara en el refrigerador. En un momento de crisis, solo pelas y comes en 1 minuto.",
            mexicanContextTip = "El huevo es el pilar de proteína más accesible y económico de la canasta básica mexicana."
        ),
        RescueSnack(
            id = "roasted_peanuts_fats",
            name = "Puñado de Cacahuates Tostados",
            shortSubtitle = "Grasa monoinsaturada que frena el vaciado estomacal",
            emoji = "🥜⏳",
            replacesJunkFood = "Chocolates con azúcar, galletas rellenas o pastelitos",
            mechanism = SatietyMechanism.ILEAL_BRAKE_LIPID,
            whyItWorksScience = "Las grasas monoinsaturadas y la fibra del cacahuate activan el 'freno ileal', disminuyendo el peristaltismo y reteniendo el bolo alimenticio en el estómago por más tiempo. Requieren masticación firme, reduciendo la ansiedad oral.",
            preparationTime = "0 min (listo para servir)",
            estimatedCostMxn = "$5 - $8 MXN",
            caloriesApprox = "~160 kcal (porción controlada de 25-30g)",
            ingredients = listOf(
                "1 puñado pequeño cerrado (aprox. 25-30 gramos) de cacahuates tostados al comal",
                "Sin sal añadida o con sal moderada, estrictamente SIN azúcar ni garapiñado"
            ),
            preparationTip = "Mide solo un puño cerrado y guarda la bolsa lejos. Come uno por uno saboreando la textura tostada durante al menos 5 minutos.",
            mexicanContextTip = "Cómpralos a granel en el mercado o tiendita de barrio. Evita las versiones 'japonesas' o 'enchiladas comerciales' que tienen harina refinada y azúcar."
        ),
        RescueSnack(
            id = "hot_herbal_tea_or_black_coffee",
            name = "Té Caliente o Café Negro sin Azúcar",
            shortSubtitle = "Distracción térmica que apaga el nerviosismo",
            emoji = "🫖☕",
            replacesJunkFood = "Frapuccinos azucarados, atole o meriendas nocturnas de galletas",
            mechanism = SatietyMechanism.VAGAL_THERMAL_SOOTHING,
            whyItWorksScience = "El calor del líquido obliga a ingerirlo mediante sorbos pausados. La temperatura tibia relaja la motilidad gástrica y estimula el nervio vago parasimpático, disipando la tensión nerviosa que suele confundirse con hambre.",
            preparationTime = "3 minutos",
            estimatedCostMxn = "$3 - $5 MXN",
            caloriesApprox = "~0 - 5 kcal",
            ingredients = listOf(
                "1 taza de agua hirviendo",
                "1 bolsita de té de manzanilla, menta, tila o café soluble/de cafetera",
                "Opcional: 1 raja de canela para aportar dulzor aromático natural sin azúcar"
            ),
            preparationTip = "Agrega una raja de canela al hervir el agua. La canela brinda una sensación olfativa dulce sin agregar una sola caloría ni alterar la insulina.",
            mexicanContextTip = "Manzanilla, menta o hierbabuena son hierbas tradicionales mexicanas presentes en casi cualquier hogar o disponibles por menos de $15 la caja."
        )
    )
}
