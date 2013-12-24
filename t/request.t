#!/usr/bin/perl -T

use strict;
use warnings; 

use Data::Dumper qw(Dumper);

use WWW::AppDotNet::API;

use Test::More;

my $api = WWW::AppDotNet::API->new(public => 1);

my $response = $api->request(url => '/users/28848');

ok $response, "Fetched user 28848";

ok exists $response->{data}, 'Has data section';
ok exists $response->{meta}, 'Has meta section';

ok $response->{data}->{id}, 'Has user ID';
is $response->{data}->{id}, 28848, 'User has ID 28848';

ok $response->{data}->{username}, 'Has user username';
is $response->{data}->{username}, 'baldown', 'User has username baldown';

done_testing;