package Text::Names::Canonicalize::Rules;

use strict;
use warnings;
use Carp qw(croak);
use YAML::XS qw(LoadFile);
use File::Spec;
use File::Basename qw(dirname);

# ----------------------------------------------------------------------
# Load a YAML ruleset if available.
# YAML files live in:
#   lib/Text/Names/Canonicalize/Rules/<locale>.yaml
# ----------------------------------------------------------------------
sub _load_yaml_rules {
    my ($locale) = @_;

# __FILE__ = .../Text/Names/Canonicalize/Rules.pm
# YAML lives in .../Text/Names/Canonicalize/Rules/*.yaml

my $base = File::Spec->catdir( dirname(__FILE__), 'Rules' );
my $file = File::Spec->catfile( $base, "$locale.yaml" );

    return unless -e $file;

    my $yaml = eval { LoadFile($file) };
    croak "Failed to load YAML rules for $locale: $@" if $@;

    croak "YAML rules for $locale must be a hash" unless ref $yaml eq 'HASH';

    return $yaml;
}

# ----------------------------------------------------------------------
# Fetch a ruleset:
#   1. Try YAML
#   2. Fall back to Perl registry
# ----------------------------------------------------------------------
sub get {
    my ($class, $locale, $ruleset) = @_;
    $ruleset ||= 'default';

    # Load YAML ruleset
    my $yaml = _load_yaml_rules($locale)
        or croak "No YAML rules found for locale '$locale'";

    my $rules = $yaml->{$ruleset}
        or croak "No ruleset '$ruleset' in YAML for locale '$locale'";

    return $rules;
}


1;
