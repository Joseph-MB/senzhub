# SENZHUB Hardware Specification

## Overview
The hardware component of SENZHUB acts as an autonomous safety node. It is designed to act independently of cloud connectivity when hazardous conditions are detected via gas sensor readings.

## Prototype Components
- **Microcontroller:** ESP32 (handles sensor polling, relay control, and HTTP/HTTPS network requests)
- **Gas Sensor:** MQ-6 
- **Connectivity:** SIM800L GSM Module (and ESP32 native WiFi)
- **Actuation Control:** 5V/12V Relay Module
- **Actuator:** FA0520F 12V DC 3-way solenoid valve

## [WARNING] Safety & Prototype Disclaimer
The currently implemented **FA0520F 12V DC 3-way solenoid valve** is a **prototype only, air-only demonstration** component.
- It is NOT for actual LPG.
- It is used strictly for firmware development, API integration, and hackathon demonstration.

A production deployment MUST replace this with an appropriately certified LPG-compatible safety shutoff valve/system selected and validated for the intended installation.

## Local Safety Priority
The core requirement of the hardware architecture is **Local Safety Priority**.
- The ESP32 evaluates the MQ-6 analog raw sensor readings in a tight local loop.
- If the concentration exceeds `danger_threshold`, the ESP32 interrupts normal operation and removes power from the solenoid (forcing a CLOSE action).
- This circuit overrides any network commands attempting to OPEN the valve.
- Network updates are dispatched *after* the physical safety action is taken.
