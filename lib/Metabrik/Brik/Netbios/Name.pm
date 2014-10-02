#
# $Id$
#
# netbios::name Brik
#
package Metabrik::Brik::Netbios::Name;
use strict;
use warnings;

use base qw(Metabrik::Brik);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return {
      'Net::NBName' => [],
   };
}

sub help {
   return {
      'run:nodestatus' => '<ip>',
   };
}

sub nodestatus {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      return $self->log->info($self->help_run('nodestatus'));
   }

   my $nb = Net::NBName->new;
   if (! $nb) {
      return $self->log->error("can't new() Net::NBName: $!");
   }

   my $ns = $nb->node_status($ip);
   if ($ns) {
      print $ns->as_string;
      return $nb;
   }

   print "no response\n";

   return $nb;
}

1;

__END__