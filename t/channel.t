#!/usr/bin/perl -T

use strict;
use warnings; 

use Data::Dumper qw(Dumper);

use WWW::AppDotNet::API;
use WWW::AppDotNet::Channel;

use Test::More;

my $api = WWW::AppDotNet::API->new(public => 1);

my $response = WWW::AppDotNet::Channel->fetch($api, { channel => 8564 });

ok $response, "Fetched channel 8564";

ok $response->id, 'Has channel ID';
is $response->id, 8564, 'Channel has ID 8564';

ok $response->owner, 'Has owner user';
is $response->owner->username, 'baldown', 'Channel has owner username baldown';

done_testing;
