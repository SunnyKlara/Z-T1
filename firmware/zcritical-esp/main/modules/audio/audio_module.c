/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | modules/audio/
 *
 * 职责: 音频模块骨架
 * ═══════════════════════════════════════════════════════════════ */

#include "audio_module.h"
#include "core/state/app_state.h"
#include "esp_log.h"

static const char *TAG = "AUDIO";

void audio_module_init(void) {
    ESP_LOGI(TAG, "Audio module initialized");
}

void audio_module_set_volume(uint8_t vol) {
    if (vol > 100) vol = 100;
    /* TODO: hal_audio_set_volume(vol); */
    APP_STATE_LOCK();
    g_app_state.audio.volume = vol;
    APP_STATE_UNLOCK();
}

void audio_module_engine(uint8_t on) {
    /* TODO: hal_audio 引擎声播放 */
    APP_STATE_LOCK();
    g_app_state.audio.engine_on = on;
    APP_STATE_UNLOCK();
}
