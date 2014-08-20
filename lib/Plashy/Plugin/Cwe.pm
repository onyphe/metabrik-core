#
# $Id$
#
# CWE plugin
#
package Plashy::Plugin::Cwe;
use strict;
use warnings;

use base qw(Plashy::Plugin);

our @AS = qw(
   file
   xml
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Plashy::Plugin::Slurp;
use Plashy::Plugin::Sqlite;

use Data::Dumper;

sub help {
   print "run cwe update\n";
   print "run cwe load\n";
   print "run cwe search <pattern>\n";
}

sub default_values {
   my $self = shift;

   return {
      file => $self->global->datadir."/2000.xml",
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->global->datadir;

   # XXX: dirty for now
   `wget --output-document=$datadir/2000.xml.zip http://cwe.mitre.org/data/xml/views/2000.xml.zip`;
   `unzip $datadir/2000.xml.zip -d $datadir/`;

   return 1;
}

sub load {
   my $self = shift;

   my $file = $self->file;

   my $slurp = Plashy::Plugin::Slurp->new(
      file => $file,
   );

   my $xml = $slurp->xml;

   return $self->xml($xml);
}

sub _view {
   my $self = shift;
   my ($h) = @_;

   my $buf = "ID: ".$h->{id}."\n";
   $buf .= "Name: ".$h->{name}."\n";
   $buf .= "Status: ".$h->{status}."\n";
   $buf .= "URL: ".$h->{url}."\n";
   $buf .= "Description Summary: ".($h->{description_summary} || '(undef)')."\n";
   $buf .= "Likelihood of Exploit: ".($h->{likelihood_of_exploit} || '(undef)')."\n";
   $buf .= "Relationships:\n";
   for my $r (@{$h->{relationships}}) {
      $buf .= "   ".$r->{relationship_nature}." ".$r->{relationship_target_form}." ".
              $r->{relationship_target_id}."\n";
   }

   return $buf;
}

sub search {
   my $self = shift;
   my ($pattern) = @_;

   if (!defined($self->xml)) {
      die("run cwe load\n");
   }

   if (!defined($pattern)) {
      die("run cwe search <pattern>\n");
   }

   my $xml = $self->xml;

   my @list = ();
   if (exists $xml->{Weaknesses} && exists $xml->{Weaknesses}->{Weakness}) {
      my $weaknesses = $xml->{Weaknesses}->{Weakness};
      for my $w (@$weaknesses) {
         my $id = $w->{ID};
         my $name = $w->{Name};
         my $status = $w->{Status};
         my $likelihood_of_exploit = $w->{Likelihood_of_Exploit};
         my $weakness_abstraction = $w->{Weakness_Abstraction};
         my $description_summary = $w->{Description}->{Description_Summary};
         if (defined($description_summary)) {
            $description_summary =~ s/\s*\n\s*/ /gs;
         }
         my $extended_description = $w->{Description}->{Extended_Description}->{Text};
         if (defined($extended_description)) {
            $extended_description =~ s/\s*\n\s*/ /gs;
         }
         my $relationships = $w->{Relationships}->{Relationship};
         # Potential_Mitigations
         # Affected_Resources

         my @relationships = ();
         if (defined($relationships)) {
            #print "DEBUG Processing ID [$id]\n";
            #print "DEBUG ".ref($relationships)."\n";
            # $relationships can be ARRAY or HASH, we convert to ARRAY
            if (ref($relationships) eq 'HASH') {
               $relationships = [ $relationships ];
            }
            for my $r (@$relationships) {
               my $relationship_nature = $r->{Relationship_Nature};
               my $relationship_target_id = $r->{Relationship_Target_ID};
               my $relationship_target_form = $r->{Relationship_Target_Form};
               push @relationships, {
                  relationship_nature => $relationship_nature,
                  relationship_target_id => $relationship_target_id,
                  relationship_target_form => $relationship_target_form,
               };
            }
         }

         my $this = {
            id => $id,
            name => $name,
            status => $status,
            url => 'http://cwe.mitre.org/data/definitions/'.$id.'.html',
            likelihood_of_exploit => $likelihood_of_exploit,
            description_summary => $description_summary,
            relationships => \@relationships,
         };

         if ($name =~ /$pattern/i || $id =~ /^$pattern$/) {
            #print Dumper($this)."\n";
            print $self->_view($this)."\n";
            push @list, $this;
         }
      }
   }

   return \@list;
}

1;

__END__
