package Tie::Hash::Array;

=head1 NAME

Tie::Hash::Array - a hash which is internally implemented as a sorted array

=head1 SYNOPSIS

  use Tie::Hash::Array;

  tie my %hash, 'Tie::Hash::Array';
  $hash{foo} = 'bar';

  my $object = new Foo;
  $hash{$object} = 'You can also use objects as keys.';

  while ( my($key, $value) = each %hash ) {
      $key->dwim($value) if ref $key && $key->can('dwim');
  }

=head1 DESCRIPTION

Hashes tied to this class will interally be stored as an array alternately
containing keys and values, with its keys sorted in standard string comparison
order, that is, as L<C<cmp>|perlop/"Equality Operators"> does.

While the main purpose of this module is serving as a base class for
L<Tie::Hash::Abbrev>, some of its side effects may also be useful by themselves:

=over 4

=item *

L<perlfunc/each> will return the contents in sorted order.

=item *

You can use objects as keys.
(Please note, however, that in this case the string representations of these
objects should stay constant, or to be exact, their string sorting order should
maintain stable, or else you might get undesired results.)

=back

=head1 SUBCLASSING

Please do not rely on the implementation details of this class for now,
since they may still be subject to change.

If you'd like to subclass this module, please let me know;
perhaps we can agree on some standards then.

=head1 BUGS

None known so far.

=head1 AUTHOR

	Martin H. Sluka
	mailto:martin@sluka.de
	http://martin.sluka.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Tie::Hash::Abbrev>

=cut

use strict;
use vars '$VERSION';

$VERSION = 0.01;

sub TIEHASH {
    my $package = shift;
    $package = ref $package if length ref $package;
    bless [], $package;
}

sub FETCH {
    my ( $self, $key ) = @_;
    if ( defined $self->valid( $key, my $pos = $self->pos($key) ) ) {
        $self->[ $pos + 1 ];
    }
    else { undef }
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    if ( defined $self->exact( $key, my $pos = $self->pos($key) ) ) {
        $self->[ $pos + 1 ] = $value;
    }
    else { splice @$self, $pos, 0, $key, $value }
}

sub EXISTS {
    my ( $self, $key ) = @_;
    defined( my $pos2 = $self->valid( $key, my $pos = $self->pos($key) ) )
      or return '';
    ( 2 + $pos2 - $pos ) >> 1;
}

sub DELETE {
    my ( $self, $key ) = @_;
    my $pos = $self->pos($key);
    if ( defined $self->exact( $key, $pos ) ) {
        ( undef, my $value ) = splice @$self, $pos, 2;
        $self->startover;
        $value;
    }
    else { undef }
}

sub CLEAR {
    my ($self) = @_;
    $self->startover;
    @$self = ();
}

my %i;

sub FIRSTKEY {
    my ($self) = @_;
    return undef unless @$self;
    $self->[ $i{$self} = 0 ];
}

sub NEXTKEY {
    my ( $self, $lastkey ) = @_;
    if ( ( my $i = $i{$self} += 2 ) < $#$self ) { $self->[$i] }
    else {
        $self->startover;
        undef;
    }
}

sub UNTIE { }

sub DESTROY { shift->startover }

sub exact {
    my ( $self, $key, $pos ) = @_;
    if ( $pos <= $#$self && $self->[$pos] eq $key ) { $pos }
    else { undef }
}

sub pos {
    my ( $self, $key ) = @_;
    my $a = 0;
    my $b = @$self;
    while ( $a < $b && $a < $#$self ) {    # perform a binary search
        if ( $self->[ my $c = ( $a + $b >> 1 ) & ~1 ] lt $key ) { $a = $c + 2 }
        else { $b = $c }
    }
    $a;
}

sub startover {
    my ($self) = @_;
    delete $i{$self};
}

*valid = \&exact;

1
