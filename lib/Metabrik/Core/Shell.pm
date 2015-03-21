#
# $Id$
#
# core::shell Brik
#
package Metabrik::Core::Shell;
use strict;
use warnings;

our $VERSION = '1.09';

use base qw(Term::Shell Metabrik);

use IO::All;

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(core main shell) ],
      attributes => {
         echo => [ qw(0|1) ],
         help_show_brik_commands => [ qw(0|1) ],
         help_show_brik_attributes => [ qw(0|1) ],
         comp_show_brik_attributes => [ qw(0|1) ],
         comp_show_brik_commands => [ qw(0|1) ],
         get_show_brik_attributes => [ qw(0|1) ],
         help_show_inherited => [ qw(0|1) ],
         comp_show_inherited => [ qw(0|1) ],
         # These are used by Term::Shell
         #path_home => [ qw(directory) ],
         #path_cwd => [ qw(directory) ],
         #prompt => [ qw(string) ],
         #_aliases => [ qw(INTERNAL) ],
         #_executables => [ qw(INTERNAL) ],
      },
      attributes_default => {
         echo => 1,
         help_show_brik_commands => 0,
         help_show_brik_attributes => 0,
         comp_show_brik_attributes => 0,
         comp_show_brik_commands => 0,
         get_show_brik_attributes => 0,
         help_show_inherited => 0,
         comp_show_inherited => 0,
      },
      commands => {
         splash => [ ],
         pwd => [ ],
         get_available_help => [ ],
         # Term::Shell stuff
         cmd => [ qw(Cmd) ],
         cmdloop => [ ],
         run_use => [ qw(Brik) ],
         run_help => [ qw(Brik) ],
         run_set => [ qw(Brik Attribute Value) ],
         run_get => [ qw(Brik) ],
         run_run => [ qw(Brik Command) ],
         run_alias => [ qw(alias Cmd) ],
         run_cd => [ qw(directory) ],
         run_code => [ qw(Code) ],
         run_exit => [ ],
      },
      require_modules => {
         'Data::Dump' => [ qw(dump) ],
         'File::HomeDir' => [ ],
         'Cwd' => [ ],
         'PPI' => [ ],
      },
   };
}

sub new {
   # Call Term::Shell new()
   my $self = shift->SUPER::new(@_);

   # Call Metabrik new()
   $self->Metabrik::new(@_);

   # We have to set of default_attributes again normally called by Brik::new():
   # Otherwise default attributes are not set properly because of Perl inheritance scheme
   $self->brik_set_default_attributes;

   # Now write Term::Shell default values we gave, like context, global, log, ...
   my %h = @_;
   for my $k (keys %h) {
      $self->{$k} = $h{$k};
   }

   return $self;
}

sub brik_init {
   my $self = shift;

   # Allow user to break out of multiline mode or run Commands
   # Note: Gnu readline() is blocking SIGs, we have to hit enter so 
   #       Ctrl+C is executed.
   $SIG{INT} = sub {
      $self->debug && $self->log->debug("SIGINT: captured for pid[$$] ".
         ($$ == $self->global->pid ? '(main process)' : '')
      );
      $self->_update_prompt;
      if ($self->global->exit_on_sigint) {
         $self->run_exit;
      }
      return 1;
   };

   # Gather executable files from PATH
   my @path = split(':', ($ENV{PATH} || ''));
   my %executables = ();
   for my $path (@path) {
      my @files = ();
      eval {
         @files = io($path)->all_files;
      };
      if ($@) {
         chomp($@);
         $self->debug && $self->log->debug("brik_init: $path: all_files: $@");
         next;
      };
      for my $file (@files) {
         if ($file->is_executable) {
            my $filename = $file->filename;
            $executables{$filename}++;

            # Without a handler, we would not be able to autoload the run Command
            $self->add_handler("run_$filename");
         }
      }
   }

   $self->{_executables} = \%executables;

   return $self->SUPER::brik_init(@_);
}

sub splash {
   my $self = shift;

   my $con = $self->context;

   my $version = $con->run('core::global', 'brik_version');

   my $available_count = keys %{$con->available};
   my $used_count = keys %{$con->used};

   # ASCII art courtesy: http://patorjk.com/software/taag/#p=testall&f=Graffiti&t=MetabriK
   print<<EOF

        ███▄ ▄███▓▓█████▄▄▄█████▓ ▄▄▄       ▄▄▄▄    ██▀███   ██▓ ██ ▄█▀
       ▓██▒▀█▀ ██▒▓█   ▀▓  ██▒ ▓▒▒████▄    ▓█████▄ ▓██ ▒ ██▒▓██▒ ██▄█▒
       ▓██    ▓██░▒███  ▒ ▓██░ ▒░▒██  ▀█▄  ▒██▒ ▄██▓██ ░▄█ ▒▒██▒▓███▄░
       ▒██    ▒██ ▒▓█  ▄░ ▓██▓ ░ ░██▄▄▄▄██ ▒██░█▀  ▒██▀▀█▄  ░██░▓██ █▄
       ▒██▒   ░██▒░▒████▒ ▒██▒ ░  ▓█   ▓██▒░▓█  ▀█▓░██▓ ▒██▒░██░▒██▒ █▄
       ░ ▒░   ░  ░░░ ▒░ ░ ▒ ░░    ▒▒   ▓▒█░░▒▓███▀▒░ ▒▓ ░▒▓░░▓  ▒ ▒▒ ▓▒
       ░  ░      ░ ░ ░  ░   ░      ▒   ▒▒ ░▒░▒   ░   ░▒ ░ ▒░ ▒ ░░ ░▒ ▒░
       ░      ░      ░    ░        ░   ▒    ░    ░   ░░   ░  ▒ ░░ ░░ ░
              ░      ░  ░              ░  ░ ░         ░      ░  ░  ░
                                                 ░

--[ Welcome to Metabrik - Knowledge is in your head, Detail is in the code ]--
--[ Briks available: $available_count ]--
--[ Briks used: $used_count ]--
--[ Version $version ]--

    There is a Brik for that.

EOF
;

   return 1;
}

sub pwd {
   my $self = shift;

   return $self->{path_cwd};
}

sub get_available_help {
   my $self = shift;

   my @used = sort { $a cmp $b } keys %{$self->context->used};
   my @aliases = sort { $a cmp $b } keys %{$self->{_aliases}};
   my @commands = sort { $a cmp $b } keys %{$self->brik_commands};

   # Skip class functions
   @commands = grep (!/^brik_/, @commands);

   # Remove leading run_ string
   for (@aliases, @commands) {
      s/^run_//;
   }

   return { briks => \@used, aliases => \@aliases, commands => \@commands };
}

#
# Term::Shell stuff
#
our $AUTOLOAD;

sub AUTOLOAD {
   my $self = shift;
   my (@args) = @_;

   $self->debug && $self->log->debug("autoload[$AUTOLOAD]");

   if ($AUTOLOAD !~ /^Metabrik::Core::Shell::run_/) {
      return 1;
   }

   (my $command = $AUTOLOAD) =~ s/^Metabrik::Core::Shell:://;

   $self->debug && $self->log->debug("command[$command] args[@args]");

   #my $aliases = $self->_aliases;
   my $aliases = $self->{_aliases};
   if (exists($aliases->{$command})) {
      my $cmd = $aliases->{$command};
      return $self->cmd(join(' ', $cmd, @args));
   }

   my $context = $self->context;

   if ($context->is_used('shell::command')) {
      (my $exec = $command) =~ s/^run_//;
      my $executables = $self->{_executables};
      if (exists($executables->{$exec})) {
         my $cmd = "run shell::command system $exec";
         return $self->cmd(join(' ', $cmd, @args));
      }
   }

   return 1;
}

# Converts Windows path
sub _convert_path {
   my ($path) = @_;

   $path =~ s/\\/\//g;

   return $path;
}

#
# Term::Shell::main stuff
#
use Cwd;
use File::HomeDir;

sub _update_path_home {
   my $self = shift;

   #$self->path_home(_convert_path(home()));
   $self->{path_home} = _convert_path(File::HomeDir->my_home);

   return 1;
}

sub _update_path_cwd {
   my $self = shift;

   my $cwd = _convert_path(Cwd::getcwd());
   $self->debug && $self->log->debug("cwd [$cwd]");
   #my $home = $self->path_home;
   my $home = $self->{path_home};
   $self->debug && $self->log->debug("home [$home]");
   $cwd =~ s/^$home/~/;

   #$self->path_cwd($cwd);
   $self->{path_cwd} = $cwd;

   return 1;
}

sub _update_prompt {
   my $self = shift;
   my ($prompt) = @_;

   if (defined($prompt)) {
      #$self->prompt($prompt);
      $self->{prompt} = $prompt;
   }
   else {
      #my $cwd = $self->path_cwd;
      my $cwd = $self->{path_cwd};

      my $prompt = "Meta:$cwd> ";
      #my $prompt = "Meta> ";
      if ($^O =~ /win32/i) {
         $prompt =~ s/> /\$ /;
      }
      elsif ($< == 0) {
         $prompt =~ s/> /# /;
      }

      #$self->prompt($prompt);
      $self->{prompt} = $prompt;
   }

   return 1;
}

sub init {
   my $self = shift;

   $|++;

   $self->_update_path_home;
   $self->_update_path_cwd;
   $self->_update_prompt;

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   # Force Commands to be entered entirely to avoid ambiguity.
   # Example: type 'my' will result in excuting Perl code, and not 'mymeta-cpanfile'.
   $self->{API}{match_uniq} = 0;

   return $self;
}

sub prompt_str {
   my $self = shift;

   #return $self->prompt;
   return $self->{prompt};
}

sub cmd_is_complete {
   my $self = shift;
   my ($lines) = @_;

   my $string = join("\n", @$lines);

   my $document = PPI::Document->new(\$string);
   if (! $document) {
      return $self->log->error("cmd_complete: cannot parse Perl string");
   }

   # Courtesy of Perl::Shell complete() function
   my $r = $document->find_any(sub {
      $_[1]->isa('PPI::Structure') and ! $_[1]->finish
   });

   return $r ? 0 : 1;
}

sub cmd_to_code {
   my $self = shift;
   my ($line) = @_;

   while ($line =~ /'\s*(?:use|set|get|run)\s.*?'/) {
      #$self->log->info("cmd_to_code: before: [$line]");
      $line =~ s/'\s*((?:use|set|get|run)\s.*?)\s*'/\$SHE->cmd("$1")/;
      #$self->log->info("cmd_to_code: after: [$line]");

      $self->debug && $self->log->debug("cmd_to_code: [$line]");
   }

   return $line;
}

sub process_line {
   my $self = shift;
   my ($line, $lines) = @_;

   $self->debug && $self->log->debug("process_line: [$line]");

   # Skip comments
   if ($line =~ /^\s*#/) {
      return 0;
   }
   # Skip blank lines
   if ($line =~ /^\s*$/) {
      return 0;
   }

   push @$lines, $line;

   # If a closure is open, we are in multiline mode
   if (! $self->cmd_is_complete($lines)) {
      # If it looks like a Metabrik command, we rewrite it to a Perl code string
      $lines->[-1] = $self->cmd_to_code($line);
      $self->_update_prompt('.. ');
      return 1;
   }

   $self->debug && $self->log->debug("process_line: lines[@$lines]");

   $self->cmd(join('', @$lines));

   $self->_update_prompt;

   return 0;
}

sub cmdloop {
   my $self = shift;
   my ($lines) = @_;

   my @lines = ();

   # User provided lines to execute (script)
   if (defined($lines)) {
      for my $line (@$lines) {
         if ($self->process_line($line, \@lines)) {
            next;   # We are in multiline mode
         }
         else {
            @lines = ();  # Command is complete, we ran it and now reset line buffer.
         }

         last if $self->{stop};
      }
   }
   # Or we are in interactive mode (shell)
   else {
      $self->{stop} = 0;
      $self->preloop;

      while (defined(my $line = $self->readline($self->prompt_str))) {
         if ($self->process_line($line, \@lines)) {
            next;   # We are in multiline mode
         }
         else {
            @lines = ();  # Command is complete, we ran it and now reset line buffer.
         }

         last if $self->{stop};
      }

      $self->run_exit;

      return $self->postloop;
   }

   return 1;
}

#
# Term::Shell::run stuff
#
sub run_exit {
   my $self = shift;

   my $context = $self->context;

   if ($context->is_used('shell::history')) {
      $context->run('shell::history', 'write');
   } 

   return $self->stoploop;
}

sub comp_exit {
   return ();
}

sub run_alias {
   my $self = shift;
   my ($alias, @cmd) = @_;

   #my $aliases = $self->_aliases;
   my $aliases = $self->{_aliases};

   if (! defined($alias)) {
      for my $this (sort { $a cmp $b } keys %$aliases) {
         ($alias = $this) =~ s/^run_//;
         $self->log->info(sprintf("%-10s \"%s\"", $alias, $aliases->{$this}));
      }

      return 1;
   }
   elsif (length($alias) && @cmd == 0) {
      $alias =~ s/^run_//;
      $self->log->info(sprintf("%-10s \"%s\"", $alias, $aliases->{"run_$alias"}));

      return 1;
   }

   $aliases->{"run_$alias"} = join(' ', @cmd);
   #$self->_aliases($aliases);
   $self->{_aliases} = $aliases;

   $self->add_handler("run_$alias");

   return 1;
}

sub comp_alias {
   return ();
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   if (defined($dir)) {
      if ($dir =~ /^~$/) {
         #$dir = $self->path_home;
         $dir = $self->{path_home};
      }
      if (! -d $dir) {
         return $self->log->error("cd: $dir: can't cd to this");
      }
      chdir($dir);
      $self->_update_path_cwd;
   }
   else {
      #chdir($self->path_home);
      chdir($self->{path_home});
      $self->_update_path_cwd;
   }

   $self->_update_prompt;

   return 1;
}

sub comp_cd {
   my $self = shift;
   my ($word, $line, $start) = @_;

   return $self->catch_comp_sub($word, $start, $line);
}

sub run_code {
   my $self = shift;

   my $context = $self->context;

   my $line = $self->line;
   $line =~ s/^code\s+//;

   if (! length($line)) {
      return $self->log->info('code <code>');
   }

   $self->debug && $self->log->debug("run_code: code[$line]");

   my $r;
   eval {
      # So we can interrupt the do($line) execution
      local $SIG{INT} = sub {
         $self->debug && $self->log->debug("run_code: SIG received");
         if ($self->global->exit_on_sigint) {
            $self->debug && $self->log->debug("run_code: exiting");
            $self->run_exit;
         }
         die("interrupted by user\n");
      };
      $r = $context->do($line);
   };
   if (! defined($r)) {
      return $self->log->error("run_code: unable to execute Code [$line]");
   }

   if ($self->echo) {
      $self->page(Data::Dump::dump($r)."\n");
   }

   return $r;
}

sub comp_code {
   my $self = shift;
   my ($word, $line, $start) = @_;

   return $self->catch_comp_sub($word, $start, $line);
}

sub run_use {
   my $self = shift;
   my ($brik, @args) = @_;

   my $context = $self->context;

   if (! defined($brik)) {
      return $self->log->info('use <brik>');
   }

   my $r;
   # If Brik starts with a minuscule, we want to use Brik in Metabrik sens.
   # Otherwise, it is a use command in the Perl sens.
   if ($brik =~ /^[a-z]/ && $brik =~ /::/) {
      $r = $context->use($brik) or return;
      if ($r) {
         $self->log->verbose("use: Brik [$brik] success");
      }
   }
   else {
      return $self->run_code($brik, @args);
   }

   return $r;
}

sub comp_use {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find available Briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my $available = $context->available;
      if ($self->debug && ! defined($available)) {
         $self->log->debug("\ncomp_use: can't fetch available Briks");
         return ();
      }

      for my $a (keys %$available) {
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_help {
   my $self = shift;
   my ($arg) = @_;

   my $context = $self->context;

   my $help = $self->get_available_help;
   my %aliases = map { $_ => 1 } @{$help->{aliases}};
   my %briks = map { $_ => 1 } @{$help->{briks}};
   my %commands = map { $_ => 1 } @{$help->{commands}};

   # Print the list of available Briks, Aliases, Commands
   if (! defined($arg)) {
      $self->log->info("For more help, print help <Command>:");
      $self->log->info(" ");

      for my $this (@{$help->{briks}}) {
         $self->log->info("   $this - Brik");
      }

      for my $this (@{$help->{aliases}}) {
         $self->log->info("   $this - Alias");
      }

      for my $this (@{$help->{commands}}) {
         $self->log->info("   $this - Command");
      }

      return 1;
   }
   else {
      # Help for a Brik
      if (exists($briks{$arg})) {
         my $used_brik = $context->used->{$arg};

         my $attributes = $used_brik->brik_attributes;
         my $commands = $used_brik->brik_commands;

         if (! $self->help_show_inherited) {
            $attributes = $used_brik->brik_properties->{attributes};
            $commands = $used_brik->brik_properties->{commands};
         }

         my $brik_attributes = Metabrik->brik_properties->{attributes};
         my $brik_commands = Metabrik->brik_properties->{commands};

         for my $attribute (keys %$attributes) {
            if (! $context->get('core::shell', 'help_show_brik_attributes')) {
               next if exists($brik_attributes->{$attribute});
            }
            my $help = $used_brik->brik_help_set($attribute);
            $self->log->info($help) if defined($help);
         }

         for my $command (keys %$commands) {
            if (! $context->get('core::shell', 'help_show_brik_commands')) {
               next if exists($brik_commands->{$command});
            }
            my $help = $used_brik->brik_help_run($command);
            $self->log->info($help) if defined($help);
         }
      }
      # Help for a Command
      elsif (exists($commands{$arg})) {
         for my $this (sort { $a cmp $b } keys %commands) {
            return $self->log->info("$arg - core::shell Command, see 'help core::shell'");
         }
      }
      # Help for an Alias
      elsif (exists($aliases{$arg})) {
         return $self->log->info("$arg - no help for Aliases");
      }
      else {
         return $self->log->info("Command [$arg] not found");
      }
   }

   return 1;
}

sub comp_help {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find help for used Briks by using completion
   if ($count == 1 || ($count == 2 && length($word) > 0)) {
      my $help = $self->get_available_help;
      for my $a (@{$help->{briks}}, @{$help->{aliases}}, @{$help->{commands}}) {
         next unless length($a);
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_set {
   my $self = shift;
   my ($brik, $attribute, $value) = @_;

   my $context = $self->context;

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info("set <brik> <attribute> <value>");
   }

   my $r = $context->set($brik, $attribute, $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute [$attribute] for Brik [$brik]");
   }

   return $r;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   # Completion is for used Briks only
   my $used = $context->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_set: can't fetch used Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Attributes
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_attributes = Metabrik->brik_properties->{attributes};
      my $attributes = $used->{$brik}->brik_attributes;

      if (! $self->comp_show_inherited) {
         $attributes = $used->{$brik}->brik_properties->{attributes};
      }

      for my $attribute (keys %$attributes) {
         if (! $context->get('core::shell', 'comp_show_brik_attributes')) {
            next if exists($brik_attributes->{$attribute});
         }
         push @comp, $attribute;
      }
   }
   # We want to complete entered Attribute
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_attributes = Metabrik->brik_properties->{attributes};
      my $attributes = $used->{$brik}->brik_attributes;

      if (! $self->comp_show_inherited) {
         $attributes = $used->{$brik}->brik_properties->{attributes};
      }

      for my $attribute (keys %$attributes) {
         if (! $context->get('core::shell', 'comp_show_brik_attributes')) {
            next if exists($brik_attributes->{$attribute});
         }
         if ($attribute =~ /^$word/) {
            push @comp, $attribute;
         }
      }
   }
   # Else, default completion method on remaining word
   else {
      return $self->catch_comp_sub($word, $start, $line);
   }

   return @comp;
}

sub run_get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   my $context = $self->context;

   # get is called without args, we display everything
   if (! defined($brik)) {
      my $used = $context->used or return;

      for my $brik (sort { $a cmp $b } keys %$used) {
         my $attributes = $used->{$brik}->brik_attributes or next;
         for my $attribute (sort { $a cmp $b } keys %$attributes) {
            if (! $context->get('core::shell', 'get_show_brik_attributes')) {
               if ($attribute =~ /^(?:shell|context|log|global|init_done|debug)$/) {
                  next;
               }
            }
            $self->log->info("$brik $attribute ".$context->get($brik, $attribute));
         }
      }
   }
   # get is called with only a Brik as an arg, we show its Attributes
   elsif (defined($brik) && ! defined($attribute)) {
      my $used = $context->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      my %printed = ();
      my $attributes = $used->{$brik}->brik_attributes;
      for my $attribute (sort { $a cmp $b } keys %$attributes) {
         if (! $context->get('core::shell', 'get_show_brik_attributes')) {
            if ($attribute =~ /^(?:shell|context|log|global|init_done|debug)$/) {
               next;
            }
         }
         my $print = "$brik $attribute ".$context->get($brik, $attribute);
         $self->log->info($print) if ! exists($printed{$print});
         $printed{$print}++;
      }
   }
   # get is called with is a Brik and an Attribute
   elsif (defined($brik) && defined($attribute)) {
      my $used = $context->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      if (! $used->{$brik}->brik_has_attribute($attribute)) {
         return $self->log->error("get: Attribute [$attribute] does not exist for Brik [$brik]");
      }

      $self->log->info("$brik $attribute ".$context->get($brik, $attribute));
   }

   return 1;
}

sub comp_get {
   my $self = shift;

   return $self->comp_set(@_);
}

sub run_run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   my $context = $self->context;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->info("run <brik> <command> [ <arg1> <arg2> .. <argN> ]");
   }

   my $r = $context->run($brik, $command, @args);
   if (! defined($r)) {
      return $self->log->error("run: unable to execute Command [$command] for Brik [$brik]");
   }

   if ($self->echo) {
      $self->page(Data::Dump::dump($r)."\n");
   }

   return $r;
}

sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("comp_run: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Completion is for used Briks only
   my $used = $context->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_run: can't fetch used Briks");
      return ();
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Commands
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_commands = Metabrik->brik_properties->{commands};
      my $commands = $used->{$brik}->brik_commands;

      if (! $self->comp_show_inherited) {
         $commands = $used->{$brik}->brik_properties->{commands};
      }

      for my $command (keys %$commands) {
         if (! $context->get('core::shell', 'comp_show_brik_commands')) {
            next if exists($brik_commands->{$command});
         }
         push @comp, $command;
      }
   }
   # We want to complete entered Command and Attributes
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_commands = Metabrik->brik_properties->{commands};
      my $commands = $used->{$brik}->brik_commands;

      if (! $self->comp_show_inherited) {
         $commands = $used->{$brik}->brik_properties->{commands};
      }

      for my $command (keys %$commands) {
         if (! $context->get('core::shell', 'comp_show_brik_commands')) {
            next if exists($brik_commands->{$command});
         }
         if ($command =~ /^$word/) {
            push @comp, $command;
         }
      }
   }
   # Else, default completion method on remaining word
   else {
      return $self->catch_comp_sub($word, $start, $line);
   }

   return @comp;
}

#
# Term::Shell::catch stuff
#
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   # Default to execute Perl commands
   return $self->run_code(@args);
}

# Taken from file::find Brik, to make core::shell independant from it.
sub _file_find {
   my $self = shift;
   my ($path) = @_;

   my @dirs = ();
   my @files = ();

   my $dirpattern = '.*';
   my $filepattern = '.*';

   # Handle finding of directories
   my @tmp_dirs = ();
   eval {
      @tmp_dirs = io($path)->all_dirs;
   };
   if ($@) {
      if ($self->debug) {
         chomp($@);
         $self->log->debug("all: $path: dirs: $@");
      }
      return { directories => [], files => [] };
   }
   for my $this (@tmp_dirs) {
      if ($this =~ /$dirpattern/) {
         push @dirs, "$this/";
      }
   }

   # Handle finding of files
   my @tmp_files = ();
   eval {
      @tmp_files = io($path)->all_files;
   };
   if ($@) {
      if ($self->debug) {
         chomp($@);
         $self->log->debug("all: $path: files: $@");
      }
      return { directories => [], files => [] };
   }
   for my $this (@tmp_files) {
      if ($this =~ /$filepattern/) {
         push @files, "$this";
      }
   }

   @dirs = map { s/^\.\///; $_ } @dirs;  # Remove leading dot slash
   @files = map { s/^\.\///; $_ } @files;  # Remove leading dot slash

   return {
      directories => \@dirs,
      files => \@files,
   };
}

# 1. $word - The word the user is trying to complete.
# 2. $line - The line as typed by the user so far.
# 3. $start - The offset into $line where $word starts.
sub catch_comp_sub {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my $context = $self->context;

   my $attribs = $self->term->Attribs;
   $attribs->{completion_suppress_append} = 1;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("catch_comp: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Be default, we will read the current directory
   if (! length($word)) {
      $word = '.';
   }

   $self->debug && $self->log->debug("catch_comp: DEFAULT: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   my @comp = ();

   # We don't use $word here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $context->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$word/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      #my $home = $self->path_home;
      my $home = $self->{path_home};
      $word =~ s/^~/$home/;

      if ($word =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }

      #$self->debug && $self->log->debug("path[$path]");

      my $found = $self->_file_find($path);

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$word/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

# 1. $word - The word the user is trying to complete.
# 2. $line - The line as typed by the user so far.
# 3. $start - The offset into $line where $word starts.
# The true default completion method for Term::Shell when no comp_* matched.
# Ugly, we should merge with comp_catch_sub().
# Bug from Term::Shell: $start is not an offset in that case.
sub catch_comp {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my $context = $self->context;

   my $attribs = $self->term->Attribs;
   $attribs->{completion_suppress_append} = 1;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("catch_comp: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Be default, we will read the current directory
   if (! length($start)) {
      $start = '.';
   }

   $self->debug && $self->log->debug("catch_comp: DEFAULT: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   my @comp = ();

   # We don't use $start here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $context->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      #my $home = $self->path_home;
      my $home = $self->{path_home};
      $start =~ s/^~/$home/;

      if ($start =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }
      $self->debug && $self->log->debug("path[$path]");

      my $found = $self->_file_find($path);

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

1;

__END__

=head1 NAME

Metabrik::Core::Shell - core::shell Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
