use strict;
use warnings;
use Test::Most;
use File::Spec;

my $cli = File::Spec->catfile(qw(bin text-names-canonicalize));

ok(-f $cli, 'CLI script exists');

my $out = qx{$cli --locale fr_FR "Jean d'Ormesson"};
is($?, 0, 'CLI exited cleanly');
chomp $out;
is($out, "jean d'ormesson", 'CLI canonicalized correctly');

done_testing();
