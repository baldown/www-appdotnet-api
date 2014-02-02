package WWW::AppDotNet::Object;

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use WWW::AppDotNet::API;
use WWW::AppDotNet::ResultSet;

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
    
    my $url = $class->build_url(@_);
    
    my $response = $api->request(
        url => $url,
        $class->request_params,
        );
    
    return unless $response;
    
    if (ref($response->{data}) eq 'ARRAY') {
        my $set = WWW::AppDotNet::ResultSet->new(
            api => $api,
            url => $url,
            result_class => $class,
            response => $response,
        );
        return wantarray ? $set->results : $set;
    } else {
        return $class->json_to_object($api, $response->{data});
    }
}

sub create {

}

sub json_to_object {
    my ($class, $api, $json) = @_;
    
    my $obj = $class->new(
        api => $api,
        json => $json,
        );

    $obj->annotations({});
    if ($json->{annotations}) {
        my %annotations = map { $_->{type} => $_->{value} } @{$json->{annotations}};
        $obj->annotations(\%annotations);
    }
        
    $obj->setup_handler;
        
    return $obj;
}

sub setup_handler {}

sub build_url {
    my ($class, @consumables) = @_;
    
    my %map;
    if (scalar(@consumables) && ref($consumables[0]) eq 'HASH') {
        %map = %{shift @consumables};
    }
    
    my $pragma = $class->fetch_pragma(@consumables);
    
    my @urlparts;
    my @pragmaparts = split(m|/|,$pragma, -1);
    while (scalar(@pragmaparts)) {
        my $piece = shift @pragmaparts;
        if ($piece ne '') {
            push @urlparts, $piece;
            next;
        }
        # Fill the empty
        if (keys %map) {
            my $fill = $map{$urlparts[-1]} || $map{substr($urlparts[-1], 0, -1)};
            if (defined $fill) {
                push @urlparts, $fill;
            } elsif (scalar(@pragmaparts)) {
                Carp::croak "Not enough parameters provided to build URL in $class";
            }
        } elsif (scalar(@consumables)) {
            push @urlparts, shift @consumables;
        } elsif (scalar(@pragmaparts)) {
            Carp::croak "Not enough parameters provided to build URL in $class";
        }
    }
    
    return '/'.join('/', @urlparts);
}

__PACKAGE__->meta->make_immutable;

1;
