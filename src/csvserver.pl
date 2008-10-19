#!/usr/bin/perl -w
# Minimalist APAS server
# (c) 2008 Jonathan Auer <jda@tapodi.net>

use strict;

use IO::Socket::INET;
use Net::Canopy::BAM;
#use Net::MAC;
use Getopt::Long;
use Text::CSV;
#use Data::Dumper;

my $version = "0.1";
my $ncb = Net::Canopy::BAM->new();

sub helpmessage {
  my $message = "JungleAuth CSVserver, version $version (c) 2008 Jonathan Auer\n";
  $message .= "This is a minimalistic BAM server using a CSV file as the SM database\n\n";
  $message .= "Usage: ./csvserver.pl --smlist users.csv\n\n";
  $message .= "users.csv needs to be in the following format:\n";
  $message .= "SM MAC, Download MIR, Upload MIR, Download bucket size, Upload bucket size\n";
  $message .= "MIR values are in kbps. Bucket sizes are in kbits\n";
  $message .= "For example, 1.5Mbps down, 640Kbps up, 50Meg download bucket, 15Meg upload bucket:\n";
  $message .= "0a003e903575,1544,640,51200,15360\n";
  print $message;
}

my $csvfile = ''; # CSV file of SMs to allow on and what speeds they get
my $help = 0;

# Validate paramaters
GetOptions('smlist=s' => \$csvfile, 'help|?' => \$help);
if ($help) {
  helpmessage();
  exit(1);
}

if ($csvfile eq '') {
  helpmessage();
  exit(1);
}

# Preload auth data
print "Loading SM config data...\n";
my %users = ();
my $csv = Text::CSV->new();
open (CSV, "<", $csvfile) or die $!;
while (<CSV>) {
  if ($csv->parse($_)){
    my @record = $csv->fields();
    if (@record == 5) {
      $users{$record[0]} = $ncb->buildQstr(
        downspeed => $record[1],
        upspeed => $record[2],
        downbucket => $record[3],
        upbucket => $record[4]
      );
    }
  }
}
close CSV;

my $bamsock = new IO::Socket::INET->new(LocalPort=>1234, Proto=>'udp', Reuse => 1);
my $gseq = 0;

print "Ready to process requests...\n";

while (1) {
  my $data;
  $bamsock->recv($data, 20);

  if ($data ne '') {
    # Show request
    my $data = $ncb->parsePacket(packet=>$data);
    #print Dumper($data); 
    my $apIP = $bamsock->peerhost();
    
    if ($data->{type} eq 'authreq') {
      $gseq = $data->{seq};
      my $resp; 
      if ($users{$data->{sm}}) {
        $resp = $ncb->mkAcceptPacket(
          seq => $data->{seq},
          mac => $data->{sm},
          qos => $users{$data->{sm}}
        );
        print "Accepted SM: $data->{sm}\n";
      } else {
        $resp = $ncb->mkRejectPacket(
          seq => $data->{seq},
          mac => $data->{sm}
        );
        print "Rejected SM: $data->{sm}\n";
      }
      
      #print "Got auth: " . unpack('H*', $resp) . "\n";
      
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
        qos => $users{$data->{sm}}
      );
      
      #print "Type 45: " . unpack('H*', $resp) . "\n";
      
      $bamsock->send($resp);
    }
  }
}
