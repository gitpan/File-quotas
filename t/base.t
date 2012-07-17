#!/usr/local/bin/perl

use Test;

BEGIN { plan tests => 7 }

unshift @INC, '.';

my $myquotas;

# There are no reasons any of these tests should ever fail.
# Unless the current release is broken regex engine.
# we will see... ... ... :)

##  Test 1 -=- Can we load the File::quotas library?
eval { require File::quotas; return 1; };
ok($@, '');
croak() if $@;

##  Test 2 -=- Can we instantiate a File::quotas ?
$myquotas = new File::quotas();
ok( $myquotas->isa('File::quotas') );


## Test 3 -=- Can we load the supplied quotas file?
eval{
  my @result = $myquotas->load_quotas('./t/exampleQuotasFile');
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');

## Test 4 -=- Is the quota on UID 10 correct?
eval{
  my @result = $myquotas->get_entry(10);
  return( $result[1] == 75000 && $result[2] == 100000 && $result[4] == 7500 && $result[5] == 100000 ) ? 1 : 0;
};
ok($@, '');

## Test 5 -=- Can we set a quota on uid 10?
eval{
  my @result = $myquotas->set_entry( 10, 100000, 150000, 100000, 150000);
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');

## Test 6 -=- Can we write the new quotas?
eval{
  unlink('./t/exampleQuotasFile2');
  my @result = $myquotas->write_quotas('./t/exampleQuotasFile2');
  return( defined $result[0] ) ? 1 : 0;
};
ok($@, '');

## Test 7 -=- Can we load the new quotas and is it correct?
eval{
  my @result = $myquotas->load_quotas('./t/exampleQuotasFile2');
  unlink('./t/exampleQuotasFile2');
  if( !defined $result[0] ){ return 0; }

  @result = $myquotas->get_entry(10);
  return( $result[1] == 100000 && $result[2] == 150000 && $result[4] == 100000 && $result[5] == 150000 ) ? 1 : 0;
};
ok($@, '');

#      $quotas = new File::quotas('/path/to/file/quotasFile');
#      $quotas->display_quotas();
      # add the quota on uid 10
#      $quotas->set_entry(10, '75000', '100000', '75000', '100000');
#      $quotas->write_quotas('/path/to/file/quotasFile');
