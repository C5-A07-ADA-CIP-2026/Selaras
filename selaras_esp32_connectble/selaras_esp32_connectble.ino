#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "4FAFC201-1FB5-459E-8FCC-C5C9C331914B"
#define CHARACTERISTIC_UUID "BEA57604-1C34-45B5-927A-94943E992383"

BLEServer* pServer = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println(">> iPhone Terhubung!");
    }
    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println(">> iPhone Terputus!");
    }
};

void setup() {
    Serial.begin(115200);
    delay(1000);

    // 1. Generate nama unik otomatis dari MAC Address chip ESP32 kamu
    uint64_t chipId = ESP.getEfuseMac();
    char uniqueDeviceName[32];
    snprintf(uniqueDeviceName, sizeof(uniqueDeviceName), "Selaras-%04X%04X", 
             (uint16_t)(chipId >> 16), (uint16_t)chipId);

    Serial.print("Nama BLE: ");
    Serial.println(uniqueDeviceName);

    // 2. Set nama perangkat ke nama unik Selaras
    BLEDevice::init(uniqueDeviceName);

    // 3. Buat BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // 4. Buat Service & Characteristic
    BLEService *pService = pServer->createService(SERVICE_UUID);
    BLECharacteristic *pChar = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pChar->addDescriptor(new BLE2902());
    pChar->setValue("Selaras Ready");
    pService->start();

    // 5. Broadcast Service
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();

    Serial.println("Menunggu koneksi dari aplikasi Selaras...");
}

void loop() {
    if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        oldDeviceConnected = deviceConnected;
    }
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}