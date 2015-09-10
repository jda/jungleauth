# Introduction #

This page documents the Access Point Authentication Protocol  used by the Motorola Canopy wireless system.

The information on this page was deduced by changing settings in Prizm (the standard AP authentication server from Motorola) and using Wireshark to watch network traffic between Prizm and the AP on my test network. You can read my notes and download the pcap files from my experimentation at http://jungleauth.googlecode.com/svn/trunk/protocol-samples/

# Protocol Description #

## General ##

Communication is via UDP traffic. The AP sends and listens on port 61001. The APAS sends and listens on port 1234.
  * AP: Access Point
  * APAS: Access Point Authentication Server
  * Hex string, network byte order/high nybble first

  * Also see ProtocolExploration

## Caveats ##
  * Airlink encryption is not supported. Encryption support appears to require knowledge of a undisclosed cryptographic function.
  * SM side authentication key is not accounted for either.

## Access Point Registration ##

From AP to APAS, meaning unknown:
| 45000000000000034300000000000000000000000000 |
|:---------------------------------------------|

## Subscriber Module Registration ##
[BAM config](http://jungleauth.googlecode.com/svn/trunk/protocol-samples/sm%20config%201.txt), [packet capture](http://jungleauth.googlecode.com/svn/trunk/protocol-samples/sm%20config%201%20allowed%20try%201.pcap)
  * Access Point will send a registration request every second until a response is received.
![http://jungleauth.googlecode.com/svn/trunk/docs/skipchallenge.png](http://jungleauth.googlecode.com/svn/trunk/docs/skipchallenge.png)

### SM is allowed to register ###
#### Authentication request from AP to APAS ####
| Unknown | SM MAC | AP MAC | Unknown | LUID | Unknown | Sequence number |
|:--------|:-------|:-------|:--------|:-----|:--------|:----------------|
| 01      | 0A003EF05227 | 0A003EF0458C | 0004    | 02   | 0000    | 0000            |

#### Challenge from APAS to AP ####
| Unknown | SM MAC | Unknown |Crypto | Unknown|
|:--------|:-------|:--------|:------|:-------|
| 2304000000000000000000370000000100000006 | 0a003ef05227 | 0000000300000001000000000400000010|000012ec000016fc00006ba200005b60|0000000000000000 |

#### Challenge response from AP to APAS ####
| Unknown | SM MAC | Unknown | AP MAC | Unknown |
|:--------|:-------|:--------|:-------|:--------|
| 2404000200000000000000560000000100000006 | 0a003ef05227 | 000000060000002000000000000000000000000000000000000000000000000000000000000000000000000200000006 | 0a003ef0458c | 0000000500000006d6bb98d8cb5e00000000 |

#### Authentication grant from APAS to AP ####
| Unknown A | Sequence number | Unknown B | SM MAC | Unknown C | Unknown D | QoS preamble | [QoS string](QoSString.md) | Unknown E |
|:----------|:----------------|:----------|:-------|:----------|:----------|:-------------|:---------------------------|:----------|
| 250400000000 | 0000            | 000000670000000100000006 | 0a003ef05227 | 0000000300000001000000000700000018 | ab8d3702bcc7d757280a7d7848f32e5910bf994e739517c | 60000000600000020 | 008000800007a1200007a1200000000000000000000000000000000000000000 | 0000000000000000 |

#### Session Confirmation ####
From AP to APAS:
| Unknown | Token | Unknown | Unknown SM MAC | Unknown |
|:--------|:------|:--------|:---------------|:--------|
| 45000000| 02000001 | 41000000 | 0a003ef05227   | 0000001b0000003200000001000000003300000001000000005a0000000101 |

From APAS to AP:
| Unknown | Token |
|:--------|:------|
| 46000000| 02000001 |

From AP to APAS:
| Unknown | Token | SM MAC | Unknown |
|:--------|:------|:-------|:--------|
| 45000000| 00000004| 42000000 | 0a003ef05227 | 000000670000000e000000020dac0000000f000000040007a12000000010000000020dac00000011000000040007a120000000090000000200000000000a0000000200000000000b0000000200000000000c0000000200000000000d000000010000000037000000020002 |

From APAS to AP:
| Unknown | Token |
|:--------|:------|
| 46000000| 00000004 |

### Subscriber Module is not allowed to register ###
  * Subscriber Module will retry authentication every 15 minutes.
#### Authentication request from AP to APAS ####
| Unknown | SM MAC | AP MAC | Unknown | LUID | Sequence number |
|:--------|:-------|:-------|:--------|:-----|:----------------|
| 01      | 0A003EF05227 | 0A003EF0458C | 0004    | 02   | 00000000        |

#### Rejection response from APAS to AP ####
| Unknown | Sequence number | Unknown | SM MAC | Unknown |
|:--------|:----------------|:--------|:-------|:--------|
|  230400000000| 0004            | 000000370000000100000006 | 0a003ef05227 | 0000000300000001010000000400000010000000000000000000000000000000000000000000000000 |

## Subscriber Module Disconnection ##

### Voluntary ###

### Forced ###