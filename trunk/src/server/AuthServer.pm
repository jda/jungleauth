#
# Implements actual authentication server for JungleAuth
#
# Copyright 2010 Jonathan Auer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use IO::Socket::INET;
use Net::Canopy::BAM;
use MooseX::Declare;

class AuthServer {
  has 'address'   => (is => 'ro', required => 1, isa => 'Str', default => '127.0.0.1');
  has 'authdbh'   => (is => 'ro', required => 1);
  has 'logdbh'    => (is => 'ro', required => 1);
  has '_sequence' => (is => 'rw', required => 1, isa => 'Int', default => 0);

  # is AP allowed to submit SMs for auth?
  # returns 0 if AP is unknown, -1 if AP is known and has no override, otherwise 
  # returns rate ID
  method _validAP(Str $ap) {
    #my $sth = $self->_authdb->prepare("SELECT * FROM accesspoints WHERE macaddr = ?");
    #$sth->execute($ap);

  }

  # Is SM allowed to auth?
  # returns 0 if SM is unknown, otherwise returns rate ID
  method _validSM(Str $sm) {

  }

  # returns hash of rate config params
  method _getRateConfig(Int $rate) {

  }

  # returns hash of rate config params generated by 
  # taking the lowest values of two rates
  method _genLowRate(Int $a, Int $b) {

  }

  method _sendResponse($destination, $message) {
    my $response = new IO::Socket::INET->new(
      PeerPort  => 61001,
      Proto     => 'udp',
      PeerAddr  => $destination,
      LocalPort => 61001
    ) or die "Error creating outbound socket: $@\n";
    $response->send($message);
  }

  method run() {
    my $bamsock = new IO::Socket::INET->new(
      LocalPort => 1234,
      Proto     => 'udp',
      Reuse     => 1,
      LocalAddr => $self->_address
    );
    while (1) {
      my $data;
      $bamsock->recv($data, 20); 
    }
  }
}

