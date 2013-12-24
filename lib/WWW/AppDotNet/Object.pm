package WWW::AppDotNet::Object;

use strict;
use warnings;

use Moose;
use WWW::AppDotNet::API;

has 'json' => ( is => 'rw', isa => 'HashRef' );
has 'api' => ( is => 'rw', isa => 'WWW::AppDotNet::API' );
has 'annotations' => ( is => 'rw', isa => 'HashRef' );

sub get_api {
    my ($class, %params) = @_;
    
    my %args;
    if ($params{token}) {
        %args = ( token => $params{token} );
    } elsif ($params{client_id}) {
        %args = ( client_id => $params{client_id}, client_secret => $params{client_secret} );
    } elsif ($params{public}) {
        %args = ( public => $params{public} );
    } else {
        Carp::croak "Insufficient arguments to provide API object for $class!";
    }
    
    my $api = WWW::AppDotNet::API->new(%args);
    return $api;
}


sub fetch_pragma {
    my ($class) = @_;
    $class =~ s/.*:://;
    $class .= 's';
    return lc($class).'/';
}

sub request_params {
    return ();
}
    
sub fetch {
    my $class = shift;
    my $api = ref($_[0]) ? shift : $class->get_api(@_);
    
    my $url = $class->build_url(
        $class->fetch_pragma,
        @_
    );
    
    my $response = $api->request(
        url => $url,
        $class->request_params,
        );
    
    return unless $response;
    
    if (ref($response->{data}) eq 'ARRAY') {
        return map { $class->json_to_object($api, $_) } @{$response->{data}};
    } else {
        return $class->json_to_object($api, $response->{data});
    }
}

sub fetch_all {
    my $class = shift;
    
}

sub create {

}

sub json_to_object {
    my ($class, $api, $json) = @_;
    
    my $obj = $class->new(
        api => $api,
        json => $json,
        );

    if ($json->{annotations}) {
        my %annotations = map { $_->{type} => $_->{value} } @{$json->{annotations}};
        $obj->annotations(\%annotations);
    }
        
    $obj->setup_handler;
        
    return $obj;
}

sub setup_handler {}

sub build_url {
    my ($class, $pragma, @consumables) = @_;
    
    my %map;
    if (scalar(@consumables) && ref($consumables[0]) eq 'HASH') {
        %map = %{shift @consumables};
    }
    
    my @parts = split(m|/|,$pragma, -1);
    for (my $i = 1; $i < scalar(@parts); $i++) {
        next if $parts[$i] ne '';
        if (keys %map) {
            $parts[$i] = $map{$parts[$i - 1]};
            $parts[$i] //= $map{substr($parts[$i - 1], 0, -1)};
        } else {
            Carp::croak "Not enough parameters provided to build URL in $class" unless scalar @consumables;
            $parts[$i] = shift @consumables;
        }
    }
    
    return '/'.join('/', @parts);
}

__PACKAGE__->meta->make_immutable;

1;
