package WWW::AppDotNet::Channel;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends 'WWW::AppDotNet::Object';

use WWW::AppDotNet::User;

has 'id'        => (is => 'rw', isa => 'Int');
has 'type'      => (is => 'rw', isa => 'Str');
has 'owner'     => (is => 'rw', isa => 'WWW::AppDotNet::User');

sub fetch_pragma {
    my ($class, @args) = @_;
    
    #if (scalar(@consumables) && ref($consumables[0]) eq 'HASH' && $consumables[0]->{user}) {
    #    return 'users//channels';
    #} else {
        return 'channels/';
    #}
}

sub setup_handler {
    my ($obj) = @_;
    
    $obj->id($obj->json->{id});
    $obj->type($obj->json->{type});
    $obj->owner(WWW::AppDotNet::User->json_to_object($obj->api,$obj->json->{owner}));
}

__PACKAGE__->meta->make_immutable;

1;
