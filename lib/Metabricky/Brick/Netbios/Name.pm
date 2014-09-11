#
# $Id$
#
# Net::NBName brick
#
package Metabricky::Brick::Netbios::Name;
use strict;
use warnings;

use base qw(Metabricky::Brick);

__PACKAGE__->cgBuildIndices;
#__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::NBName;

sub help {
   print "run netbios::name nodestatus <ip>\n";
}

sub nodestatus {
   my $self = shift;
   my ($ip) = @_;

   if (! defined($ip)) {
      die($self->help."\n");
   }

   my $nb = Net::NBName->new;
   if (! $nb) {
      die("can't new() Net::NBName: $!\n");
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