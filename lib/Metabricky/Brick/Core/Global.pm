#
# $Id$
#
# Global brick
#
package Metabricky::Brick::Core::Global;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   input
   output
   db
   file
   uri
   target
   ctimeout
   rtimeout
   datadir
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use File::Find;

sub new {
   my $self = shift->SUPER::new(
      datadir => '/tmp',
      @_,
   );

   return $self;
}

sub help {
   print "set core::global input <input>\n";
   print "set core::global output <output>\n";
   print "set core::global db <db>\n";
   print "set core::global file <file>\n";
   print "set core::global uri <uri>\n";
   print "set core::global target <target>\n";
   print "set core::global ctimeout <connection_timeout>\n";
   print "set core::global rtimeout <read_timeout>\n";
   print "set core::global datadir <directory>\n";
}

1;

__END__
