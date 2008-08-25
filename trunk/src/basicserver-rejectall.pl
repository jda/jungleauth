#!/usr/bin/perl -w

use strict;

use IO::Socket::INET;
use Net::MAC;
use Data::Dumper;
use Net::Canopy::BAM;

my $ncb = Net::Canopy::BAM->new();
my $bamsock = new IO::Socket::INET->new(LocalPort=>1234, Proto=>'udp', Reuse => 1);

while (1) {
  my $data;
  $bamsock->recv($data, 20);

  if ($data ne '') {
    # Show request
    my $data2 = $ncb->parsePacket(packet=>$data);
    
    print Dumper($data2);
    
    my $resp = $ncb->mkRejectPacket(seq=>$data2->{seq}, mac=>$data2->{sm});

    my $apIP = $bamsock->peerhost();
    
    my $respsock = new IO::Socket::INET->new(
      PeerPort => 61001, 
      Proto => 'udp',
      PeerAddr => $apIP,
      LocalPort => 61001) or die "$@\n";
    $respsock->send($resp);
  }
}
