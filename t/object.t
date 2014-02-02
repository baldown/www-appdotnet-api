#!/usr/bin/perl -T

use strict;
use warnings; 

use Data::Dumper qw(Dumper);

use WWW::AppDotNet::API;

use Test::More;

my $api = WWW::AppDotNet::API->new(public => 1);

my $obj = WWW::AppDotNet::Test->fetch($api, 8564, 2181332);

ok $obj, 'Got an object!';

my $response = $obj->json;

ok $response->{id}, 'Has ID';
is $response->{id}, 2181332, 'Message has ID 2181332';
is $response->{channel_id}, 8564, 'Message has right channel ID';;

my @objs = WWW::AppDotNet::Test->fetch($api, 8564)->all;

ok scalar(@objs), 'Got back multiple results.';

is ref($obj), ref($objs[0]), 'Same type of object returned.';
is $objs[0]->json->{channel_id}, 8564, 'Result has right channel ID';

done_testing;

BEGIN {
    package WWW::AppDotNet::Test;
    
    use Moose;
    
    extends 'WWW::AppDotNet::Object';
    
    sub fetch_pragma {
        return 'channels//messages/';
    }
    
    1;
};
