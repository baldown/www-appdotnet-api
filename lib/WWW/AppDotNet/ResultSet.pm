package WWW::AppDotNet::ResultSet;

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use WWW::AppDotNet::API;

has 'response' => (is => 'rw', isa => 'HashRef');
has 'url' => (is => 'rw', isa => 'Str');
has 'result_class' => (is => 'rw', isa => 'Str');
has 'api' => (is => 'rw', isa => 'WWW::AppDotNet::API');

sub more {
    my ($self) = @_;
    
    return $self->response->{meta}->{more};
}

sub results {
    my ($self) = @_;
    return map { $self->result_class->json_to_object($self->api, $_) } @{$self->response->{data}};
}

sub next {
    my ($self) = @_;
    return 0 unless $self->more;
    my %opts = $self->result_class->request_params;
    $opts{params} //= {};
    $opts{params}->{before_id} = $self->response->{meta}->{min_id};
    my $resp = $self->api->request(
        url => $self->url,
        %opts,
    );
    if ($resp) {
        $self->response($resp);
        return 1;
    } else {
        warn $self->api->error;
        return 0;
    }
}

sub all {
    my ($self) = @_;
    
    my @results;
    do {
        push @results, $self->results;
    } while ($self->next);
    return @results;
}

__PACKAGE__->meta->make_immutable;

1;

