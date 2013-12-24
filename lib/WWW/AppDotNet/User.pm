package WWW::AppDotNet::User;

use strict;
use warnings;

use Moose;

extends 'WWW::AppDotNet::Object';

has 'id'        => (is => 'rw', isa => 'Int');
has 'username'  => (is => 'rw', isa => 'Str');
has 'name'      => (is => 'rw', isa => 'Str');
has 'timezone'  => (is => 'rw', isa => 'Str');

sub setup_handler {
    my ($obj) = @_;
    
    $obj->id($obj->json->{id});
    $obj->username($obj->json->{username});
    $obj->name($obj->json->{name});
    $obj->timezone($obj->json->{timezone});
    
    return $obj;
};

__PACKAGE__->meta->make_immutable;

1;

