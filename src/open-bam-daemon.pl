#!/usr/bin/perl -w
# JungleAuth drop in replacement for Canopy BAM daemon
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
use POE::Component::EasyDBI;

use IO::Socket::INET;
use Net::Canopy::BAM;

use Config::INI::Reader;

use Data::Dumper;

# Handle startup init tasks
if (@ARGV != 1) {
  print "Usage: $0 BAM-sse.conf\n";
  exit(1);
}

my $config = Config::INI::Reader->read_file($ARGV[0]);
$config = $config->{client};

POE::Session->create(
  inline_states => {
    _start       => \&server_start,
    get_datagram => \&server_read,
  }
);
POE::Kernel->run();
exit;

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
}

