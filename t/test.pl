#!/usr/local/bin/perl

unshift @INC, '.';

my $myquotas;

# There are no reasons any of these tests should ever fail.
# Unless the current release is broken regex engine.
# we will see... ... ... :)

##  Test 1 -=- Can we load the File::quotas library?
require File::quotas;

$myquotas = new File::quotas();
my @result = $myquotas->load_quotas('./exampleQuotasFile');

$myquotas->display_quotas();

my @result = $myquotas->get_entry(10);
print '|'. $result[3] .'|'."\n"; #"'$$result[0]'\n";

  my @result = $myquotas->set_entry( 10, 100000, 150000, 100000, 150000);

$myquotas->display_quotas();

  my @result = $myquotas->write_quotas('./exampleQuotasFile2');
