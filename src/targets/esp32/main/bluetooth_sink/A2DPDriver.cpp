#include "A2DPDriver.h"
#include <cstring>

using namespace euph;

/* device name */
static char DEVICE_NAME[32];

static A2DPDriver* currentPtr = NULL;

/* event for stack up */
enum {
  BT_APP_EVT_STACK_UP = 0,
};

/******************************** / 
 * STATIC FUNCTION DECLARATIONS
 *******************************/

/* GAP callback function */
static void bt_app_gap_cb(esp_bt_gap_cb_event_t event,
                          esp_bt_gap_cb_param_t* param);
/* handler for bluetooth stack enabled events */
static void bt_av_hdl_stack_evt(uint16_t event, void* p_param);

A2DPDriver::A2DPDriver() {
  currentPtr = this;
}

A2DPDriver::~A2DPDriver() {
  currentPtr = NULL;
}

void A2DPDriver::disconnect() {
  bt_disconnect();
}

void A2DPDriver::initialize(const std::string& name) {
  if (name.length() > sizeof(DEVICE_NAME)) {
    EUPH_LOG(error, TAG, "Bluetooth device name too long");
    return;
  } else {
    memcpy(DEVICE_NAME, name.c_str(), name.length());
  }
  // Release BLE memory, as we only use classci
  ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_BLE));

  esp_bt_controller_config_t cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
  esp_err_t err;

  // Init controller
  if ((err = esp_bt_controller_init(&cfg)) != ESP_OK) {
    EUPH_LOG(error, TAG, "initialize controller failed: %s\n",
             esp_err_to_name(err));
    return;
  }

  // Enable controller
  if ((err = esp_bt_controller_enable(ESP_BT_MODE_CLASSIC_BT)) != ESP_OK) {
    EUPH_LOG(error, TAG, "enable controller failed: %s\n",
             esp_err_to_name(err));
    return;
  }

  // init bluedroid
  if ((err = esp_bluedroid_init()) != ESP_OK) {
    EUPH_LOG(error, TAG, "bluedroid init failed: %s\n", esp_err_to_name(err));
    return;
  }

  // enable bluedroid
  if ((err = esp_bluedroid_enable()) != ESP_OK) {
    EUPH_LOG(error, TAG, "bluedroid enable failed: %s\n", esp_err_to_name(err));
    return;
  }
  /* set default parameters for Legacy Pairing (use fixed pin code 1234) */
  esp_bt_pin_type_t pin_type = ESP_BT_PIN_TYPE_FIXED;
  esp_bt_pin_code_t pin_code;
  pin_code[0] = '1';
  pin_code[1] = '2';
  pin_code[2] = '3';
  pin_code[3] = '4';
  esp_bt_gap_set_pin(pin_type, 4, pin_code);

  bt_app_task_init_queue();

  /* bluetooth device name, connection mode and profile set up */
  bt_app_work_dispatch(bt_av_hdl_stack_evt, BT_APP_EVT_STACK_UP, NULL, 0, NULL);
}

/*******************************
 * STATIC FUNCTION DEFINITIONS
 ******************************/

static void bt_app_gap_cb(esp_bt_gap_cb_event_t event,
                          esp_bt_gap_cb_param_t* param) {
  uint8_t* bda = NULL;

  switch (event) {
    /* when authentication completed, this event comes */
    case ESP_BT_GAP_AUTH_CMPL_EVT: {
      if (param->auth_cmpl.stat == ESP_BT_STATUS_SUCCESS) {
        ESP_LOGI(BT_AV_TAG, "authentication success: %s",
                 param->auth_cmpl.device_name);
        esp_log_buffer_hex(BT_AV_TAG, param->auth_cmpl.bda, ESP_BD_ADDR_LEN);
      } else {
        ESP_LOGE(BT_AV_TAG, "authentication failed, status: %d",
                 param->auth_cmpl.stat);
      }
      break;
    }

#if (CONFIG_BT_SSP_ENABLED == true)
    /* when Security Simple Pairing user confirmation requested, this event comes */
    case ESP_BT_GAP_CFM_REQ_EVT:
      ESP_LOGI(
          BT_AV_TAG,
          "ESP_BT_GAP_CFM_REQ_EVT Please compare the numeric value: %" PRIu32,
          param->cfm_req.num_val);
      esp_bt_gap_ssp_confirm_reply(param->cfm_req.bda, true);
      break;
    /* when Security Simple Pairing passkey notified, this event comes */
    case ESP_BT_GAP_KEY_NOTIF_EVT:
      ESP_LOGI(BT_AV_TAG, "ESP_BT_GAP_KEY_NOTIF_EVT passkey: %" PRIu32,
               param->key_notif.passkey);
      break;
    /* when Security Simple Pairing passkey requested, this event comes */
    case ESP_BT_GAP_KEY_REQ_EVT:
      ESP_LOGI(BT_AV_TAG, "ESP_BT_GAP_KEY_REQ_EVT Please enter passkey!");
      break;
#endif

    /* when GAP mode changed, this event comes */
    case ESP_BT_GAP_MODE_CHG_EVT:
      ESP_LOGI(BT_AV_TAG, "ESP_BT_GAP_MODE_CHG_EVT mode: %d",
               param->mode_chg.mode);
      break;
    /* when ACL connection completed, this event comes */
    case ESP_BT_GAP_ACL_CONN_CMPL_STAT_EVT:
      bda = (uint8_t*)param->acl_conn_cmpl_stat.bda;
      ESP_LOGI(BT_AV_TAG,
               "ESP_BT_GAP_ACL_CONN_CMPL_STAT_EVT Connected to "
               "[%02x:%02x:%02x:%02x:%02x:%02x], status: 0x%x",
               bda[0], bda[1], bda[2], bda[3], bda[4], bda[5],
               param->acl_conn_cmpl_stat.stat);
      break;
    /* when ACL disconnection completed, this event comes */
    case ESP_BT_GAP_ACL_DISCONN_CMPL_STAT_EVT:
      bda = (uint8_t*)param->acl_disconn_cmpl_stat.bda;
      ESP_LOGI(BT_AV_TAG,
               "ESP_BT_GAP_ACL_DISC_CMPL_STAT_EVT Disconnected from "
               "[%02x:%02x:%02x:%02x:%02x:%02x], reason: 0x%x",
               bda[0], bda[1], bda[2], bda[3], bda[4], bda[5],
               param->acl_disconn_cmpl_stat.reason);
      break;
    /* others */
    default: {
      ESP_LOGI(BT_AV_TAG, "event: %d", event);
      break;
    }
  }
}

void bt_app_a2d_data_cb(const uint8_t* data, uint32_t len) {
  // Check if instance of driver is connected, pass data if so
  if (currentPtr != NULL && currentPtr->dataHandler != NULL) {
    currentPtr->dataHandler(data, len);
  }
}

void local_set_volume(uint8_t volume) {
  euph::A2DPDriver::Event event = {.type = A2DPDriver::EventType::VOLUME,
                                   .data = volume};

  if (currentPtr != NULL && currentPtr->eventHandler != NULL) {
    currentPtr->eventHandler(event);
  }
}

// Prepare audio activity event, notify listener
void local_active_audio(bool active) {
  euph::A2DPDriver::Event event = {
      .type = A2DPDriver::EventType::PLAYBACK_STATE, .data = active};

  if (currentPtr != NULL && currentPtr->eventHandler != NULL) {
    currentPtr->eventHandler(event);
  }
}

// Prepare sample rate event, notify listener
void local_set_sr(uint32_t sr) {
  euph::A2DPDriver::Event event = {
      .type = A2DPDriver::EventType::PLAYBACK_SAMPLERATE, .data = sr};

  if (currentPtr != NULL && currentPtr->eventHandler != NULL) {
    currentPtr->eventHandler(event);
  }
}

// Prepare metadata event, notify listener
void local_metadata_updated(char* artist, char* album, char* title,
                            int duration) {
  euph::A2DPDriver::PlaybackMetadata playbackMetadata{
      .artist = std::string(artist),
      .album = std::string(album),
      .title = std::string(title),
      .duration = duration};

  euph::A2DPDriver::Event event = {
      .type = A2DPDriver::EventType::PLAYBACK_METADATA,
      .data = playbackMetadata};

  if (currentPtr != NULL && currentPtr->eventHandler != NULL) {
    currentPtr->eventHandler(event);
  }
}

static void bt_av_hdl_stack_evt(uint16_t event, void* p_param) {
  ESP_LOGD(BT_AV_TAG, "%s event: %d", __func__, event);

  switch (event) {
    /* when do the stack up, this event comes */
    case BT_APP_EVT_STACK_UP: {
      esp_bt_dev_set_device_name(DEVICE_NAME);
      esp_bt_gap_register_callback(bt_app_gap_cb);

      assert(esp_avrc_ct_init() == ESP_OK);
      esp_avrc_ct_register_callback(bt_app_rc_ct_cb);
      assert(esp_avrc_tg_init() == ESP_OK);
      esp_avrc_tg_register_callback(bt_app_rc_tg_cb);

      esp_avrc_rn_evt_cap_mask_t evt_set = {0};
      esp_avrc_rn_evt_bit_mask_operation(ESP_AVRC_BIT_MASK_OP_SET, &evt_set,
                                         ESP_AVRC_RN_VOLUME_CHANGE);
      assert(esp_avrc_tg_set_rn_evt_cap(&evt_set) == ESP_OK);

      assert(esp_a2d_sink_init() == ESP_OK);
      esp_a2d_register_callback(&bt_app_a2d_cb);
      esp_a2d_sink_register_data_callback(bt_app_a2d_data_cb);

      /* Get the default value of the delay value */
      esp_a2d_sink_get_delay_value();

      /* set discoverable and connectable mode, wait to be connected */
      esp_bt_gap_set_scan_mode(ESP_BT_CONNECTABLE, ESP_BT_GENERAL_DISCOVERABLE);
      break;
    }
    /* others */
    default:
      ESP_LOGE(BT_AV_TAG, "%s unhandled event: %d", __func__, event);
      break;
  }
}

void A2DPDriver::processQueue() {
  bt_app_handle_queue();
}