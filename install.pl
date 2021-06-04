#!/usr/bin/env perl

use Cwd qw[abs_path];
use File::Basename qw[dirname basename];
use File::Spec;
use File::Find qw[find];

my $diff = grep {/^-+d(iff)?$/i} @ARGV;
my $f = grep {/^-+f(orce)?$/i} @ARGV;
@ARGV = grep { !/^-/ } @ARGV;

my $selfName = basename($0);
my $dotfileOrigin = abs_path(dirname($0));
my $baseOrigin = $dotfileOrigin . '/home';
my $destination = abs_path(shift || $ENV{HOME});
s!//+!/!gs foreach ($dotfileOrigin, $baseOrigin, $destination);
s!/*$!/!gs foreach ($dotfileOrigin, $baseOrigin, $destination);
my $dotfileLink = $destination . '.dotfiles';

symlink($dotfileOrigin, $dotfileLink) unless(-e $dotfileLink);

chomp(my $uname = lc(`uname`));
my $origin;
foreach my $suffix (('', '-'.$uname)) {
  ($origin = $baseOrigin) =~ s!/?$!${suffix}/!;
  next unless -d $origin;
  print "Origin: $origin\n";
  print "Destination: $destination\n";

  if($diff) {
    my @cmd = ();
    find({wanted => sub{compare_file(\@cmd)}, no_chdir => 1}, $origin);
    if(@cmd) {
      my $cmd = '(' . join(' ; ', @cmd) . ') | less';
      system $cmd;
    } else {
      print "No differences.\n";
    }
  } else {
    find({wanted => \&symlink_file, no_chdir => 1}, $origin);
    find({wanted => \&remove_file, no_chdir => 1}, map { "${destination}$_" } (qw[bin]) );
  }
}


sub symlink_file {
  next if -d && ! m!/.atom$!;
  next if m!/.atom/.+!;
  next if m!/\.git/|\.DS_Store!;
  my $sf = $_;
  (my $fn = $sf) =~ s!$origin!!;
  next if $fn eq $selfName;
  my $df = $destination.$fn;
  my $dd = dirname($df);
  $sf = File::Spec->abs2rel($sf, dirname($df));
  $sf =~ s!^([^\./])!./$1!;
  if((-e $df or -l $df) && $f) {
    print "WARNING: $df exists and -f(orce) was specified. Deleting!\n";
    unlink $df;
  }
  if(-l $df) {
    my $dfl = readlink($df);
    print "$df is already symlinked (to $dfl). Not replacing.\n" unless $dfl eq $sf;
    next;
  } elsif(-f $df) {
    if(&identical_contents($_, $df)) {
      print "$df contains the same contents as $sf. Replacing with symlink.\n";
      unlink $df;
    } else {
      print "$df exists. Not replacing.\n";
      next;
    }
  }
  unless(-d $dd) {
    print "$dd does not exist. Creating...\n";
    mkdir $dd;
  }
  if(-e $df) {
    print "$df exists. Not replacing.\n";
    next;
  } else {
    print "Linking $df to $sf...\n";
    symlink($sf, $df);
  }
}

sub compare_file {
  next if -d;
  next if m!/\.git/|\.DS_Store!;
  my $sf = $_;
  (my $fn = $sf) =~ s!$origin!!;
  next if $fn eq $selfName;
  my $df = $destination.$fn;
  my $dd = dirname($df);
  $sf = File::Spec->abs2rel($sf, dirname($df));
  $sf =~ s!^([^\./])!./$1!;
  if(-f $df) {
    unless(&identical_contents($_, $df)) {
      push @{$_[0]}, qq[diff -atbBU5 "$_" "$df"];
    }
  }
}

sub remove_file {
  next unless -l;
  my $df = readlink($_);
  my $sf = abs_path(File::Spec->rel2abs($df, dirname($_)));
  next unless $sf =~ /^$origin/;
  next if -f $sf;
  print "$_ links to non-existant $sf. Removing.\n";
  unlink $_;
}

sub identical_contents {
  my($left, $right) = @_;
  $left = `cat $left`; $left =~ s/\s+//gs;
  $right = `cat $right`; $right =~ s/\s+//gs;
  return $left eq $right;
}
