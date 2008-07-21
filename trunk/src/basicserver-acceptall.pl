#!/usr/bin/perl -w

use strict;

use IO::Socket::INET;
use Net::MAC;

my $bamsock = new IO::Socket::INET->new(LocalPort=>1234, Proto=>'udp', Reuse => 1);

while (1) {
  my $data;
  $bamsock->recv($data, 20);

  if ($data ne '') {
    # Show request
    $data = unpack('H*', $data);
  
    my $apIP = $bamsock->peerhost();
    my $u1 = substr($data, 0, 2);
    my $smMAC = substr($data, 2, 12);
    my $apMAC = substr($data, 14, 12);
    my $u2 = substr($data, 26, 4);
    my $luid = hex(substr($data, 30, 2));
    my $sequence = hex(substr($data, 36, 4));

    $smMAC = Net::MAC->new('mac' => $smMAC);
    $smMAC = $smMAC->convert('delimiter' => ':', 'bit_group' => 8);
    $smMAC = $smMAC->get_mac();

    $apMAC = Net::MAC->new('mac' => $apMAC);
    $apMAC = $apMAC->convert('delimiter' => ':', 'bit_group' => 8);
    $apMAC = $apMAC->get_mac();
  
    print "Request from: $apIP\n";
    print "Requesting AP: $apMAC\nAttempting SM: $smMAC\nSM LUID: $luid\n";
    print "Sequence number: $sequence\n";
    print "Unknown 1: $u1\nUnknown 2: $u2\n\n";

    # Send reject
    my $uA = "2504000000000000000000670000000100000006";
    my $smrMAC = substr($data, 2, 12);
    my $uB = "0000000300000001000000000700000018";
    my $uC = "ab8d3702bcc7d757280a7d7848f32e5910bf994e739517c";
    my $qosP = "60000000600000020";
    my $qosS = "008000800007a1200007a12000000000000000000000000000000000000000000000000000000000";
    
    my $resp = $uA . $smrMAC . $uB . $uC . $qosP . $qosS;
    print $resp."\n";

    # Format and send response
    $resp = pack('H*', $resp);
    my $respsock = new IO::Socket::INET->new(
      PeerPort => 61001, 
      Proto => 'udp',
      PeerAddr => $apIP,
      LocalPort => 61001) or die "$@\n";
    $respsock->send($resp);
  }
}
