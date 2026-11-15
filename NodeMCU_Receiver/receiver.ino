// ============================================================

// SMART SAFETY RECEIVER

// NodeMCU ESP8266 + HC-12 + TFT + Firebase

// ============================================================



// ============================================================

// FIREBASE DEFINITIONS

// ============================================================



#define ENABLE_USER_AUTH

#define ENABLE_DATABASE

#define ENABLE_ESP_SSLCLIENT



#include <ESP8266WiFi.h>

#include <FirebaseClient.h>

#include "ExampleFunctions.h"



// ============================================================

// WIFI + FIREBASE SETTINGS

// ============================================================



#define WIFI_SSID       

#define WIFI_PASSWORD   



#define API_KEY        



#define USER_EMAIL      

#define USER_PASSWORD   



#define DATABASE_URL   



// ============================================================

// FIREBASE OBJECTS

// ============================================================



SSL_CLIENT ssl_client;



using AsyncClient = AsyncClientClass;



AsyncClient aClient(ssl_client);



UserAuth user_auth(

  API_KEY,

  USER_EMAIL,

  USER_PASSWORD,

  3000

);



FirebaseApp app;

RealtimeDatabase Database;





// ============================================================

// HC-12

// ============================================================



#include <SoftwareSerial.h>



#define HC12_RX D1

#define HC12_TX D2



SoftwareSerial HC12(HC12_RX, HC12_TX);





// ============================================================

// TFT

// ============================================================



#include <Adafruit_GFX.h>

#include <Adafruit_ST7735.h>

#include <SPI.h>



#define TFT_CS  D8

#define TFT_DC  D3

#define TFT_RST D4



Adafruit_ST7735 tft = Adafruit_ST7735(

  TFT_CS,

  TFT_DC,

  TFT_RST

);





// ============================================================

// MATH

// ============================================================



#include <math.h>





// ============================================================

// THRESHOLDS (raised demonstration values; not validated safety limits)

// Temperature (C)
#define TEMP_HIGH_WARNING  45.0
#define TEMP_HIGH_DANGER   50.0
#define TEMP_LOW_WARNING   10.0
#define TEMP_LOW_DANGER     5.0

// Relative humidity (%)
#define HUM_HIGH_WARNING   90.0
#define HUM_HIGH_DANGER    95.0
#define HUM_LOW_WARNING   20.0
#define HUM_LOW_DANGER    10.0

// Gas raw ADC value (calibrate for your sensor)
#define GAS_WARNING       1400
#define GAS_DANGER        1800

// Acceleration magnitude (g)
#define ACCEL_WARNING     2.5
#define ACCEL_DANGER      3.0


// SENSOR VARIABLES

// ============================================================



float temperature = 0.0;

float humidity = 0.0;



int gasRaw = 0;



float accelX = 0.0;

float accelY = 0.0;

float accelZ = 0.0;



float accelMag = 0.0;





// ============================================================

// STATUS

// ============================================================



bool danger = false;

bool warning = false;



bool displayDirty = false;



unsigned long lastBlink = 0;

bool blinkState = false;





// ============================================================

// FIREBASE CONTROL

// ============================================================



// New sensor data has arrived

bool newSensorData = false;



// Firebase request currently in progress

bool firebaseRequestPending = false;



// Upload interval

unsigned long lastFirebaseUpload = 0;



const unsigned long FIREBASE_INTERVAL = 3000;





// ============================================================

// GET VALUE FROM HC-12 PACKET

// ============================================================



String getValue(String data, String key)

{

  int start = data.indexOf(key);



  if (start < 0)

  {

    return "";

  }



  start += key.length();



  int end = data.indexOf(',', start);



  if (end < 0)

  {

    end = data.length();

  }



  return data.substring(start, end);

}





// ============================================================

// CHECK HAZARD

// ============================================================



void checkHazard()

{

  danger = false;

  warning = false;





  // ----------------------------------------------------------

  // TEMPERATURE

  // ----------------------------------------------------------



  if (temperature >= TEMP_HIGH_DANGER ||

      temperature <= TEMP_LOW_DANGER)

  {

    danger = true;

  }

  else if (temperature >= TEMP_HIGH_WARNING ||

           temperature <= TEMP_LOW_WARNING)

  {

    warning = true;

  }





  // ----------------------------------------------------------

  // HUMIDITY

  // ----------------------------------------------------------



  if (humidity >= HUM_HIGH_DANGER ||

      humidity <= HUM_LOW_DANGER)

  {

    danger = true;

  }

  else if (humidity >= HUM_HIGH_WARNING ||

           humidity <= HUM_LOW_WARNING)

  {

    warning = true;

  }





  // ----------------------------------------------------------

  // GAS

  // ----------------------------------------------------------



  if (gasRaw >= GAS_DANGER)

  {

    danger = true;

  }

  else if (gasRaw >= GAS_WARNING)

  {

    warning = true;

  }





  // ----------------------------------------------------------

  // ACCELERATION

  // ----------------------------------------------------------



  if (accelMag >= ACCEL_DANGER)

  {

    danger = true;

  }

  else if (accelMag >= ACCEL_WARNING)

  {

    warning = true;

  }

}





// ============================================================

// GET STATUS

// ============================================================



String getStatus()

{

  if (danger)

  {

    return "DANGER";

  }



  if (warning)

  {

    return "WARNING";

  }



  return "SAFE";

}





// ============================================================

// DYNAMIC 4-BOX TFT DASHBOARD
// Designed for a 160x128 ST7735 display in landscape rotation.

void drawMetricBox(int x, int y, int w, int h, const char *label, String value, uint16_t accent) {
  uint16_t cardColor = tft.color565(24, 30, 48);
  uint16_t labelColor = tft.color565(185, 195, 210);

  tft.fillRoundRect(x, y, w, h, 5, cardColor);
  tft.drawRoundRect(x, y, w, h, 5, accent);

  tft.setTextSize(1);
  tft.setTextColor(labelColor);
  tft.setCursor(x + 5, y + 4);
  tft.print(label);

  tft.setTextColor(accent);
  tft.setCursor(x + 5, y + 19);
  tft.print(value);
}

void drawDashboard() {
  uint16_t bg = tft.color565(10, 15, 28);
  uint16_t white = ST77XX_WHITE;
  uint16_t green = tft.color565(0, 230, 120);
  uint16_t yellow = tft.color565(255, 190, 0);
  uint16_t red = tft.color565(255, 65, 75);
  uint16_t blue = tft.color565(50, 175, 255);
  uint16_t purple = tft.color565(190, 110, 255);

  tft.fillScreen(bg);

  // Header
  tft.setTextSize(1);
  tft.setTextColor(white);
  tft.setCursor(4, 4);
  tft.print("SMART SAFETY");
  tft.setTextColor(tft.color565(130, 155, 185));
  tft.setCursor(112, 4);
  tft.print("LIVE");
  tft.drawFastHLine(3, 15, 154, tft.color565(65, 80, 105));

  // Four live sensor boxes in a 2x2 grid
  drawMetricBox(3, 20, 75, 36, "TEMP C", String(temperature, 1), tft.color565(255, 100, 100));
  drawMetricBox(82, 20, 75, 36, "HUMIDITY %", String(humidity, 1), blue);
  drawMetricBox(3, 60, 75, 36, "GAS RAW", String(gasRaw), purple);
  drawMetricBox(82, 60, 75, 36, "MOVEMENT g", String(accelMag, 2), green);

  // Status bar at the bottom
  uint16_t statusColor = green;
  if (danger) statusColor = red;
  else if (warning) statusColor = yellow;

  tft.fillRoundRect(3, 102, 154, 22, 5, statusColor);
  tft.setTextColor(ST77XX_BLACK);
  tft.setTextSize(1);
  tft.setCursor(9, 110);
  tft.print("STATUS: ");
  tft.print(getStatus());
}

void showBlack() {
  tft.fillScreen(ST77XX_BLACK);
}


// FIREBASE RESULT CALLBACK

// ============================================================



void processData(AsyncResult &aResult)

{

  if (!aResult.isResult())

  {

    return;

  }





  // ----------------------------------------------------------

  // EVENT

  // ----------------------------------------------------------



  if (aResult.isEvent())

  {

    Firebase.printf(

      "Event task: %s, msg: %s, code: %d\n",

      aResult.uid().c_str(),

      aResult.eventLog().message().c_str(),

      aResult.eventLog().code()

    );

  }





  // ----------------------------------------------------------

  // DEBUG

  // ----------------------------------------------------------



  if (aResult.isDebug())

  {

    Firebase.printf(

      "Debug task: %s, msg: %s\n",

      aResult.uid().c_str(),

      aResult.debug().c_str()

    );

  }





  // ----------------------------------------------------------

  // ERROR

  // ----------------------------------------------------------



  if (aResult.isError())

  {

    Firebase.printf(

      "Error task: %s, msg: %s, code: %d\n",

      aResult.uid().c_str(),

      aResult.error().message().c_str(),

      aResult.error().code()

    );





    // Allow another upload attempt later

    if (aResult.uid() == "sensorDataTask")

    {

      firebaseRequestPending = false;

    }



    return;

  }





  // ----------------------------------------------------------

  // SUCCESS

  // ----------------------------------------------------------



  if (aResult.available())

  {

    Firebase.printf(

      "Firebase task: %s, payload: %s\n",

      aResult.uid().c_str(),

      aResult.c_str()

    );





    if (aResult.uid() == "sensorDataTask")

    {

      firebaseRequestPending = false;

      newSensorData = false;



      Serial.println("Firebase upload completed successfully!");

    }

  }

}





// ============================================================

// SEND SENSOR DATA TO FIREBASE

// ============================================================



void sendToFirebase()

{

  if (!app.ready())

  {

    Serial.println("Firebase not ready - waiting...");

    return;

  }





  // ----------------------------------------------------------

  // Create JSON objects

  // ----------------------------------------------------------



  object_t sensorData;



  object_t obj1;

  object_t obj2;

  object_t obj3;

  object_t obj4;

  object_t obj5;

  object_t obj6;

  object_t obj7;

  object_t obj8;





  JsonWriter writer;





  // ----------------------------------------------------------

  // Temperature

  // ----------------------------------------------------------



  writer.create(

    obj1,

    "temperature",

    number_t(temperature, 1)

  );





  // ----------------------------------------------------------

  // Humidity

  // ----------------------------------------------------------



  writer.create(

    obj2,

    "humidity",

    number_t(humidity, 1)

  );





  // ----------------------------------------------------------

  // Gas

  // ----------------------------------------------------------



  writer.create(

    obj3,

    "gas",

    gasRaw

  );





  // ----------------------------------------------------------

  // Acceleration X

  // ----------------------------------------------------------



  writer.create(

    obj4,

    "accelX",

    number_t(accelX, 2)

  );





  // ----------------------------------------------------------

  // Acceleration Y

  // ----------------------------------------------------------



  writer.create(

    obj5,

    "accelY",

    number_t(accelY, 2)

  );





  // ----------------------------------------------------------

  // Acceleration Z

  // ----------------------------------------------------------



  writer.create(

    obj6,

    "accelZ",

    number_t(accelZ, 2)

  );





  // ----------------------------------------------------------

  // Acceleration magnitude

  // ----------------------------------------------------------



  writer.create(

    obj7,

    "accelMag",

    number_t(accelMag, 2)

  );





  // ----------------------------------------------------------

  // Status

  // ----------------------------------------------------------



  writer.create(

    obj8,

    "status",

    string_t(getStatus())

  );





  // ----------------------------------------------------------

  // Combine all objects

  // ----------------------------------------------------------



  writer.join(

    sensorData,

    8,

    obj1,

    obj2,

    obj3,

    obj4,

    obj5,

    obj6,

    obj7,

    obj8

  );





  // ----------------------------------------------------------

  // Send ONE Firebase request

  // ----------------------------------------------------------



  Serial.println();

  Serial.println("Uploading sensor data to Firebase...");





  firebaseRequestPending = true;



  Database.set<object_t>(

    aClient,

    "/sensorData",

    sensorData,

    processData,

    "sensorDataTask"

  );





  Serial.println("Firebase upload request sent");

}





// ============================================================

// SETUP

// ============================================================



void setup()

{

  Serial.begin(115200);





  // ==========================================================

  // HC-12

  // ==========================================================



  HC12.begin(9600);





  // ==========================================================

  // TFT

  // ==========================================================



  tft.initR(INITR_BLACKTAB);



  tft.setRotation(1);



  tft.fillScreen(ST77XX_BLACK);



  tft.setTextColor(ST77XX_WHITE);



  tft.setTextSize(2);



  tft.setCursor(15, 20);

  tft.println("SMART");



  tft.setCursor(15, 45);

  tft.println("SAFETY");



  tft.setTextSize(1);



  tft.setCursor(15, 75);

  tft.println("RECEIVER");



  delay(2000);





  // ==========================================================

  // SERIAL

  // ==========================================================



  Serial.println();

  Serial.println("==============================");

  Serial.println("SMART SAFETY RECEIVER");

  Serial.println("==============================");





  // ==========================================================

  // WIFI

  // ==========================================================



  Serial.println("Connecting to Wi-Fi...");



  WiFi.begin(

    WIFI_SSID,

    WIFI_PASSWORD

  );





  while (WiFi.status() != WL_CONNECTED)

  {

    Serial.print(".");

    delay(500);

  }





  Serial.println();



  Serial.println("Wi-Fi Connected!");





  Serial.print("IP Address: ");



  Serial.println(

    WiFi.localIP()

  );





  // ==========================================================

  // FIREBASE

  // ==========================================================



  Firebase.printf(

    "Firebase Client v%s\n",

    FIREBASE_CLIENT_VERSION

  );





  set_ssl_client_insecure_and_buffer(

    ssl_client

  );





  Serial.println("Initializing Firebase...");





  initializeApp(

    aClient,

    app,

    getAuth(user_auth),

    auth_debug_print,

    "authTask"

  );





  app.getApp<RealtimeDatabase>(

    Database

  );





  Database.url(

    DATABASE_URL

  );





  Serial.println(

    "Waiting for Firebase authentication..."

  );





  // ==========================================================

  // RECEIVER READY

  // ==========================================================



  Serial.println();

  Serial.println(

    "Waiting for ESP32 data..."

  );





  displayDirty = true;

}





// ============================================================

// LOOP

// ============================================================



void loop()

{

  // ==========================================================

  // VERY IMPORTANT

  // Keep Firebase running

  // ==========================================================



  app.loop();





  // ==========================================================

  // RECEIVE HC-12 DATA

  // ==========================================================



  if (HC12.available())

  {

    String data = HC12.readStringUntil('\n');



    data.trim();





    // --------------------------------------------------------

    // Find T:

    // --------------------------------------------------------



    int packetStart = data.indexOf("T:");





    if (packetStart >= 0)

    {

      data = data.substring(packetStart);

    }





    // --------------------------------------------------------

    // Check valid packet

    // --------------------------------------------------------



    if (data.startsWith("T:"))

    {

      Serial.println();

      Serial.println(

        "=============================="

      );





      Serial.print(

        "Received: "

      );



      Serial.println(data);





      // ------------------------------------------------------

      // Extract values

      // ------------------------------------------------------



      String t = getValue(data, "T:");

      String h = getValue(data, "H:");

      String g = getValue(data, "G:");

      String x = getValue(data, "X:");

      String y = getValue(data, "Y:");

      String z = getValue(data, "Z:");





      // ------------------------------------------------------

      // Convert values

      // ------------------------------------------------------



      if (t != "")

      {

        temperature = t.toFloat();

      }





      if (h != "")

      {

        humidity = h.toFloat();

      }





      if (g != "")

      {

        gasRaw = g.toInt();

      }





      if (x != "")

      {

        accelX = x.toFloat();

      }





      if (y != "")

      {

        accelY = y.toFloat();

      }





      if (z != "")

      {

        accelZ = z.toFloat();

      }





      // ------------------------------------------------------

      // Calculate acceleration magnitude

      // ------------------------------------------------------



      accelMag = sqrt(

        accelX * accelX +

        accelY * accelY +

        accelZ * accelZ

      );





      // ------------------------------------------------------

      // Check hazard

      // ------------------------------------------------------



      checkHazard();





      // ------------------------------------------------------

      // SERIAL OUTPUT

      // ------------------------------------------------------



      Serial.print("Temperature : ");

      Serial.print(temperature, 1);

      Serial.println(" C");





      Serial.print("Humidity    : ");

      Serial.print(humidity, 1);

      Serial.println(" %");





      Serial.print("Gas Raw     : ");

      Serial.println(gasRaw);





      Serial.print("Accel X     : ");

      Serial.println(accelX, 2);





      Serial.print("Accel Y     : ");

      Serial.println(accelY, 2);





      Serial.print("Accel Z     : ");

      Serial.println(accelZ, 2);





      Serial.print("Accel Mag   : ");

      Serial.println(accelMag, 2);





      Serial.print("STATUS      : ");

      Serial.println(getStatus());





      Serial.println(

        "=============================="

      );





      // ------------------------------------------------------

      // Mark that new data is available

      // ------------------------------------------------------



      newSensorData = true;





      // ------------------------------------------------------

      // Update TFT

      // ------------------------------------------------------



      displayDirty = true;





      if (!danger)

      {

        blinkState = false;

        lastBlink = millis();

      }

    }

  }





  // ==========================================================

  // FIREBASE UPLOAD

  // ==========================================================



  if (

    app.ready() &&

    newSensorData &&

    !firebaseRequestPending &&

    millis() - lastFirebaseUpload >= FIREBASE_INTERVAL

  )

  {

    lastFirebaseUpload = millis();



    sendToFirebase();

  }





  // ==========================================================

  // TFT DISPLAY UPDATE
  if (displayDirty) {
    drawDashboard();
    displayDirty = false;
  }
}
