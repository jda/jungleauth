# Introduction #
This page documents the QoS string encoding used by the Motorola Canopy wireless system.

The QoS string defines subscriber provisioning settings in the Canopy system. It is 64 hex digits long.

## Version 1 (BAM 1.0) ##

| **Field** | **Description** | **Format** | **Example** |
|:----------|:----------------|:-----------|:------------|
| Upload speed | Upload speed in Kbps | 4 hex digits | 512 Kbps -> 0200 |
| Download speed | Download speed in Kbps | 4 hex digits | 768 Kbps -> 0300 |
| Upload bucket | Bucket size in Kb | 8 hex digits | 320000 Kb -> 00004e200 |
| Download bucket | Bucket size in Kb | 8 hex digits | 5120000 Kb -> 0004e2000|
| Future features | Reserved space for future features | 40 zeros (0) | 0000000000000000000000000000000000000000 |

| Upload speed | Download speed | Upload bucket | Download bucket | Future features |
|:-------------|:---------------|:--------------|:----------------|:----------------|
| 0200         | 0300           | 0000 4e200    | 0004 e2000      | 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 |

## Version 2 (BAM 2.1) ##