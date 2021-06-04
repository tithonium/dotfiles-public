#!/usr/bin/perl

my %branches;
open(my $fp, '-|','git branch -r -v -v --no-merged');
while(<$fp>) {
  chomp;
  # origin/oauth2_fixes                                       c1de634 check for non-nil GA profile before requesting GA data
  my(undef, $br, $sha, $desc) = split(/\s+/, $_, 4);
  next if $br =~ m!^origin/(?:HEAD|master|release|production|staging)$!;
  s! origin/! !;
  
  chomp(my $owner = `git log -1 --pretty=format:'%aN <%aE> %as' $br`);
  $owner =~ s! (\S+)$!!; my $date = $1;
  $_ = "$date  $_";
  
  push @{$branches{$owner}}, $_;
}
close($fp);
foreach my $owner (sort keys %branches) {
  print $owner, "\n";
  print join("\n", sort @{$branches{$owner}}), "\n\n";
}
