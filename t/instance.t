#!/usr/bin/perl -T

use strict;
use warnings;

use WWW::AppDotNet::API;

use Test::More;

my $api = WWW::AppDotNet::API->new(token => 'fake token here');

ok $api, "Created API object with fake token.";
is $api->type, 'user', "API know it is a user object.";

is ref($api->ua), 'LWP::UserAgent', "Built an LWP object";
like $api->ua->agent, qr/^WWW::AppDotNet::API/, 'US has proper agent value.';
is $api->ua->default_header('Authorization'), 'Bearer fake token here', 'UA properly configured for user auth to App.net';


done_testing;
