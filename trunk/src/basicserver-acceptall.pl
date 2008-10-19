#!/usr/bin/perl -w

use strict;

use IO::Socket::INET;
use Net::Canopy::BAM;
use Net::MAC;
use Data::Dumper;

my $ncb = Net::Canopy::BAM->new();
my $qos = $ncb->buildQstr(
	upspeed=>512,
	downspeed=>1024, 
	upbucket=>320000, 
	downbucket=>5120000
);
my $bamsock = new IO::Socket::INET->new(LocalPort=>1234, Proto=>'udp', Reuse => 1);
my $gseq = 0;
while (1) {
  my $data;
  $bamsock->recv($data, 20);

  if ($data ne '') {
    # Show request
    my $data = $ncb->parsePacket(packet=>$data);
    print Dumper($data);
    
    my $apIP = $bamsock->peerhost();
    
    if ($data->{type} eq 'authreq') {
	    $gseq = $data->{seq};
	    my $resp = $ncb->mkAcceptPacket(
		    seq => $data->{seq},
		    mac => $data->{sm},
		    qos => $qos);
	    print unpack('H*', $resp) . "\n";
	    
	    my $respsock = new IO::Socket::INET->new(
		    PeerPort => 61001, 
		    Proto => 'udp',
		    PeerAddr => $apIP,
		    LocalPort => 61001) or die "$@\n";
	    $respsock->send($resp);
    } elsif ($data->{type} eq 'unknown-45') {
	    my $resp = $ncb->mkAcceptPacket(
		    seq => $gseq,
		    mac => $data->{sm},
		    qos => $qos);
    
	    print unpack('H*', $resp) . "\n";
	    
	    $bamsock->send($resp);
    } else {
	print Dumper($data);    
    }
  }
}
