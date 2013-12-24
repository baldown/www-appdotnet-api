package WWW::AppDotNet::Channel;

use strict;
use warnings;

use Moose;

extends 'WWW::AppDotNet::Object';

use WWW::AppDotNet::User;

has 'id'        => (is => 'rw', isa => 'Int');
has 'type'      => (is => 'rw', isa => 'Str');
has 'owner'     => (is => 'rw', isa => 'WWW::AppDotNet::User');

sub setup_handler {
    my ($obj) = @_;
    
    $obj->id($obj->json->{id});
    $obj->type($obj->json->{type});
    $obj->owner(WWW::AppDotNet::User->json_to_object($obj->api,$obj->json->{owner}));
}

__PACKAGE__->meta->make_immutable;

1;
