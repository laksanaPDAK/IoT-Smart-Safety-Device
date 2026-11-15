// ESP32 Soil Moisture Monitoring System

#define SOIL_SENSOR_PIN 34

// Calibration values (adjust after testing)
#define DRY_VALUE 3000
#define WET_VALUE 1200

int soilValue = 0;
int moisturePercentage = 0;

void setup()
{
  Serial.begin(115200);

  delay(1000);

  Serial.println("ESP32 Soil Moisture Monitoring System");
  Serial.println("------------------------------------");
}

void loop()
{
  // Read analog value from soil moisture sensor
  soilValue = analogRead(SOIL_SENSOR_PIN);

  // Convert ADC value into moisture percentage
  moisturePercentage = map(soilValue,
                           DRY_VALUE,
                           WET_VALUE,
                           0,
                          100);

  // Limit percentage between 0 and 100
  moisturePercentage = constrain(moisturePercentage, 0, 100);

  // Display sensor readings
  Serial.print("Raw Sensor Value: ");
  Serial.println(soilValue);

  Serial.print("Soil Moisture: ");
  Serial.print(moisturePercentage);
  Serial.println("%");

  // Check soil condition
  if (moisturePercentage < 30)
  {
    Serial.println("Status: DRY SOIL");
  }
  else if (moisturePercentage < 60)
  {
    Serial.println("Status: MODERATE MOISTURE");
  }
  else
  {
    Serial.println("Status: WET SOIL");
  }

  Serial.println("-----------------------------");

  delay(2000);
}