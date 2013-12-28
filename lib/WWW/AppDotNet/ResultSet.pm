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
    return unless $self->more;
    my %opts = $self->result_class->request_params;
    $opts{params} //= {};
    $opts{params}->{before_id} = $self->response->{meta}->{min_id};
    return $self->result_class->fetch($self->api,
        url => $self->url,
        %opts,
    );
}

sub all {
    my ($self) = @_;
    
    my $request = $self;
    my @results;
    do {
        push @results, $request->results;
    } while ($request = $request->next);
    return @results;
}

__PACKAGE__->meta->make_immutable;

1;

