#!/usr/bin/perl -T

use strict;
use warnings; 

use Data::Dumper qw(Dumper);

use WWW::AppDotNet::API;
use WWW::AppDotNet::Message;

use Test::More;

my $api = WWW::AppDotNet::API->new(public => 1);

my $response = WWW::AppDotNet::Message->fetch($api, { channel => 8564, message => 2181332 });

ok $response, "Fetched message 2181332";

ok $response->id, 'Has channel ID';
is $response->id, 2181332, 'Has ID 2181332';

ok $response->channel_id, 'Has channel ID';
is $response->channel_id, 8564, 'Channel has ID 8564';

ok $response->user, 'Has user';
is $response->user->username, 'baldown', 'Message has user username baldown';

done_testing;
