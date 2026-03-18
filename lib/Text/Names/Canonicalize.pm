package Text::Names::Canonicalize;

use strict;
use warnings;
    use Encode qw(decode);
use Exporter qw(import);
use Unicode::Normalize qw(NFKC NFD NFC);

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
    

    return $norm;
}

1;
