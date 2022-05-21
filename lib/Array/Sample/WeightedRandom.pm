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

    if ($opts->{shuffle}) {
        require List::Util;
        @res = List::Util::shuffle(@res);
    }

    @res;
}

 sub sample_weighted_random_no_replacement {
    my ($ary, $n, $opts) = @_;
    $opts //= {};
    $opts->{algo} //= 'copy';

    $n = @$ary if $n > @$ary;

    my $sum_of_weights = 0;
    for (@$ary) { $sum_of_weights += $_->[1] }

    my @res; # element: item or pos (if 'pos' option is true)

    if ($opts->{algo} eq 'nocopy') {
        my %picked; # key=index, val=1
        for my $i (1..$n) {
            my $x = rand() * $sum_of_weights;

            my $y = 0;
            for my $j (0 .. $#{$ary}) {
                my $elem;
                if ($picked{$j}) {
                    $elem = [undef, 0];
                } else {
                    $elem = $ary->[$j];
                }

                my $y2 = $y + $elem->[1];
                if ($x >= $y && $x < $y2) {
                    push @res, $opts->{pos} ? $j : $elem->[0];
                    $sum_of_weights -= $elem->[1];
                    $picked{$j}++;
                    last;
                }
                $y = $y2;
            }
        }
    } else {
        my @ary_copy = @$ary;
        my @pos  = 0 .. $#ary_copy;

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
    }

    if ($opts->{shuffle}) {
        require List::Util;
        @res = List::Util::shuffle(@res);
    }

    @res;
}

1;
# ABSTRACT: Sample elements randomly, with weights (with or without replacement)

=head1 SYNOPSIS

 use Array::Sample::WeightedRandom qw(sample_weighted_random_with_replacement sample_weighted_random_no_replacement);

 # "b" will be picked more often because it has a greater weight. it's also more
 # likely to be picked at the beginning.
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

=item * shuffle => bool

By default, a heavier-weighted item will be more likely to be at the front of
the resulting sample. If this option is set to true, the function will shuffle
the random samples before returning it, resulting in random order regardless of
weight.

=item * algo => str

Default is 'copy'. Another choice is 'nocopy', which avoids creating a shallow
(1-level) copy of the input array. The 'nocopy' algorithm is generally a bit
slower but could save memory usage *if* your array is very very large (e.g. tens
of millions of elements).

=back

The function takes an array reference (C<\@ary>) and number of samples to take
(C<$n>). The array must be structured as follow: each element is a 2-element
arrayref containing a value followed by weight (a non-negative real number). The
function will take samples at random position but taking weight into
consideration. The larger the weight of an element, the greater the possibility
of the element's value being chosen *and* the greater the possibility of the
element's value being in the front of the samples. An element can be picked more
than once.

The function will return a list of sample items (values only, without the
weights).

If you want random order regardless of weight, you can shuffle the resulting
list e.g. using L<List::Util>'s C<shuffle>; or you can use the C<shuffle> option
which does the same.

=head2 sample_weighted_random_no_replacement

Syntax: sample_simple_random_no_replacement(\@ary, $n [ , \%opts ]) => list

Like L</sample_weighted_random_with_replacement> but an element can only be
picked once.


=head1 SEE ALSO

L<Data::Random::Weighted> returns only a single item, uses hash internally so
you can't have duplicate elements, and only allows integer as weights.

Other sampling methods: L<Array::Sample::SysRand>, L<Array::Sample::Partition>,
L<Array::Sample::SimpleRandom>.

=cut
