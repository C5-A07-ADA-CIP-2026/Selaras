#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_AS7341.h>
#include <Wire.h>

#define SERVICE_UUID        "4FAFC201-1FB5-459E-8FCC-C5C9C331914B"
#define CHARACTERISTIC_UUID "BEA57604-1C34-45B5-927A-94943E992383"
#define I2C_SDA_PIN        6
#define I2C_SCL_PIN        7
#define AS7341_I2C_ADDRESS 0x39

// Sensor pH RS485 Modbus RTU lewat modul TTL-RS485 (default pabrik SN-*-PH-N01:
// 4800 baud 8N1, alamat 1, register 0x0000 = pH x100).
#define PH_RX_PIN              20  // modul TXD -> GPIO20
#define PH_TX_PIN              21  // modul RXD <- GPIO21
#define PH_BAUD_RATE           4800
#define PH_SLAVE_ADDRESS       1
#define PH_REGISTER            0x0000
#define PH_SCALE               100.0f
#define PH_POLL_INTERVAL_MS    1000
#define PH_MAX_AGE_MS          3000
#define PH_RESPONSE_TIMEOUT_MS 150

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
Adafruit_AS7341 as7341;
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool sensorReady = false;
unsigned long lastMeasurementAt = 0;
float lastPh = 0;
bool phKnown = false;
unsigned long lastPhAt = 0;
unsigned long lastPhPollAt = 0;

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

uint16_t modbusCrc(const uint8_t *data, size_t length) {
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < length; i++) {
        crc ^= data[i];
        for (uint8_t bit = 0; bit < 8; bit++) {
            crc = (crc & 1) ? (crc >> 1) ^ 0xA001 : crc >> 1;
        }
    }
    return crc;
}

// Baca pH lewat Modbus fungsi 0x03 (pH dan suhu). Mengembalikan false kalau gagal
// atau nilai di luar 0-14, supaya aplikasi tidak menerima angka palsu.
bool readPh(float *ph) {
    uint8_t request[8] = {
        PH_SLAVE_ADDRESS, 0x03, PH_REGISTER >> 8, PH_REGISTER & 0xFF, 0x00, 0x02, 0, 0
    };
    uint16_t requestCrc = modbusCrc(request, 6);
    request[6] = requestCrc & 0xFF;
    request[7] = requestCrc >> 8;

    while (Serial1.available()) {
        Serial1.read();
    }
    Serial1.write(request, sizeof(request));
    Serial1.flush();

    uint8_t response[9];
    size_t received = 0;
    unsigned long startedAt = millis();
    while (received < sizeof(response) && millis() - startedAt < PH_RESPONSE_TIMEOUT_MS) {
        while (Serial1.available() && received < sizeof(response)) {
            response[received++] = Serial1.read();
        }
        delay(1);
    }
    if (received < sizeof(response)) {
        return false;
    }

    uint16_t expectedCrc = modbusCrc(response, 7);
    uint16_t receivedCrc = response[7] | (response[8] << 8);
    if (expectedCrc != receivedCrc || response[0] != PH_SLAVE_ADDRESS
        || response[1] != 0x03 || response[2] != 4) {
        return false;
    }

    float value = ((response[3] << 8) | response[4]) / PH_SCALE;
    if (value < 0.0f || value > 14.0f) {
        return false;
    }
    *ph = value;
    return true;
}

void updatePh() {
    float ph;
    if (readPh(&ph)) {
        lastPh = ph;
        lastPhAt = millis();
        phKnown = true;
        Serial.printf("pH sensor: %.2f\n", ph);
    } else {
        Serial.println("pH sensor: tidak ada jawaban atau nilai tidak valid.");
    }
}

bool phIsFresh() {
    return phKnown && millis() - lastPhAt <= PH_MAX_AGE_MS;
}

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial1.begin(PH_BAUD_RATE, SERIAL_8N1, PH_RX_PIN, PH_TX_PIN);
    Serial.printf(
        "Sensor pH RS485 dimulai: RX=GPIO%d, TX=GPIO%d, %d baud, alamat %d\n",
        PH_RX_PIN, PH_TX_PIN, PH_BAUD_RATE, PH_SLAVE_ADDRESS
    );

    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    Serial.printf(
        "I2C dimulai: SDA=GPIO%d, SCL=GPIO%d\n",
        I2C_SDA_PIN,
        I2C_SCL_PIN
    );
    scanI2C();

    sensorReady = as7341.begin(AS7341_I2C_ADDRESS, &Wire);
    if (sensorReady) {
        Serial.println("AS7341 siap di alamat I2C 0x39.");
    } else {
        Serial.println(
            "AS7341 tidak ditemukan di 0x39. Periksa power, GND, SDA, SCL, "
            "atau alamat breakout."
        );
    }

    // 1. Generate nama unik otomatis dari MAC Address chip ESP32 kamu
    uint64_t chipId = ESP.getEfuseMac();
    char uniqueDeviceName[32];
    snprintf(uniqueDeviceName, sizeof(uniqueDeviceName), "Serona-%04X%04X", 
             (uint16_t)(chipId >> 16), (uint16_t)chipId);

    Serial.print("Nama BLE: ");
    Serial.println(uniqueDeviceName);

    // 2. Set nama perangkat ke nama unik Serona
    BLEDevice::init(uniqueDeviceName);

    // 3. Buat BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // 4. Buat Service & Characteristic
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pCharacteristic->addDescriptor(new BLE2902());
    pCharacteristic->setValue("{\"visibleAverage\":0,\"clear\":0,\"nir\":0}");
    pService->start();

    if (sensorReady) {
        updateMeasurement();
        lastMeasurementAt = millis();
    }

    // 5. Broadcast Service
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();

    Serial.println("Menunggu koneksi dari aplikasi Serona...");
}

void loop() {
    if (millis() - lastPhPollAt >= PH_POLL_INTERVAL_MS) {
        lastPhPollAt = millis();
        updatePh();
    }

    if (sensorReady && millis() - lastMeasurementAt >= 500) {
        updateMeasurement();
        lastMeasurementAt = millis();
    }

    if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        oldDeviceConnected = deviceConnected;
    }
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}

void scanI2C() {
    uint8_t deviceCount = 0;

    Serial.println("Memindai perangkat I2C...");
    for (uint8_t address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        uint8_t error = Wire.endTransmission();
        if (error != 0) {
            continue;
        }

        Serial.printf("Perangkat I2C ditemukan: 0x%02X", address);
        if (address == AS7341_I2C_ADDRESS) {
            Serial.println(" (alamat AS7341)");
        } else {
            Serial.println();
        }
        deviceCount++;
    }

    if (deviceCount == 0) {
        Serial.println("Tidak ada perangkat I2C ditemukan.");
    }
}

void updateMeasurement() {
    uint16_t readings[12];
    if (!as7341.readAllChannels(readings)) {
        Serial.println("Gagal membaca AS7341.");
        return;
    }

    // readAllChannels order: F1, F2, F3, F4, Clear, NIR, F5, F6, F7, F8, Clear, NIR.
    const uint8_t visibleIndexes[] = {0, 1, 2, 3, 6, 7, 8, 9};
    uint32_t visibleTotal = 0;
    for (uint8_t index : visibleIndexes) {
        visibleTotal += readings[index];
    }

    float visibleAverage = visibleTotal / 8.0f;
    String payload = "{\"visibleAverage\":" + String(visibleAverage, 1)
        + ",\"clear\":" + String(readings[10])
        + ",\"nir\":" + String(readings[11]);
    if (phIsFresh()) {
        payload += ",\"ph\":" + String(lastPh, 2);
    }
    payload += "}";

    Serial.printf(
        "AS7341 raw F1..F8: %u, %u, %u, %u, %u, %u, %u, %u | clear=%u nir=%u | visibleAverage=%.1f\n",
        readings[0], readings[1], readings[2], readings[3],
        readings[6], readings[7], readings[8], readings[9],
        readings[10], readings[11], visibleAverage
    );
    Serial.print("BLE payload: ");
    Serial.println(payload);

    pCharacteristic->setValue(payload.c_str());
    if (deviceConnected) {
        pCharacteristic->notify();
    }
}