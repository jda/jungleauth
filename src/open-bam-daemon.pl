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

use Tie::Hash;
use Data::Dumper;

# Handle startup init tasks
if (@ARGV != 1) {
  print "Usage: $0 BAM-sse.conf\n";
  exit(1);
}

my $config = Config::INI::Reader->read_file($ARGV[0]);
$config = $config->{client};


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
  }
);
POE::Kernel->run();
exit;

# Generate authentication response
sub auth_response {
  my ($kernel, $dbres) = @_[KERNEL, ARG0];
  my $data = delete($dbres->{BAGGAGE});

  my $resp;

  if ($dbres->{RESULT}) {
    $resp = $ncb->mkAcceptPacket(
      seq => $data->{seq},
      mac => $data->{sm},
      qos => $dbres->{RESULT}->{qos},
    );
  } else {
    $resp = $ncb->mkRejectPacket(
      seq => $data->{seq},
      mac => $data->{sm},
    );
  }

  my $respsock = new IO::Socket::INET->new(
    PeerPort  => 61001,
    Proto     => 'udp',
    PeerAddr  => $data->{apip},
    LocalPort => 61001,
  ) or warn "Could not create reply socket";
  
  if ($respsock) {
    $respsock->send($resp);
  }
}

# Handle authentication request
sub auth_request {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  $kernel->post('SimpleDBI', 'SINGLE',
    'SQL'          => 'SELECT qos FROM SS WHERE esn = ?',
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
  );
  die "Couldn't create server socket: $!" unless $socket;
  $kernel->select_read($socket, "get_datagram");
}

sub server_read {
  my ($kernel, $socket) = @_[KERNEL, ARG0];
  my $data;

  $socket->recv($data, 20);
  my $apIP = $socket->peerhost();

  $data = $ncb->parsePacket(packet => $data);
  if ($data->{type} eq 'authreq') {
      $data->{apip} = $apIP;
      $kernel->post($_[SESSION], 'auth_request', $data);
  }
}

