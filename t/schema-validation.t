use strict;
use warnings;
use utf8;
use Test::Most;
use YAML::XS qw(LoadFile);
use File::Spec;
use File::Basename qw(dirname);

# Directory containing YAML rules
my $rules_dir = File::Spec->catdir(
    dirname(__FILE__), '..', 'lib', 'Text', 'Names', 'Canonicalize', 'Rules'
);

opendir my $dh, $rules_dir or die "Cannot open $rules_dir: $!";
my @yaml_files = grep { /\.yaml$/ } readdir $dh;
closedir $dh;

# Required keys for each ruleset
my @required_keys = qw(
    particles
    suffixes
    strip_titles
    hyphen_policy
    surname_strategy
);

# Allowed keys (for future extensibility)
my %allowed = map { $_ => 1 } @required_keys;

foreach my $file (@yaml_files) {
    my $path = File::Spec->catfile($rules_dir, $file);

    ok(-e $path, "YAML file exists: $file");

    my $yaml = eval { LoadFile($path) };
    ok(!$@, "YAML loads cleanly: $file");

    ok(ref $yaml eq 'HASH', "YAML top-level is a hash: $file");

    foreach my $ruleset (keys %$yaml) {
        my $rules = $yaml->{$ruleset};

        ok(ref $rules eq 'HASH', "Ruleset '$ruleset' is a hash");

        # Check required keys
        foreach my $key (@required_keys) {
            ok(exists $rules->{$key}, "$file/$ruleset has key '$key'");
        }

        # Check for unknown keys
        foreach my $key (keys %$rules) {
            ok($allowed{$key}, "$file/$ruleset key '$key' is allowed");
        }

        # Type checks
        ok(ref $rules->{particles} eq 'ARRAY', "particles is array");
        ok(ref $rules->{suffixes} eq 'ARRAY', "suffixes is array");
        ok(ref $rules->{strip_titles} eq 'ARRAY', "strip_titles is array");
        ok(!ref $rules->{hyphen_policy}, "hyphen_policy is scalar");
        ok(!ref $rules->{surname_strategy}, "surname_strategy is scalar");
    }
}

done_testing;
