package Text::Names::Canonicalize;

use strict;
use warnings;
use Exporter qw(import);
use Unicode::Normalize qw(NFKC NFD NFC);
use feature 'unicode_strings';
use charnames qw(:full);

our @EXPORT_OK = qw(canonicalize_name);

my %SUFFIX = map { $_ => 1 } qw(jr sr ii iii iv);

sub canonicalize_name {
    my ($name, %opts) = @_;

    # 1. Coerce to defined string
    $name = '' unless defined $name;

    # 2. Unicode normalization
    my $norm = NFKC($name);

    # 3. Normalize whitespace
    $norm =~ s/\s+/ /g;
    $norm =~ s/^\s+//;
    $norm =~ s/\s+$//;

    # 4. Normalize punctuation (very conservative for now)
    $norm =~ s/[.,]+$//;
    $norm =~ s/^[.,]+//;

    # 5. Lowercase
    $norm = lc $norm;

# 6. Optional: strip diacritics by removing combining marks
if ($opts{strip_diacritics}) {
    # Ensure we are working with decoded characters
    # (no-op if already decoded)
    $norm = decode('UTF-8', $norm) unless utf8::is_utf8($norm);

    # Decompose: é → e + ◌́
    my $decomp = NFD($norm);

    # Remove all combining marks
    $decomp =~ s/\pM//g;

    # Recompose (optional but cleaner)
    $norm = NFC($decomp);
}
    
	return wantarray ? ($norm, _tokenize($norm)) : $norm;
}

sub _tokenize {
    my ($norm) = @_;

    my @t = split / /, $norm;

    for (@t) {
        # strip leading/trailing punctuation
        s/^\pP+//;
        s/\pP+$//;

        # normalize apostrophes: curly quotes → ASCII '
        s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}]/'/g;

        # normalize all dash-like characters to ASCII hyphen
        s/\p{Dash}/-/g;

        # trailing period (initials)
        s/\.$//;
    }

    return [ grep { length } @t ];
}

sub _classify_tokens {
    my ($tokens) = @_;

    my @types;

    for my $t (@$tokens) {
        if ($t =~ /^[a-z]$/) {
            push @types, "initial";
        }
        elsif ($SUFFIX{$t}) {
            push @types, "suffix";
        }
        else {
            push @types, "word";
        }
    }

    return {
        tokens => $tokens,
        types  => \@types,
    };
}

sub _extract_parts {
    my ($classified) = @_;

    my @tokens = @{ $classified->{tokens} };
    my @types  = @{ $classified->{types} };

    my (@given, @middle, @surname, @suffix);

    # 1. Peel off suffixes from the end
    while (@types && $types[-1] eq 'suffix') {
        unshift @suffix, pop @tokens;
        pop @types;
    }

    # 2. If no tokens left, return empty structure
    return {
        given   => [],
        middle  => [],
        surname => [],
        suffix  => \@suffix,
    } unless @tokens;

    # 3. Surname = last remaining token
    push @surname, pop @tokens;
    pop @types;

    # 4. Given = first remaining token (if any)
    if (@tokens) {
        push @given, shift @tokens;
        shift @types;
    }

    # 5. Middle = everything else
    @middle = @tokens;

    return {
        given   => \@given,
        middle  => \@middle,
        surname => \@surname,
        suffix  => \@suffix,
    };
}



1;
