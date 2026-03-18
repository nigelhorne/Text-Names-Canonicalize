package Text::Names::Canonicalize;

use strict;
use warnings;
use Exporter qw(import);
use Unicode::Normalize qw(NFKC NFD NFC);
use feature 'unicode_strings';
use charnames qw(:full);

our @EXPORT_OK = qw(
	canonicalize_name
	canonicalize_name_struct
);

my %SUFFIX = map { $_ => 1 } qw(jr sr ii iii iv);

BEGIN {
	require Text::Names::Canonicalize::Rules;

	Text::Names::Canonicalize::Rules->register(
		'en_GB',
		'default',
{
    particles    => [],
    suffixes     => [qw(jr sr ii iii iv)],
    strip_titles => [qw(mr mrs miss ms sir dame dr prof lord lady)],
    hyphen_policy => 'preserve',
    surname_strategy => 'last_token_with_particles',
}
	);
}

# Returns a plain canonical string.
sub canonicalize_name {
	my ($name, %opts) = @_;
	return _normalize_string($name, %opts);
}

sub canonicalize_name_struct {
	my ($name, %opts) = @_;

	my $locale  = $opts{locale}  || 'en_GB';
	my $ruleset = $opts{ruleset} || 'default';

	my $rules = Text::Names::Canonicalize::Rules->get($locale, $ruleset);

	# 1. Strip titles (using raw input)
	if (my $titles = $rules->{strip_titles}) {
		my $re = join '|', map { quotemeta } @$titles;
		$name =~ s/\b(?:$re)\b\.?//ig if defined $name;
	}

	# 2. Normalize
	my $norm = _normalize_string($name, %opts);

	# 3. Tokenize
	my $tokens = _tokenize($norm);

	# 4. Classify
	my $classified = _classify_tokens($tokens);

	# 5. Extract parts
	my $parts = _extract_parts($classified, $rules);

	return {
		original  => (defined $name ? $name : ''),
		locale	=> $locale,
		ruleset   => $ruleset,
		canonical => join(' ', @$tokens),
		parts	 => $parts,
	};
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
    my ($classified, $rules) = @_;

    my @tokens = @{ $classified->{tokens} };
    my @types  = @{ $classified->{types} };

    my %particle = map { $_ => 1 } @{ $rules->{particles} || [] };

    my (@given, @middle, @surname, @suffix);

    # 1. Peel off suffixes
    while (@types && $types[-1] eq 'suffix') {
        unshift @suffix, pop @tokens;
        pop @types;
    }

    # If nothing left, return empty structure
    return {
        given   => [],
        middle  => [],
        surname => [],
        suffix  => \@suffix,
    } unless @tokens;

    # 2. Locale-aware surname extraction
    if ($rules->{surname_strategy} && $rules->{surname_strategy} eq 'last_token_with_particles') {

        # Always take the last token as surname root
        my $root = pop @tokens;
        pop @types;
        unshift @surname, $root;

        # Pull in particles from the end backwards
        while (@tokens && $particle{$tokens[-1]}) {
            unshift @surname, pop @tokens;
            pop @types;
        }

    } else {
        # Fallback: simple last token
        my $root = pop @tokens;
        pop @types;
        unshift @surname, $root;
    }

    # 3. Given = first token (if any)
    if (@tokens) {
        push @given, shift @tokens;
        shift @types;
    }

    # 4. Middle = everything else
    @middle = @tokens;

    return {
        given   => \@given,
        middle  => \@middle,
        surname => \@surname,
        suffix  => \@suffix,
    };
}

sub _normalize_string {
	my ($name, %opts) = @_;

	$name = '' unless defined $name;

	my $norm = NFKC($name);

	# whitespace
	$norm =~ s/\s+/ /g;
	$norm =~ s/^\s+//;
	$norm =~ s/\s+$//;

	# punctuation (basic)
	$norm =~ s/[.,]+$//;   # strip trailing comma/period
	$norm =~ s/^[.,]+//;   # strip leading comma/period

	# lowercase
	$norm = lc $norm;

	# diacritics
	if ($opts{strip_diacritics}) {
		my $d = NFD($norm);
		$d =~ s/\pM//g;
		$norm = NFC($d);
	}

	return $norm;
}

1;
