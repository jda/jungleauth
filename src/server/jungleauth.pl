#!/usr/bin/env perl -w
# JungleAuth Server

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

use strict;

use YAML;
use DBI;

use MooseX::Declare;

use AuthServer;

class Main {
  with 'MooseX::Daemonize';
  has 'config'      => (is => 'ro', isa => 'Str', required => 1);
  has '_conf'       => (is => 'rw');
  has '_bindaddr'   => (is => 'rw', isa => 'Str', default => '127.0.0.1');
  has '_authhandle' => (is => 'rw'); 
  has '_loghandle'  => (is => 'rw');

  before start { 
    # read config before Daemonize changes our working dir
    # so non-absolute config file paths work
    $self->_conf(YAML::LoadFile($self->config));

    # Did we open a config file?
    if (!defined $self->_conf) {
      print "Error: empty or malformed config file.\n";
      exit(1);
    }

    # Is config file remotely valid?
    if (!UNIVERSAL::isa($self->_conf, "HASH")) {
      print "Error: Malformed config file.\n";
      exit(1);
    }

    # Validate config
    my $validError = 0;
    my $validMsg = '';

    if (defined $self->_conf->{'jungleauth'}) {
      if (defined $self->_conf->{'jungleauth'}->{'bindaddr'}) {
        $self->_bindaddr($self->_conf->{'jungleauth'}->{'bindaddr'});
      }
    }
  
    foreach my $section ('authdb', 'logdb') {
      my $dsn = "";
      my $user = "";
      my $pass = "";

      if (defined $self->_conf->{$section}) {

        if (defined $self->_conf->{$section}->{'host'}) {
          $dsn = "DBI:mysql:host=" . $self->_conf->{$section}->{'host'};
        } else {
          $validError += 1;
          $validMsg .= "\tNo host defined for $section in config file\n";
        }

        if (defined $self->_conf->{$section}->{'user'}) {
          $user = $self->_conf->{$section}->{'user'};
        } else {
          $validError += 1;
          $validMsg .= "\tNo user defined for $section in config file\n";
        }

        if (defined $self->_conf->{$section}->{'password'}) {
          $pass = $self->_conf->{$section}->{'password'};
        } else {
          $validError += 1;
          $validMsg .= "\tNo password defined for $section in config file\n";
        }

        if (defined $self->_conf->{$section}->{'database'}) {
          $dsn .= ";database=" . $self->_conf->{$section}->{'database'};
        } else {
          $validError += 1;
          $validMsg .= "\tNo database defined for $section in config file\n";
        }

      } else {
        $validError += 1;
        $validMsg .= "\tNo $section section in config file\n";
      }
   
      # try to connect to database
      if ($validError == 0) {
        if ($section eq 'authdb') {
          my $dbh = DBI->connect($dsn, $user, $pass);
          $self->_authhandle($dbh); 
        } elsif ($section eq 'logdb') {
          my $dbh = DBI->connect($dsn, $user, $pass);
          $self->_loghandle($dbh);
        }
      }
      
    }

    if ($validError > 0) {
      print "Error: $validError errors reading config file\n";
      print $validMsg;
      exit(1);
    }

  }

  after start {
    return unless $self->is_daemon;
  

    my $server = AuthServer->new(
      address => $self->_bindaddr,
      authdbh => $self->_authhandle,
      logdbh  => $self->_loghandle
    );
    $server->run();
  }
}

my $app = Main->new_with_options();
my ($command) = @{$app->extra_argv};
defined $command || die "Usage: -h for help, otherwise start|stop|restart|status";

$app->start   if $command eq 'start';
$app->status  if $command eq 'status';
$app->restart if $command eq 'restart';
$app->stop    if $command eq 'stop';

if (defined($app->status_message)) {
  print $app->status_message . "\n"; 
};
exit $app->exit_code;

