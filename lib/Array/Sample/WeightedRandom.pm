package Array::Sample::WeightedRandom;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(sample_weighted_random_with_replacement
                    sample_weighted_random_no_replacement);

sub sample_weighted_random_with_replacement {
    my ($ary, $n, $opts) = @_;
    $opts //= {};

    return () unless @$ary;

    my $sum_of_weights = 0;
    for (@$ary) { $sum_of_weights += $_->[1] }

    my @res;
    for my $i (1..$n) {
        my $x = rand() * $sum_of_weights;

        my $y = 0;
        for my $j (0 .. $#{$ary}) {
            my $elem = $ary->[$j];
            my $y2 = $y + $elem->[1];
            if ($x >= $y && $x < $y2) {
                my $idx = $j;
                push @res, $opts->{pos} ? $idx : $ary->[$idx][0];
                last;
            }
            $y = $y2;
        }
    }

    @res;
}

sub sample_weighted_random_no_replacement {
    my ($ary, $n, $opts) = @_;
    $opts //= {};

    $n = @$ary if $n > @$ary;
    my @ary_copy = @$ary;
    my @pos  = 0 .. $#ary_copy;

    my $sum_of_weights = 0;
    for (@ary_copy) { $sum_of_weights += $_->[1] }

    my @res;
    for my $i (1..$n) {
        my $x = rand() * $sum_of_weights;

        my $y = 0;
        for my $j (0 .. $#ary_copy) {
            my $elem = $ary_copy[$j];
            my $y2 = $y + $elem->[1];
            if ($x >= $y && $x < $y2) {
                push @res, $opts->{pos} ? $pos[$j] : $elem->[0];
                $sum_of_weights -= $elem->[1];
                splice @ary_copy, $j, 1;
                splice @pos     , $j, 1;
                last;
            }
            $y = $y2;
        }
    }
    @res;
}

1;
# ABSTRACT: Sample elements randomly, with weights (with or without replacement)

=head1 SYNOPSIS

 use Array::Sample::WeightedRandom qw(sample_weighted_random_with_replacement sample_weighted_random_no_replacement);

 # "b" will be picked more often because it has a greater weight
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("b")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("a")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("b")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 5); => ("b", "b", "a", "b", "b")

 sample_weighted_random_no_replacement([ ["a",1], ["b",2.5] ], 5); => ("b", "a")


=head1 DESCRIPTION

Keywords: weight, weighting, pick


=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 sample_weighted_random_with_replacement

Syntax: sample_simple_random_with_replacement(\@ary, $n [ , \%opts ]) => list

Options:

=over

=item * pos => bool

If set to true, will return positions instead of the elements.

=back

The function takes an array reference (C<\@ary>) and number of samples to take
(C<$n>). The array must be structured as follow: each element is a 2-element
arrayref containing a value followed by weight (a non-negative real number). The
function will take samples at random position but taking weight into
consideration. The larger the weight of an element, the greater the possibility
of the element being chosen. An element can be picked more than once.

The function will return a list of sample items (values only, without the
weights).

=head2 sample_weighted_random_no_replacement

Syntax: sample_simple_random_no_replacement(\@ary, $n [ , \%opts ]) => list

Options:

=over

=item * pos => bool

If set to true, will return positions instead of the elements.

=back

Like L</sample_weighted_random_with_replacement> but an element can only be
picked once.


=head1 SEE ALSO

Other sampling methods: L<Array::Sample::SysRand>, L<Array::Sample::Partition>.

L<Array::Sample::SimpleRandom::Scan>

=cut
