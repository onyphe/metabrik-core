#
# $Id$
#
# core::log Brik
#
package Metabrik::Core::Log;
use strict;
use warnings;

# Breaking.Feature.Fix
our $VERSION = '1.21';
our $FIX = '0';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main core) ],
      attributes => {
         color => [ qw(0|1) ],
         level => [ qw(0|1|2|3) ],
      },
      attributes_default => {
         color => 1,
         level => 1,
      },
      commands => {
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
      },
      require_modules => {
         'Term::ANSIColor' => [ ],
      },
   };
}

sub brik_preinit {
   my $self = shift;

   my $context = $self->context;

   # We replace the current logging Brik by this one,
   # but only after core::context has been created and initialized.
   if (defined($context)) {
      $context->{log} = $self;
      for my $this (keys %{$context->used}) {
         $context->{used}->{$this}->{log} = $self;
      }

      # We have to init this new log Brik, because previous one
      # was already inited at this stage. We have to keep the same init context.
      $self->brik_init or return $self->log->error("brik_preinit: brik_init error");
   }

   return $self->SUPER::brik_preinit(@_);
}

sub brik_init {
   my $self = shift;

   # Makes STDOUT file handle unbuffered
   my $current = select;
   select(STDOUT);
   $|++;
   select($current);

   return $self->SUPER::brik_init(@_);
}

sub _msg {
   my $self = shift;
   my ($brik, $msg) = @_;

   $msg ||= 'undef';

   $brik =~ s/^metabrik:://i;

   return lc($brik).": $msg\n";
}

sub warning {
   my $self = shift;
   my ($msg, $caller) = @_;

   if ($self->color) {
      print Term::ANSIColor::MAGENTA(), "[!] ", Term::ANSIColor::RESET();
   }
   else {
      print "[!] ";
   }

   print $self->_msg(($caller) ||= caller(), $msg);

   return 1;
}

sub error {
   my $self = shift;
   my ($msg, $caller) = @_;

   if ($self->color) {
      print Term::ANSIColor::RED(), "[-] ", Term::ANSIColor::RESET();
   }
   else {
      print "[-] ";
   }

   print $self->_msg(($caller) ||= caller(), $msg);

   # Returning undef is my official way of stating an error occured:
   # Number 0 is for stating a false condition occured, not not error.
   return;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   if ($self->color) {
      print Term::ANSIColor::RED(), "[F] ", Term::ANSIColor::RESET();
   }
   else {
      print "[F] ";
   }

   die($self->_msg(($caller) ||= caller(), $msg));
}

sub info {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 0;

   if ($self->color) {
      print Term::ANSIColor::GREEN(), "[+] ", Term::ANSIColor::RESET();
   }
   else {
      print "[+] ";
   }

   $msg ||= 'undef';

   print "$msg\n";

   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 1;

   if ($self->color) {
      print Term::ANSIColor::YELLOW(), "[*] ", Term::ANSIColor::RESET();
   }
   else {
      print "[*] ";
   }

   print $self->_msg(($caller) ||= caller(), $msg);

   return 1;
}

sub debug {
   my $self = shift;
   my ($msg, $caller) = @_;

   # We have a conflict between the method and the accessor,
   # we have to identify which one is accessed.

   # If no message defined, we want to access the Attribute
   if (! defined($msg)) {
      return $self->{debug};
   }
   else {
      # If $msg is either 1 or 0, we want to set the Attribute
      if ($msg =~ /^(?:1|0)$/) {
         return $self->{debug} = $msg;
      }
      else {
         return 1 unless $self->level > 2;

         if ($self->color) {
            print Term::ANSIColor::CYAN(), "[D] ", Term::ANSIColor::RESET();
         }
         else {
            print "[D] ";
         }

         print $self->_msg(($caller) ||= caller(), $msg);
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Core::Log - core::log Brik

=head1 SYNOPSIS

   use Metabrik::Core::Log;

   my $LOG = Metabrik::Core::Log->new;

=head1 DESCRIPTION

This Brik is the default logging mechanism: output on console. You could write a different logging Brik as long as it respects the API as described in the B<METHODS> paragraph below. You don't need to use this Brik directly. It is auto-loaded by B<core::context> Brik and is stored in its B<log> Attribute.

=head1 ATTRIBUTES

At B<The Metabrik Shell>, just type:

L<get core::log>

=head1 COMMANDS

At B<The Metabrik Shell>, just type:

L<help core::log>

=head1 METHODS

=over 4

=item B<brik_preinit>

=item B<brik_init>

=item B<brik_properties>

=item B<debug>

=item B<error>

=item B<fatal>

=item B<info>

=item B<verbose>

=item B<warning>

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
