# File::quotas
#
# Copyright (c) 2005 Charles Morris
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package File::quotas;

our %entries;
our $last_loaded_mp;
our $marker = pack("x32");
our $uids_read;

BEGIN {
  $VERSION = '0.20';
}

#---------- Constructor ----------#
sub new {
  my ($pkg, $mountPoint) = @_;

  my $instance = bless( {}, $pkg );

  if ($mountPoint)
  {
    load_quotas($instance, $mountPoint);
  }

return $instance;
}

##########################
#--- object functions ---#

# load_quotas()
# loads quota data
sub load_quotas
{
  my ($instance, $mountPoint) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  #if weve loaded into this variable before, null out the old stuff.
  if ( $last_loaded_mp )
  {
    null_data( $instance );
  }

  $last_loaded_mp = $mountPoint;

  open( $QUOTAS_HDL, "<$mountPoint/quotas" ); #will need to be OS specific. (solaris currently)

  for($uid = 0; read($QUOTAS_HDL, $bytes, 32) > 0; $uid++)
  {
  $bytes eq $marker and next;

    #if we get here, we know we have a valid entry- so lets record.

    $entries{$uid}{username} = getpwuid($uid); #this is so easy to get, should we put it in? it wastes space..

    ($entries{$uid}{blocks_hard},
     $entries{$uid}{blocks_soft},
     $entries{$uid}{blocks_used},
     $entries{$uid}{inodes_hard},
     $entries{$uid}{inodes_soft},
     $entries{$uid}{inodes_used},
     $entries{$uid}{grace_used},
     $entries{$uid}{grace_full} ) = unpack("L*", $bytes);

    $entries{$uid}{blocks_hard} = $entries{$uid}{blocks_hard} / 2; #the weird devided by 2 error.
    $entries{$uid}{blocks_soft} = $entries{$uid}{blocks_soft} / 2; #may be solaris speicific
  }

$uids_read = $uid;

return $instance;
}

# write_quotas()
# write a quotas file
sub write_quotas
{
  my ($instance, $mountPoint) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  #will need to be OS specific. (solaris currently)
  open( QUOTAS_HDL, ">$mountPoint/quotas" );

  for($uid = 0; $uid < $uids_read; $uid++)
  {
    if ( $entries{$uid} )
    {
      print QUOTAS_HDL pack("L*", ($entries{$uid}{blocks_hard} * 2),
                                  ($entries{$uid}{blocks_soft} * 2),
                                  $entries{$uid}{blocks_used},
                                  $entries{$uid}{inodes_hard},
                                  $entries{$uid}{inodes_soft},
                                  $entries{$uid}{inodes_used},
                                  $entries{$uid}{grace_used},
                                  $entries{$uid}{grace_full}
                           );
    }
    else
    {
      print QUOTAS_HDL $marker;
    }
  }

return $instance;
}

# null_data()
# nulls out data in $instance, normally when load_quotas() is called.
sub null_data()
{
  my ($instance) = shift;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  undef( %entries );
  undef( $last_loaded_mp );
  undef( $uids_read );

  our %entries;
  our $last_loaded_mp;
  our $uids_read;
}

sub display_quotas()
{
  my ($instance) = shift;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  foreach my $uid ( keys(%entries) )
  {
    print "Quotas for " . $entries{$uid}{username}. " ($uid):\n";
    
    print "disk blocks (U/S/H): " . $entries{$uid}{blocks_used} . '/' .
                                    $entries{$uid}{blocks_soft} . '/' .
                                    $entries{$uid}{blocks_hard}. "\n";
    
    print "index nodes (U/S/H): " . $entries{$uid}{inodes_used} . '/' .
                                    $entries{$uid}{inodes_soft} . '/' .
                                    $entries{$uid}{inodes_hard}. "\n";
  }

}

sub del_entry()
{
  my ($instance, $uid) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
  
  delete $entries{$uid};

return $instance;
}

sub set_entry()
{
  my ($instance, $uid, $blocks_soft, $blocks_hard, $inodes_soft, $inodes_hard) = @_;
  die "expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

  $entries{$uid}{blocks_used} = 0;
  $entries{$uid}{blocks_soft} = $blocks_soft;
  $entries{$uid}{blocks_hard} = $blocks_hard;

  $entries{$uid}{inodes_used} = 0;
  $entries{$uid}{inodes_soft} = $inodes_soft;
  $entries{$uid}{inodes_hard} = $inodes_hard;

return $instance;
}



1;

__END__

=head1 NAME

    File::quotas - Interface to quotas databases

=head1 SYNOPSIS

      use File::quotas;  

      $quotas = new File::quotas( );

      # to load data form existing mount point
      $quotas = new File::quotas('/mount/point/');

      $quotas->display_quotas();

      # add the quota on uid 10
      $quotas->set_entry(10, '75000', '100000', '75000', '100000');

      $quotas->write_quotas('/mount/point/');

=head1 DESCRIPTION

    File::quotas provides a perl interface to 'quotas' files.

=head1 USAGE

    new()

      Constructor.
      Returns new instance of File::quotas.


    display_quotas()

      Displays quota information once loaded in human-readable form.


    load_quotas()
      parameters:
        $mountPoint, mount point to read 'quotas' from, like /export/home.

      Decompresses quotas file and loads into object.


    write_quotas()
      parameters:
        $mountPoint, mount point to write 'quotas' to, like /export/home.

      Recompresses relevant object data into quotas file.

    set_entry()
      parameters:
        $uid, UID or username to apply quota to.
        $blocks_soft, soft disk block limit in bytes.
        $blocks_hard, hard disk block limit in bytes.
        $inodes_soft, soft index node limit in bytes.
        $inodes_hard, hard index node limit in bytes.

      Sets quota entry for UID

    del_entry()
      parameters:
        $uid, UID to delete quota.

      Deletes quota entry for UID

    null_data()

     Internal function, used for object reuse.

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make install

=head1 DEPENDENCIES

   none

=head1 BUGS

  All testing so far has been done on solaris.

  Other than that, all demons sighted have been expelled,
  see CHANGES document for more info.

=head1 AUTHORS

Copyright (C) 2005 Charles A Morris.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
