package Text::Names::Canonicalize;

use strict;
use warnings;
use Exporter qw(import);
use Unicode::Normalize qw(NFKC NFD NFC);
use feature 'unicode_strings';
use charnames qw(:full);

our @EXPORT_OK = qw(canonicalize_name);


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

1;
