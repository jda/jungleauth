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

import socket, sys, time, select, binascii

def apOnline():
  magic1 = "45000000000000034300000000000000000000000000"
  return magic1

def phase1req(sm, ap, luid, sequence=0):
  magic1 = 1
  magic2 = 4
  magic3 = 0

  # magic1 sm ap magic2 luid magic3 sequence 
  #return "%02X%s%s%04X%02X%04X%04X" % (magic1, sm, ap, magic2, luid, magic3, sequence)
  return "%02X%s%s%04X%02X%08X" % (magic1, sm, ap, magic2, luid, sequence)

def parseReply(msg):
  #print msg
  part1 = msg[0:40]
  part2 = msg[40:52]
  part3 = msg[52:86]
  part4 = msg[86:118]
  part5 = msg[118:]
  
  print "%s %s %s %s %s" % (part1, part2, part3, part4, part5)

def beClient(server, mac, timeout=15, localip='0.0.0.0', localmac="0a003edeadbe"):
  endTime = time.time() + timeout
  localport = 61001
  apas = (server, 1234)

  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sock.bind((localip, localport))

  #sock.sendto(binascii.unhexlify(apOnline()), apas)

  # Need to explore sequence numbers. How high can we go and get resp from BAM?
  # that will show us field size...
  #for i in range(0,5):
  sock.sendto(binascii.unhexlify(phase1req(mac, localmac, 2, sequence=0)), apas)

  seq = 1
  while (time.time() <= endTime):
    #print "in loop at %s" % (time.time())
    rlist, wlist, xlist = select.select([sock], [], [], 0.1)
    sock.sendto(binascii.unhexlify(phase1req(mac, localmac, 2, sequence=seq)), apas)
    seq += 1

    for s in rlist:
      data, addr = sock.recvfrom(1024)
      #print binascii.hexlify(data)
      parseReply(binascii.hexlify(data))

  sock.close()

if __name__ == '__main__':
  try:
    authserver = sys.argv[1]
    clientmac = sys.argv[2]
  except IndexError:
    print "Usage: %s AuthServerAddress ClientMACAddress" % (sys.argv[0])
    sys.exit(1)
  beClient(authserver, clientmac, timeout=18000)


