package WWW::AppDotNet::Channel::Blog;

use strict;
use warnings;

use Moose;

extends 'WWW::AppDotNet::Channel';
with 'WWW::AppDotNet::Role::Annotated';

has 'name'      => (is => 'rw', isa => 'Str');
has 'url'       => (is => 'rw', isa => 'Str');
has 'settings'  => (is => 'rw', isa => 'HashRef');

sub fetch_pragma {
    my ($class) = @_;
    return 'channels/'
}

sub setup_handler {
    my ($obj) = @_;
    $obj->maybe::next::method;

    unless ($obj->type eq 'net.blog-app.blog') {
        Carp::cluck('Blog Channel fetch returned blog of odd type '.$obj->type.'!');
    }

    $obj->settings($obj->annotations->{'net.blog-app.settings'});
    
    $obj->name($obj->settings->{name});
}

__PACKAGE__->meta->make_immutable;

1;