#
# $Id$
#
# core::global Brik
#
package Metabrik::Core::Global;
use strict;
use warnings;

our $VERSION = '1.11';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(core main global) ],
      attributes => { 
         device => [ qw(device) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
         db => [ qw(db) ],
         file => [ qw(file) ],
         uri => [ qw(uri) ],
         target => [ qw(target) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(udp|tcp) ],
         ctimeout => [ qw(seconds) ],
         rtimeout => [ qw(seconds) ],
         datadir => [ qw(directory) ],
         username => [ qw(username) ],
         hostname => [ qw(hostname) ],
         domainname => [ qw(domainname) ],
         homedir => [ qw(directory) ],
         port => [ qw(port) ],
         # encoding: see `perldoc Encode::Supported' for other types
         encoding => [ qw(utf8|ascii) ],
         auto_use_on_require => [ qw(0|1) ],
         auto_install_on_require => [ qw(0|1) ],
         exit_on_sigint => [ qw(0|1) ],
         pid => [ qw(metabrik_main_pid) ],
      },
      attributes_default => {
         device => 'eth0',
         uri => 'http://www.example.com',
         target => 'localhost',
         family => 'ipv4',
         protocol => 'tcp',
         ctimeout => 5,
         rtimeout => 5,
         username => $ENV{USER} || 'root',
         hostname => 'localhost',
         domainname => 'example.com',
         port => 80,
         encoding => 'utf8',
         auto_use_on_require => 1,
         auto_install_on_require => 0,
         exit_on_sigint => 0,
         pid => $$,
      },
      commands => {
         sleep => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $homedir = $ENV{HOME} || '/tmp';
   my $datadir = $homedir.'/metabrik';

   return {
      attributes_default => {
         homedir => $homedir,
         datadir => $datadir,
         input => $datadir.'/input.txt',
         output => $datadir.'/output.txt',
         db => $datadir.'/db.db',
         file => $datadir.'/file.txt',
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::Core::Global - core::global Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
