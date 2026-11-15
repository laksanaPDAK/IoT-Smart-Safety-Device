# IoT-Based Smart Safety Device for Real-Time Industrial Worker Safety Monitoring

## 📌 Project Overview

The **IoT-Based Smart Safety Device** is designed to monitor industrial workers' environmental conditions and movement in real time. The system uses multiple sensors to detect potential hazards and transmits sensor data wirelessly for remote monitoring.

The collected data is displayed locally and integrated with Firebase Realtime Database and a Flutter dashboard for remote visualization.

## 🎯 Objectives

- Monitor temperature and humidity in the working environment.
- Detect harmful gas levels using a gas sensor.
- Monitor worker movement using an MPU6050 accelerometer.
- Enable wireless communication between transmitter and receiver.
- Provide remote monitoring through Firebase and Flutter.

## 🏗️ System Architecture

**Data Flow:**

Sensors → ESP32 Transmitter → HC-12 Wireless Communication → NodeMCU Receiver → Wi-Fi → Firebase Realtime Database → Flutter Dashboard

## 🔧 Hardware Components

| Component | Purpose |
|---|---|
| ESP32 | Transmitter and sensor data processing |
| NodeMCU ESP8266 | Receiver and Wi-Fi connectivity |
| DHT22 | Temperature and humidity monitoring |
| Gas Sensor | Gas level detection |
| MPU6050 | Movement and acceleration monitoring |
| HC-12 Modules | Wireless serial communication |
| LCD Display | Local transmitter-side monitoring |
| TFT Display | Receiver-side data visualization |

## 💻 Software and Technologies

- **Programming:** C, C++ 
- **Embedded Platform:** Arduino IDE
- **Wireless Communication:** HC-12 RF Modules (UART)
- **Cloud Database:** Firebase Realtime Database
- **Mobile/Web Application:** Flutter
- **Simulation:** Wokwi
- **Development Environment:** Visual Studio Code

## ⚙️ Working Principle

1. The sensors collect temperature, humidity, gas, and movement data.
2. The ESP32 processes the sensor readings and identifies potential hazard conditions.
3. Sensor data is transmitted wirelessly through the HC-12 module.
4. The NodeMCU receives the transmitted data and provides Wi-Fi connectivity.
5. Data is sent to Firebase Realtime Database.
6. The Flutter dashboard retrieves and displays sensor readings and hazard status.

## 🚨 Hazard Detection

The system classifies operating conditions into three categories:

- **SAFE:** Sensor readings are within configured limits.
- **WARNING:** Sensor readings exceed warning thresholds.
- **DANGER:** Sensor readings exceed danger thresholds.

The thresholds can be configured according to project requirements. Gas sensor readings are processed as raw ADC values unless sensor calibration is performed.

## 📂 Repository Structure

```text
IoT-Smart-Safety-Device/
│
├── Transmitter/
│   └── ESP32 source code
│
├── Receiver/
│   └── NodeMCU source code
│
├── Flutter_App/
│   └── Flutter dashboard application
│
├── Simulation/
│   └── Wokwi simulation files
│
├── Images/
│   └── Hardware and simulation images
│
├── Documentation/
│   └── Project report and documentation
│
├── Circuit_Diagrams/
│   └── Circuit diagrams
│
├── README.md
└── .gitignore
```

## 🔮 Future Enhancements

- GPS-based worker location tracking.
- Real-time push notifications for critical hazards.
- Multi-worker monitoring and identification.
- Improved sensor calibration and industrial-grade sensing.
- Historical data analysis and advanced hazard prediction.

## 👩‍💻 Project Information

**Project Title:** IoT-Based Smart Safety Device for Real-Time Industrial Worker Safety Monitoring and Hazard Detection

**Domain:** Internet of Things (IoT), Embedded Systems and Wireless Communication

**Key Technologies:** ESP32, NodeMCU, HC-12, Firebase and Flutter

## 📜 Disclaimer

This project is developed as an academic prototype for industrial safety monitoring. It is not a replacement for certified industrial safety equipment or emergency protection systems.
