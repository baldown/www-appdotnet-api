package WWW::AppDotNet::User::Follows;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends 'WWW::AppDotNet::User';

sub fetch_pragma {
    my ($class, @args) = @_;

    return 'users//following';
}

__PACKAGE__->meta->make_immutable;

1;

