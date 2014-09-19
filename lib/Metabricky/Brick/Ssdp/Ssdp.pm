#
# $Id: Ssdp.pm 89 2014-09-17 20:29:29Z gomor $
#
# SSDP brick
#
package Metabricky::Brick::Ssdp::Ssdp;
use strict;
use warnings;

use base qw(Metabricky::Brick);

our @AS = qw(
   device
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub revision {
   return '$Revision$';
}

sub require_modules {
   return [
      'IO::Socket::Multicast',
   ];
}

sub help {
   return [
      'set ssdp::ssdp device <device>',
      'run ssdp::ssdp discover',
   ];
}

sub discover {
   my $self = shift;

   if (! defined($self->device)) {
      return $self->log->info("set ssdp::ssdp device <device>");
   }

   my $device = $self->device;

   my $ssdpAddr = '239.255.255.250';
   my $ssdpPort = 1900;

   my $m = IO::Socket::Multicast->new(
      Proto     => 'udp',
      #LocalPort => 1900,
      PeerDest  => $ssdpAddr,
      PeerPort  => $ssdpPort,
      ReuseAddr => 1,
   ) or return $self->log->error("multicast: $!");
   $m->mcast_if($device);

   my $ssdpSearch =
      "M-SEARCH * HTTP/1.1\r\n".
      "Host: $ssdpAddr:$ssdpPort\r\n".
      "Man: \"ssdp:discover\"\r\n".
      "ST: upnp:rootdevice\r\n".
      "MX: 3\r\n".
      "\r\n".
      "";

   # XXX: use IO::Select to handle timeout

   my $data;
   for (1..3) {
      $m->mcast_send($ssdpSearch, "$ssdpAddr:$ssdpPort") or $self->log->error("mcast_send: $!");
      print "[+] Request sent\n";
      $m->recv($data, 1024);
      if ($data && length($data)) {
         print "[+] Answer received\n";
         last;
      }
      sleep(1);
   }

   print $data;

   return $data;
}

1;

__END__
