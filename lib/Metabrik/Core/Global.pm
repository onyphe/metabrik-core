#
# $Id$
#
# core::global Brik
#
package Metabrik::Core::Global;
use strict;
use warnings;

our $VERSION = '1.20.0';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main core) ],
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
         repository => [ qw(repository) ],
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

=head1 SYNOPSIS

   use Metabrik::Core::Global;

   my $GLO = Metabrik::Core::Global->new;

=head1 DESCRIPTION

This Brik holds some global Attributes like timeout values, paths or default network interface. You don't need to use this Brik directly. It is auto-loaded by B<core::context> Brik and is stored in its B<global> Attribute.

=head1 ATTRIBUTES

At B<The Metabrik Shell>, just type:

L<get core::global>

=head1 COMMANDS

At B<The Metabrik Shell>, just type:

L<help core::global>

=head1 METHODS

=over 4

=item B<brik_properties>

Class Properties for the Brik. See B<Metabrik>.

=item B<brik_use_properties>

Instanciated Properties when the Brik is first used. See B<use> Command.

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
