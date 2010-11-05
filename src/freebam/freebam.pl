#!/usr/bin/perl -w
# Stand alone Canopy authentication server
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
use POE::Component::Daemon;

use IO::Socket::INET;
use Net::Canopy::BAM 0.04;

use Config::INI::Reader;

# Handle startup init tasks
if (@ARGV != 2) {
  print "Usage: $0 open-bam.ini USE.THIS.IP.ADDR\n";
  exit(1);
}

my $configfile = $ARGV[0];
my $bindIP = $ARGV[1];

my $config = Config::INI::Reader->read_file($configfile);
$config = $config->{client};

my $ncb = Net::Canopy::BAM->new();

POE::Component::SimpleDBI->new('SimpleDBI') or die 'Unable to create DBI session';

POE::Component::Daemon->spawn(detach=>1, max_children=>3);

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
    $resp = $ncb->mkAcceptPacket(
      seq => $data->{seq},
      mac => $data->{sm},
      qos => $data->{qos},
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
    LocalAddr => $data->{myip},
    LocalPort => 61001,
  ) or die "Could not create reply socket: $@\n";
  $respsock->send($resp);
}

# Handle auth verification request
sub confirm_auth {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  my $token = $data->{token};
  
  my $resp = $ncb->mkConfirmPacket($token);
    
  my $respsock = new IO::Socket::INET->new(
    PeerPort  => 61001,
    Proto     => 'udp',
    PeerAddr  => $data->{apip},
    LocalAddr => $data->{myip},
    LocalPort => 61001,
  ) or die "Could not create reply socket: $@";
  $respsock->send($resp);
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
  } elsif ($data->{type} eq 'authverify') {
    $kernel->post($_[SESSION], 'confirm_auth', $data);  
  } 
}

