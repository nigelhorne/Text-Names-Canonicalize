package Text::Names::Canonicalize::Rules;

use strict;
use warnings;
use Carp qw(croak);

# Simple in-memory registry:
#   $REGISTRY{locale}{ruleset} = { ...rules... }
my %REGISTRY;

# Register a ruleset for a locale.
sub register {
    my ($class, $locale, $ruleset, $rules) = @_;
    croak "register() requires locale, ruleset, rules hashref"
        unless $locale && $ruleset && ref $rules eq 'HASH';

    $REGISTRY{$locale}{$ruleset} = $rules;
}

# Fetch a ruleset for a locale.
sub get {
    my ($class, $locale, $ruleset) = @_;
    $ruleset ||= 'default';

    my $rules = $REGISTRY{$locale}{$ruleset}
        or croak "No ruleset '$ruleset' for locale '$locale'";

    return $rules;
}

1;
