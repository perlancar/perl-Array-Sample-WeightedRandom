package Array::Sample::WeightedRandom::Scan;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(sample_weighted_random_no_replacement);

# this sub requires two iterator, the first one is to calculate sum of inverse
# weight for all items. then the second to scan and
sub _sample_weighted_random_no_replacement {
    my ($iter1, $iter2, $num_items, $opts) = @_;

    $num_items //= 1;
    $opts //= {};

    my @res; # each elem: [item, weight, pos]

    # iterate the first time to calculate sum of inverse weights for all items
    my $sum_of_inv_weights_all = 0;
    my $sum_of_weights_all = 0;
    while (defined(my $item = $iter1->())) {
        next if $item->[1] <= 0;
        $sum_of_weights_all     += $item->[1];
        $sum_of_inv_weights_all += 1/$item->[1];
    }
    #say "D: sum_of_weights_all=<$sum_of_weights_all>";

    my $sum_of_weights_iterated = 0;
    my $sum_of_weights_res = 0;
    my $sum_of_inv_weights_iterated = 0;
    my $sum_of_inv_weights_res = 0;
    my $i = -1;
    while (defined(my $item = $iter2->())) {
        $i++;

        next if $item->[1] <= 0;

        #use DD; print "D:item: "; dd $item;
        if (@res < $num_items) {
            # we haven't collected $num_items in @res, populate @res first.
            #say "D:  adding";
            push @res, [$item->[0], $item->[1], $i];
            $sum_of_weights_res     += $item->[1];
            $sum_of_inv_weights_res += 1/$item->[1];
        } else {
            #say "D:maybe replacing (probability: rand($sum_of_inv_weights_iterated + 1/$item->[1]) < $sum_of_inv_weights_res)";
            # we have reached $num_items in @res, probabilistically replace an
            # item randomly, using algorithm from Learning Perl, slightly
            # modified to account for weights.
            if (rand($sum_of_inv_weights_iterated + 1/$item->[1]) < $sum_of_inv_weights_res) {
                my $x = rand($sum_of_inv_weights_res);
                #say "D:  x=rand($sum_of_inv_weights_res)=$x";
                my $y = 0;
                my $replaced;
                for my $j (0 .. $#res) {
                    my $elem = $res[$j];
                    my $y2 = $y + 1/$elem->[1];
                    if ($x >= $y && $x < $y2) {
                        my $idx = $j;
                        #say "D:  replacing at position $j";
                        my ($removed_elem) = splice @res, $j, 1, [$item->[0], $item->[1], $i];
                        $sum_of_weights_res     += $item->[1]   - $removed_elem->[1];
                        $sum_of_inv_weights_res += 1/$item->[1] - $removed_elem->[1];
                        $replaced++;
                        last;
                    }
                    $y = $y2;
                }
            } else {
                #say "D:  not replacing";
            }
        }

        $sum_of_weights_iterated     += $item->[1];
        $sum_of_inv_weights_iterated += 1/$item->[1];

    } # while iter

    if ($opts->{shuffle}) {
        require List::Util;
        @res = List::Util::shuffle(@res);
    } else {
        require Array::Sample::WeightedRandom;
        @res = Array::Sample::WeightedRandom::sample_weighted_random_no_replacement(\@res, scalar(@res), {with_weight=>1});
    }

    if ($opts->{pos}) {
        return map {$_->[2]} @res;
    } else {
        return map {$_->[0]} @res;
    }
}

sub sample_weighted_random_no_replacement {
    require Array::Iter;

    my ($ary, $n, $opts) = @_;

    my $iter1 = Array::Iter::array_iter($ary);
    my $iter2 = Array::Iter::array_iter($ary);
    _sample_weighted_random_no_replacement($iter1, $iter2, $n, $opts);
}

1;
# ABSTRACT: (DO NOT USE) Sample elements randomly, with weights, without replacement (using scan algorithm)

=head1 SYNOPSIS

 use Array::Sample::WeightedRandom::Scan qw(sample_weighted_random_no_replacement);

 # "b" will be picked more often because it has a greater weight. it's also more
 # likely to be at the front of the samples.
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("b")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("a")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("b")
 sample_weighted_random_no_replacement([ ["a",1], ["b",2.5] ], 5); => ("b", "a")


=head1 DESCRIPTION

B<DO NOT USE>. This algorithm currently produces biased results where the items
at the beginning will be picked at probabiity not quite according to their
weights. Use L<Array::Sample::WeightedRandom> instead.

This module provides L</sample_weighted_random_no_replacement> which is the same
as the one provided by L<Array::Sample::WeightedRandom> but uses the scan
algorithm. It actually scans the array twice instead of once.


=head1 FUNCTIONS

=head2 sample_weighted_random_no_replacement

See documentation of L<Array::Sample::WeightedRandom>.


=head1 FAQ

=head2 Why no sample_weighted_random_with_replacement?

This kind of sampling does not require scanning algorithm.


=head1 SEE ALSO

L<Array::Sample::WeightedRandom>

Other sampling methods: L<Array::Sample::Partition>, L<Array::Sample::SysRand>,
L<Array::Sample::SimpleRandom>.
