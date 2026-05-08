/**
 * @file speed_math.h
 * @brief SINGLE SOURCE OF TRUTH for all speed ↔ internal conversions.
 *
 * All display speed (kmh_display, mph_display) ↔ internal value (0-100)
 * conversions MUST use these functions. No inline formulas anywhere else.
 *
 * Math (matches STM32 F4's Num formula):
 *   internal = round(kmh_display / 3.4)
 *            = (kmh_display * 10 + 17) / 34     (integer math)
 *
 *   kmh_display = round(internal * 3.4)
 *               = (internal * 34 + 5) / 10
 *
 *   mph_display = round(kmh_display * 0.621371)
 *               = min(round(kmh_display * 0.621371), 211)
 */
#pragma once
#include <stdint.h>

/**
 * Convert km/h display value (0-340) to internal 0-100 value.
 * Internal value drives: fan PWM duty, audio RPM, protocol Num.
 */
static inline uint8_t speed_to_internal(int16_t kmh_display)
{
    if (kmh_display <= 0) return 0;
    if (kmh_display >= 340) return 100;
    uint8_t internal = (uint8_t)(((int32_t)kmh_display * 10 + 17) / 34);
    if (internal > 100) internal = 100;
    return internal;
}

/**
 * Convert internal value (0-100) to km/h display value (0-340).
 */
static inline int16_t internal_to_kmh(uint8_t internal)
{
    if (internal == 0) return 0;
    if (internal >= 100) return 340;
    return (int16_t)(((int32_t)internal * 34 + 5) / 10);
}

/**
 * Convert km/h display value to mph display value (0-211).
 */
static inline int16_t kmh_to_mph(int16_t kmh_display)
{
    if (kmh_display <= 0) return 0;
    /* mph = kmh * 0.621371 */
    int16_t mph = (int16_t)(kmh_display * 0.621371f + 0.5f);
    if (mph > 211) mph = 211;
    return mph;
}

/**
 * Convert mph display value back to km/h display value.
 */
static inline int16_t mph_to_kmh(int16_t mph_display)
{
    if (mph_display <= 0) return 0;
    /* kmh = mph / 0.621371 */
    int16_t kmh = (int16_t)(mph_display / 0.621371f + 0.5f);
    if (kmh > 340) kmh = 340;
    return kmh;
}
