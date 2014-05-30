package WWW::AppDotNet::User::Followers;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends 'WWW::AppDotNet::User';

sub fetch_pragma {
    my ($class, @args) = @_;

    return 'users//followers';
}

__PACKAGE__->meta->make_immutable;

1;

