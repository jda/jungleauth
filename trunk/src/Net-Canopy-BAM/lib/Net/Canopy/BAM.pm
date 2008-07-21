package Net::Canopy::BAM;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our $VERSION = '0.01';

sub new {

}



1;
__END__

=head1 NAME

Net::Canopy::BAM - Interact with Motorola Canopy Bandwidth Authentication Manager

=head1 SYNOPSIS

  use Net::Canopy::BAM;

=head1 DESCRIPTION

Common Packet Assembly, Disassembly, and Identification  for 
L<Net::Canopy::BAM::Client> and L<Net::Canopy::BAM::Server>. 

=head1 METHODS

None.

=head1 SEE ALSO

Canopy BAM User Guide, Issue 4/BAM 1.1

See http://code.google.com/p/jungleauth/ for wiki, bug reports, svn, etc.

=head1 AUTHOR

Jonathan Auer, E<lt>jda@tapodi.netE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008 by Jonathan Auer

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

=cut
