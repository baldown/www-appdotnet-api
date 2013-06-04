package WWW::AppDotNet::API;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp qw(cluck croak);
use LWP::UserAgent;
use JSON::Any;

our $base_url = 'https://alpha-api.app.net/stream/0/';
our $app_token_url = 'https://account.app.net/oauth/access_token';

=head1 NAME

WWW::AppDotNet::API - Module for accessing the App.net API.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::AppDotNet::API;

    my $foo = WWW::AppDotNet::API->new();
    ...

=head1 SUBROUTINES/METHODS

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = {
        ua => LWP::UserAgent->new(),
        url_base => $opts{base_url} || $base_url,
        error => undef,
        
    };
    $self = bless $self, $class;
    
    $self->{ua}->timeout(15);
    $self->{ua}->agent("WWW::AppDotNet::API $VERSION");

    if ($opts{token}) {
        $self->{token} = $opts{token};
    } elsif ($opts{client_id} && $opts{client_secret}) {
        $self->{token} = $self->get_app_token($opts{client_id}, $opts{client_secret});
    } else {
        croak("Unable to initialize $class: no token or client id and secret provided.");
        return;
    }
    
    return $self;
}

sub api_request {
    my ($self, $type, $path, %opts) = @_;

    if ($opts{params}) {
        $path .= '?' . urlify_hash(%{$opts{params}});
    };

    my $request = HTTP::Request->new(
        $type => ($path =~ /^http/) ? $path : $self->{url_base}.$path
    );
    
    $request->header(Authorization => 'Bearer '.$self->{token}) if $self->{token};
    
    if ($type eq 'POST' && $opts{formdata}) {
        my $formdata = urlify_hash(%{$opts{formdata}});
        $request->content($formdata);
        $request->header('Content-Length' => length($formdata));
        $request->header('Content-Type' => 'application/x-www-form-urlencoded');
    }

    my $response = $self->{ua}->request($request);
    
    if ($response->code != 200) {
        # XXX set error
        $self->{error} = $response ->code." ".$response->message." ".$response->as_string;
        return;
    }
    
    my $j = JSON::Any->new;
    
    return $j->jsonToObj( $response->decoded_content );
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
            my $response = $self->api_request($type, $path, params => \%reqopts);
            return unless $response;
            warn "Got ".scalar(@{$response->{data}})." responses.\n";
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
    
    my $response = $self->api_request('POST', $app_token_url, formdata => \%postdata);

    if ($response) {
        $self->{token} = $response->{access_token};
    } else {
        croak "Unable to retrieve app token: ".$self->last_error;
    }
}

sub as_user {
    my ($self, $token) = @_;
    
    my %usercall = %$self;
    
    $usercall{token} = $token;
    $usercall{error} = undef;
    
    return bless \%usercall, ref($self);
}

sub urlify_hash {
    my (%params) = @_;
    my $data = join ('&', map { sprintf("%s=%s", $_, $params{$_}) } keys %params);
}

sub last_error {
    my ($self) = @_;
    return $self->{error};
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

1; # End of WWW::AppDotNet::API
