package WWW::AppDotNet::API;

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp qw(cluck croak);
use LWP::UserAgent;
use JSON::Any;
use URI;
use URI::QueryParam;
use namespace::autoclean;

our $base_url = 'https://alpha-api.app.net/stream/0/';
our $app_token_url = 'https://account.app.net/oauth/access_token';
our $handle_cache = {};

=head1 NAME

WWW::AppDotNet::API - Module for accessing the App.net API.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.80';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::AppDotNet::API;

    my $foo = WWW::AppDotNet::API->new();
    ...

=head1 SUBROUTINES/METHODS

=cut

has 'ua' => ( is => 'rw', isa => 'LWP::UserAgent' );
has 'error' => ( is => 'rw', isa => 'Str' );
has 'type' => ( is => 'rw', isa => 'Str' );
has 'token' => ( is => 'rw', isa => 'Str' );
has 'last_request' => (is => 'rw', isa => 'HTTP::Request');

=head2 new

=cut

sub new {
    my ($class, %options) = @_;
   
    my $cache_key = $class->cache_entry(%options);

    return $handle_cache->{$cache_key} if $cache_key && $handle_cache->{$cache_key};

    my $self = $class->SUPER::new;

    if ($options{token}) {
        $self->type('user');
        $self->token($options{token});
    } elsif ($options{client_id}) {
        Carp::croak "You must supply both a client_id and client_secret to $class\->new!" unless $options{client_secret};
        $self->type('app');
        self->get_app_token($options{client_id}, $options{client_secret});
    } elsif ($options{public}) {
        $self->type('public');
    } else {
        Carp::croak "Not enough options to create new $class object.  Must specify one of token, client_id and client_secret, or public.";
    }
    
    $self->setup_useragent;
    
    $handle_cache->{$cache_key} = $self if $cache_key;

    return $self;
}

sub cache_entry {
    my ($self, %opts) = @_;
    
    return 'token:'.$opts{token} if $opts{token};
    return 'client_id:'.$opts{client_id} if $opts{client_id};
    return 'public' if $opts{public};
    return;
}

sub setup_useragent {
    my ($self) = @_;
    
    my $ua = LWP::UserAgent->new;
    
    $ua->timeout(15);
    $ua->agent("WWW::AppDotNet::API $VERSION");
    
    if ($self->token) {
        $ua->default_header(Authorization => 'Bearer '.$self->token);
    }
    
    $self->ua($ua);
}

sub request {
    my ($self, %options) = @_;
    
    $self->error('');
    
    my $request = $self->build_request(%options);
    
    my $response = $self->send_request($request);
    
    if ($response->code != 200) {
        $self->error($response->code." ".$response->message);
        return;
    }
    
    $self->last_request($request);
    
    return $self->process_response($response);
}

sub build_request {
    my ($self, %options) = @_;
    
    Carp::croak 'Insufficient parameters to build ADN Request object.' unless$options{url};
    
    my $path = ($options{url} =~ /^http/) ? $options{url} : $base_url.$options{url};
    
    my $request = HTTP::Request->new(
        ($options{method} || 'GET') => $path);
    if ($options{params}) {
      $request->uri->query_param($_ => $options{params}->{$_}) foreach keys %{$options{params}};
    }
    
    if ($request->method eq 'POST') {
        if ($options{json}) {
            my $j = JSON::Any->new;
            my $json = $j->objToJson($options{json});
            $request->content($json);
            $request->header('Content-Type' => 'application/json');
        } elsif ($options{formdata}) {
            $request->uri->query_form(%{$options{formdata}});
            #my $formdata = urlify_hash(%{$options{formdata}});
            #$request->content($formdata);
            #$request->header('Content-Type' => 'application/x-www-form-urlencoded');
        } else {
            Carp::croak 'POST request type specified but neither json nor formdata specified for content.';
        }
        #$request->header('Content-Length' => length($request->content));
    }
    
    return $request;
}

sub send_request {
    my ($self, $request) = @_;
    
    my $response = $self->ua->request($request);
}

sub process_response {
    my ($self, $response) = @_;
    
    my $j = JSON::Any->new;
    
    return $j->jsonToObj( $response->decoded_content );
}

sub api_request {
    my ($self, $method, $url, %args) = @_;
    
    Carp::cluck('Use of $api->api_request is deprecated.  Please use $api->request(%params) instead.');
    $self->request(url => $url, method => $method, %args);
}

sub paginated_request {
    my ($self, $type, $path, %opts) = @_;
    my %reqopts = $opts{params} ? %{$opts{params}} : ();
    $reqopts{count} ||= $opts{count} if $opts{count};
    if ($opts{all}) {
        #$reqopts{since_id} = 0;
        my @results;
        my $more = 1;
        while ($more) {
            my $response = $self->request(method => $type, url => $path, params => \%reqopts);
            return unless $response;
            $self->debug_log("Got ".scalar(@{$response->{data}})." responses.\n") if $self->{debug};
            push(@results, @{$response->{data}});
            $more = $response->{meta}->{more};
            $reqopts{before_id} = $response->{meta}->{min_id};
        }
        return wantarray ? @results : { data => \@results };
    } else {
         my $response = $self->api_request($type, $path, params => \%reqopts);
         return unless $response;
         return wantarray ? @{$response->{data}} : $response;
    }
}

sub get_app_token {
    my ($self, $id, $secret) = @_;

    my %postdata = (
        client_id => $id,
        client_secret => $secret,
        grant_type => 'client_credentials',
    );
    
    my $response = $self->request(method =>'POST', url => $app_token_url, formdata => \%postdata);

    if ($response) {
        $self->token($response->{access_token});
    } else {
        croak "Unable to retrieve app token: ".$self->error;
    }
}

sub urlify_hash {
    my (%params) = @_;
    my $data = join ('&', map { sprintf("%s=%s", $_, $params{$_}) } keys %params);
}

=head1 AUTHOR

Josh Ballard, C<< <josh at oofle.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-appdotnet-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-AppDotNet-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::AppDotNet::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-AppDotNet-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-AppDotNet-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-AppDotNet-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-AppDotNet-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Josh Ballard.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1; # End of WWW::AppDotNet::API
