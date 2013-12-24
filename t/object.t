#!/usr/bin/perl -T

use strict;
use warnings; 

use Data::Dumper qw(Dumper);

use WWW::AppDotNet::API;

use Test::More;

my $api = WWW::AppDotNet::API->new(public => 1);

my $obj = WWW::AppDotNet::Test->fetch($api, 28848);

ok $obj, 'Got an object!';

my $response = $obj->json;

ok $response->{id}, 'Has user ID';
is $response->{id}, 28848, 'User has ID 28848';

ok $response->{username}, 'Has user username';
is $response->{username}, 'baldown', 'User has username baldown';

done_testing;

BEGIN {
    package WWW::AppDotNet::Test;
    
    use Moose;
    
    extends 'WWW::AppDotNet::Object';
    
    sub fetch_pragma {
        return 'users/';
    }
    
    1;
};
