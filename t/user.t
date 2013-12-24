#!/usr/bin/perl -T

use strict;
use warnings; 

use Data::Dumper qw(Dumper);

use WWW::AppDotNet::API;
use WWW::AppDotNet::User;

use Test::More;

my $api = WWW::AppDotNet::API->new(public => 1);

my $response = WWW::AppDotNet::User->fetch($api, { user => 28848 });
#$api->request(url => '/users/28848');

ok $response, "Fetched user 28848";

ok $response->id, 'Has user ID';
is $response->id, 28848, 'User has ID 28848';

ok $response->username, 'Has user username';
is $response->username, 'baldown', 'User has username baldown';

done_testing;