package WWW::AppDotNet::Message;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use DateTime::Format::RFC3339;

use WWW::AppDotNet::User;

extends 'WWW::AppDotNet::Object';

subtype 'Timestamp' => as class_type('DateTime');

coerce 'Timestamp' =>
      from 'Str' =>
      via { 
          my $f = DateTime::Format::RFC3339->new();
          my $dt = $f->parse_datetime( $_ );
          return $dt;
      };

has 'id'        => (is => 'rw', isa => 'Int');
has 'channel_id'   => (is => 'rw', isa => 'Int');
has 'user'      => (is => 'rw', isa => 'WWW::AppDotNet::User');
has 'timestamp' => (is => 'rw', isa => 'Timestamp', coerce => 1);

has 'content'   => (is => 'rw', isa => 'Str');
has 'html_content'  => (is => 'rw', isa => 'Str');

sub fetch_pragma {
    my ($class) = @_;
    return 'channels//messages/'
}

sub setup_handler {
    my ($obj) = @_;
    
    $obj->id($obj->json->{id});
    $obj->timestamp($obj->json->{created_at});
    $obj->user(WWW::AppDotNet::User->json_to_object($obj->api,$obj->json->{user}));
    $obj->channel_id($obj->json->{channel_id});
    $obj->content($obj->json->{text});
    $obj->html_content($obj->json->{html});
}

__PACKAGE__->meta->make_immutable;

1;
