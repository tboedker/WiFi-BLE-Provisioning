#include "board.h"
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

bool resetPending = false;
bool prov_state = false;

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Neil Kolbans Arduino BLE Library

BLECharacteristic *pCharacteristics;

class MySecurity : public BLESecurityCallbacks
{

  bool onConfirmPIN(uint32_t pin)
  {
    Serial.println("onConfirmPIN");

    return true;
  }

  uint32_t onPassKeyRequest()
  {
    Serial.println("onPassKeyRequest");
    ESP_LOGI(LOG_TAG, "PassKeyRequest");
    return 133700;
  }

  void onPassKeyNotify(uint32_t pass_key)
  {
    Serial.println("onPassKeyNotify");
    ESP_LOGI(LOG_TAG, "On passkey Notify number:%d", pass_key);
  }

  bool onSecurityRequest()
  {
    Serial.println("onSecurityRequest");
    ESP_LOGI(LOG_TAG, "On Security Request");
    return true;
  }

  void onAuthenticationComplete(esp_ble_auth_cmpl_t cmpl)
  {
    Serial.println("onAuthenticationComplete");
    ESP_LOGI(LOG_TAG, "Starting BLE work!");
    if (cmpl.success)
    {
      Serial.println("onAuthenticationComplete -> success");
      uint16_t length;
      esp_ble_gap_get_whitelist_size(&length);
      ESP_LOGD(LOG_TAG, "size: %d", length);
    }
    else
    {
      Serial.println("onAuthenticationComplete -> fail");
      ESP.restart(); // Thomas : with this I want to force secure bonding
    }
  }
};

class MyCallbacks : public BLECharacteristicCallbacks
{

  void onWrite(BLECharacteristic *pCharacteristic)
  {
    String value = pCharacteristic->getValue().c_str();

    if (value.length() > 0)
    {
      Serial.print("Length : ");
      Serial.println(value.length());

      Serial.print("New value: ");
      for (int i = 0; i < value.length(); i++)
      {
        Serial.print(value[i]);
      }

      Serial.println();

      if (value.substring(0, 3) == "***") // these 3 chars are startdelimiters
      {

        int pos = value.indexOf(';'); // locate the SSID & PW separator char

        String ssid = value.substring(3, pos);
        Serial.print("SSID : ");
        Serial.println(ssid);
        value.remove(0, pos + 1);
        String pass = value;
        Serial.print("PW : ");
        Serial.println(pass);

        // WIFI begin with credentials
      }

      Serial.println();
    }
  }
};

class MyServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer)
  {
    Serial.println("device connected");
  };

  void onDisconnect(BLEServer *pServer)
  {
    Serial.println("device disconnected");
  }
};


// -----------------------------------------------------------------------------------------------

void setup()
{
  Serial.begin(115200);
  pinMode(BTN_PROV, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);

  if (digitalRead(BTN_PROV) == true)
  {

    Serial.println("Prov button NOT pushed");
  }
  else
  {

    prov_state = true;
    Serial.println("Prov button pushed");

    String strBLEAdvertise = "Wi-Fi Device";
    BLEDevice::init(strBLEAdvertise.c_str());

    // Create the BLE Server
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // Create the BLE Service
    BLEService *pService = pServer->createService(SERVICE_UUID);

    BLEDevice::setEncryptionLevel(ESP_BLE_SEC_ENCRYPT);
    BLEDevice::setSecurityCallbacks(new MySecurity());

    pCharacteristics = pService->createCharacteristic(CHARACTERISTIC_UUID,
                                                      BLECharacteristic::PROPERTY_READ |
                                                          BLECharacteristic::PROPERTY_WRITE |
                                                          BLECharacteristic::PROPERTY_NOTIFY |
                                                          BLECharacteristic::PROPERTY_INDICATE);

    pCharacteristics->addDescriptor(new BLE2902());
    pCharacteristics->setCallbacks(new MyCallbacks());

    pService->start();

    BLEAdvertising *pAdvertising = pServer->getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();

    BLESecurity *pSecurity = new BLESecurity();
    pSecurity->setAuthenticationMode(ESP_LE_AUTH_REQ_SC_ONLY);
    pSecurity->setCapability(ESP_IO_CAP_NONE);
    pSecurity->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);

    pCharacteristics->setValue("Connected to ESP32 BLE");
    pCharacteristics->notify();
  }
}


// -----------------------------------------------------------------------------------------------


void loop()
{

  unsigned long cpuTime = millis();

  if (prov_state == false)
  {

    // Your code
  }
  else
  {
    delay(500);
    digitalWrite(BLUE_LED_PIN, HIGH);
    Serial.print(".");
    delay(500);
    digitalWrite(BLUE_LED_PIN, LOW);

    if (ftsclient.connected)
    {

      pCharacteristics->setValue(ftsclient.IPaddress.c_str());
      pCharacteristics->notify();
      resetPending = true;
    }

    if (resetPending == true)
    {
      delay(1000);
      Serial.println("\n\nWill leave provisioning mode and reboot\n\n");
      pCharacteristics->setValue("RESET");
      pCharacteristics->notify();
      delay(3000);
      ESP.restart();
    }
  }

  if ((digitalRead(BTN_PROV) == 0) && (prov_state == false))
  {
    ESP.restart();
  }
}