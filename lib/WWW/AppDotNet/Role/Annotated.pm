package WWW::AppDotNet::Role::Annotated;

use strict;
use warnings;

use Moose::Role;

sub request_params {
    my ($class) = @_;
    return ( params => { include_annotations => 2, },  );
}

1;
