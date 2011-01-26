#!/opt/nwx/bin/perl -w
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
use POE::Component::Daemon;

use IO::Socket::INET;
use Net::Canopy::BAM;

use Config::INI::Reader;
use Data::Dumper;

# Handle startup init tasks
if (@ARGV != 2) {
  print "Usage: $0 BAM-sse.conf USE.THIS.IP.ADDR\n";
  exit(1);
}

my $configfile = $ARGV[0];
my $bindIP = $ARGV[1];

my $config = Config::INI::Reader->read_file($configfile);
my $authconfig = $config->{authclient};
my $logconfig = $config->{logclient};

# Congested AP override APs
open(BusyAP, '/etc/bam/aplist.txt');
my @busyAPlist = <BusyAP>;
close(BusyAP);

# Congested AP override exemption
open(SkipSM, '/etc/bam/smmac.txt');
my @SkipSMlist = <SkipSM>;
close (SkipSM);

my %is_busy_ap;
for (@busyAPlist) { 
  chomp;
  $is_busy_ap{$_} = 1;
}

my %is_exempt_sm;
for (@SkipSMlist) {
  chomp;
  $is_exempt_sm{$_} = 1;
}

my $ncb = Net::Canopy::BAM->new();

POE::Component::SimpleDBI->new('SimpleDBI') or die 'Unable to create DBI session';
POE::Component::SimpleDBI->new('TrackerSimpleDBI') or die 'Unable to create DBI session for tracker';

POE::Component::Daemon->spawn(detach=>1, max_children=>5);

# Auth database
POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->post('SimpleDBI', 'CONNECT',
        'DSN'         => "DBI:mysql:database=04004SSE;host=$authconfig->{sqlhost};port=3306",
        'USERNAME'    => $authconfig->{user},
        'PASSWORD'    => $authconfig->{password},,
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

# Log database
POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->post('TrackerSimpleDBI', 'CONNECT',
        'DSN'         => "DBI:Pg:database=jungleware;host=$logconfig->{sqlhost}",
        'USERNAME'    => $logconfig->{user},
        'PASSWORD'    => $logconfig->{password},
        'NOW'         => 1,
        'EVENT'       => 'conn_handler',
        'AUTO_COMMIT' => 1,
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
    # for tracking
    tracker_start => \&tracker_start,
    tracker_do    => \&tracker_do,
    tracker_update=> \&tracker_update,
    tracker_add   => \&tracker_add,
    tracker_done  => \&tracker_done,
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
  my $userOK = 0;

  if ($dbres->{RESULT}->{qos}) {
    $userOK = 1;
    $resp = $ncb->mkAcceptPacket(
      seq => $data->{seq},
      mac => $data->{sm},
      qos => $data->{qos},
    );
  } else {
    $userOK = 0;
    $resp = $ncb->mkRejectPacket(
      seq => $data->{seq},
      mac => $data->{sm},
    );
  }

  if ($userOK == 1 && exists $is_busy_ap{$data->{apip}} && !exists $is_exempt_sm{$data->{sm}}) {
    #print "Override speed for $data->{sm} on $data->{apip}\n"; 
    $resp = $ncb->mkAcceptPacket(
      seq => $data->{seq},
      mac => $data->{sm},
      qos => '010001800003A9800003A9800000000000000000000000000000000000000000',
    );
  };

  my $respsock = new IO::Socket::INET->new(
    PeerPort  => 61001,
    Proto     => 'udp',
    PeerAddr  => $data->{apip},
    LocalAddr => $data->{myip},
    LocalPort => 61001,
  ) or die "Could not create reply socket: $@\n";
  $respsock->send($resp);
  
  $kernel->post($_[SESSION], 'tracker_start', $data);
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

# Start the process of tracking sm
sub tracker_start {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  
  $kernel->post('TrackerSimpleDBI', 'SINGLE',
    'SQL'          => 'SELECT id FROM smtracker WHERE mac = ?',
    'PLACEHOLDERS' => [$data->{sm}],
    'EVENT'        => 'tracker_do',
    'BAGGAGE'      => $data,
  );
}

# Check sm tracker database for existing record. If record exists, 
# trigger update, if not, do insert
sub tracker_do {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  
  if (defined $data->{RESULT}) {
    $kernel->post($_[SESSION], 'tracker_update', $data);
  } else {
    $kernel->post($_[SESSION], 'tracker_add', $data);
  }
}

# Add new record to sm tracker database
sub tracker_update {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  my $id = $data->{RESULT}->{id};
  $data = $data->{BAGGAGE};

  my $state = 'false';
  if (defined $data->{qos}) {
    $state = 'true';
  }

  $kernel->post('TrackerSimpleDBI', 'SINGLE',
    'SQL'          => 'UPDATE smtracker SET apip = ?, luid = ?, regok = ? WHERE id = ?',
    'PLACEHOLDERS' => [$data->{apip}, $data->{luid}, $state, $id],
    'EVENT'        => 'tracker_done',
    'BAGGAGE'      => $data,
  );
}

# Update existing record in sm tracker database
sub tracker_add {
# insert into smtracker (mac, apip, luid, laststate) values ()
  my ($kernel, $data) = @_[KERNEL, ARG0];
  $data = $data->{BAGGAGE};

  my $state = 'false';
  if (defined $data->{qos}) {
    $state = 'true';
  }

  $kernel->post('TrackerSimpleDBI', 'SINGLE',
    'SQL'          => 'INSERT INTO smtracker (mac, apip, luid, regok) VALUES (?, ?, ?, ?)',
    'PLACEHOLDERS' => [$data->{sm}, $data->{apip}, $data->{luid}, $state],
    'EVENT'        => 'tracker_done',
    'BAGGAGE'      => $data,
  );
}

# Clean up and diagnostics
sub tracker_done {
  my ($kernel, $data) = @_[KERNEL, ARG0];
  #print Dumper($data);
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

