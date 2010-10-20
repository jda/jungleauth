#!/usr/bin/perl -w
# Drop in replacement for Canopy BAM 2.0 daemon
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

use warnings;
use strict;

use POE;
use POE::Component::SimpleDBI;

use IO::Socket::INET;
use Net::Canopy::BAM;

use Config::INI::Reader;

use KyotoCabinet;
use JSON::XS;

# Handle startup init tasks
if (@ARGV != 3) {
  print "Usage: $0 BAM-sse.conf auth-cache.kch USE.THIS.IP.ADDR\n";
  exit(1);
}

my $configfile = $ARGV[0];
my $cachedbname = $ARGV[1];
my $bindIP = $ARGV[2];

my $config = Config::INI::Reader->read_file($configfile);
$config = $config->{client};

my $seencache = new KyotoCabinet::DB;
if (!$seencache->open($cachedbname, 
  $seencache->OWRITER | $seencache->OCREATE| $seencache->OAUTOSYNC)) {
    print "Could not open cache database: " . $seencache->error() . "\n";
    exit(1);
}

my $ncb = Net::Canopy::BAM->new();

POE::Component::SimpleDBI->new('SimpleDBI') or die 'Unable to create DBI session';

POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->post('SimpleDBI', 'CONNECT',
        'DSN'         => "DBI:mysql:database=04004SSE;host=$config->{sqlhost};port=3306",
        'USERNAME'    => $config->{user},
        'PASSWORD'    => $config->{password},
        'NOW'         => 1,
        'EVENT'       => 'conn_handler',
        'AUTO_COMMIT' => 0,
      );
    },

    'conn_handler' => sub {
      my ($kernel, $val) = @_[KERNEL, ARG0];
      if ($val->{ERROR}) {
        print "Fatal error with database: $val->{ERROR}\n";
        exit(1);
      };
    }
  },
);

# Network handler
POE::Session->create(
  inline_states => {
    _start        => \&server_start,
    get_datagram  => \&server_read,
    auth_request  => \&auth_request,
    auth_response => \&auth_response,
    confirm_auth  => \&confirm_auth,
  }
);
POE::Kernel->run();
exit;

# Generate authentication response
sub auth_response {
  my ($kernel, $dbres) = @_[KERNEL, ARG0];
  my $data = delete($dbres->{BAGGAGE});
  $data->{qos} = $dbres->{RESULT}->{qos};

  my $resp;

  if ($dbres->{RESULT}->{qos}) {
    $seencache->set($data->{sm}, encode_json($data));
    $resp = $ncb->mkAcceptPacket(
      seq => $data->{seq},
      mac => $data->{sm},
      qos => $data->{qos},
    );
  } else {
    $seencache->remove($data->{sm});
    $resp = $ncb->mkRejectPacket(
      seq => $data->{seq},
      mac => $data->{sm},
    );
  }
  
  my $respsock = new IO::Socket::INET->new(
    PeerPort  => 61001,
    Proto     => 'udp',
    PeerAddr  => $data->{apip},
    LocalAddr => $data->{myip},
    LocalPort => 61001,
  ) or die "Could not create reply socket: $@\n";
  $respsock->send($resp);
}

# Handle unknown-45 request
sub confirm_auth {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  my $sm = $data->{sm};

  if (my $jdata = $seencache->get($sm)) {
    $data = decode_json($jdata);
    my $resp;
    
    $resp = $ncb->mkAcceptPacket(
      seq => $data->{seq},
      mac => $data->{sm},
      qos => $data->{qos},
    );

    my $respsock = new IO::Socket::INET->new(
      PeerPort  => 61001,
      Proto     => 'udp',
      PeerAddr  => $data->{apip},
      LocalAddr => $data->{myip},
      LocalPort => 61001,
    ) or die "Could not create reply socket: $@";
    $respsock->send($resp);
  } else {
    $data->{seq} = 0;
    $kernel->post($_[SESSION], 'auth_request', $data);
  }
}

# Handle authentication request
sub auth_request {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  $kernel->post('SimpleDBI', 'SINGLE',
    'SQL'          => 'SELECT qos FROM SS WHERE esn = ? AND ENABLE = 1',
    'PLACEHOLDERS' => [$data->{sm}],
    'EVENT'        => 'auth_response',
    'BAGGAGE'      => $data,
  );
}

# Setup server connection
sub server_start {
  my $kernel = $_[KERNEL];
  my $socket = IO::Socket::INET->new(
    Proto     => 'udp',
    LocalPort => '1234',
    LocalHost => $bindIP,
  );
  die "Couldn't create server socket: $@" unless $socket;
  $kernel->select_read($socket, "get_datagram");
}

sub server_read {
  my ($kernel, $socket) = @_[KERNEL, ARG0];
  my $data;

  $socket->recv($data, 20);

  $data = $ncb->parsePacket(packet => $data);
  $data->{apip} = $socket->peerhost();
  $data->{myip} = $socket->sockhost();

  if ($data->{type} eq 'authreq') {
    $kernel->post($_[SESSION], 'auth_request', $data);
  } elsif ($data->{type} eq 'unknown-45') {
    $kernel->post($_[SESSION], 'confirm_auth', $data);  
  } 
}

