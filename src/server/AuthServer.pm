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

use Net::Canopy::BAM;
use MooseX::Declare;

class AuthServer {
  has 'address' => (isa => 'Str', is => 'ro', required => 1, default => '127.0.0.1');
  has 'authdbh' => (isa => 'Str', is => 'ro', required => 1);
  has 'logdbh'  => (isa => 'Str', is => 'ro', required => 1);
  
  method run() {
    while () {

    }
  }
}

