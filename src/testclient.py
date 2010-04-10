#!/usr/bin/env python
# JungleAuth test client
#
#  Copyright 2010 Jonathan Auer
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

import socket, sys, datetime, binascii

def phase1req(sm, ap, luid, sequence=0):
  magic1 = 1
  magic2 = 4
  magic3 = 0

  # magic1 sm ap magic2 luid magic3 sequence 
  return "%02X%s%s%04X%02X%04X%04X" % (magic1, sm, ap, magic2, luid, magic3, sequence)

def beClient(server, mac, timeout=15, localip='0.0.0.0', localmac="0a003edeadbe"):
  localport = 61001

  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sock.bind((localip, localport))

  # fixme: following is converting hex to some other representation before sending
  # which won't work
  sock.sendto(binascii.unhexlify(phase1req(mac, localmac, 2)), (server, 1234))

  while True:
    data, addr = sock.recvfrom(1024)
    print "Got ", data

  sock.close()

if __name__ == '__main__':
  try:
    authserver = sys.argv[1]
    clientmac = sys.argv[2]
  except IndexError:
    print "Usage: %s AuthServerAddress ClientMACAddress" % (sys.argv[0])
    sys.exit(1)
  beClient(authserver, clientmac)


