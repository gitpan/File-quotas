# File::quotas
#
# Copyleft 2005-2012 Charles Morris
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package File::quotas;

our %entries;
our $last_loaded_mp;
our $marker = pack("x32");
our $uids_read;

BEGIN { $VERSION = '0.30'; }

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
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

	#if we've loaded into this variable before, null out the old stuff.
	if ( $last_loaded_mp ){ null_data( $instance ); }

	my $pathToFile = ($mountPoint =~ /\/$/)? "$mountPoint/quotas" : $mountPoint;
	$last_loaded_mp = $pathToFile;

	open( $QUOTAS_HDL, "<$pathToFile" ); #will need to be OS specific. (solaris currently)
	for($uid = 0; read($QUOTAS_HDL, $bytes, 32) > 0; $uid++)
	{
		$bytes eq $marker and next;

 		$entries{$uid}{username} = getpwuid($uid); #this is so easy to get, should we put it in? it wastes space..
		#most likely not. However for backwards-compatibility it will stay.

		($entries{$uid}{blocks_hard},
		$entries{$uid}{blocks_soft},
		$entries{$uid}{blocks_used},
		$entries{$uid}{inodes_hard},
		$entries{$uid}{inodes_soft},
		$entries{$uid}{inodes_used},
		$entries{$uid}{grace_used},
		$entries{$uid}{grace_full} ) = unpack("L8", $bytes);

		$entries{$uid}{blocks_hard} /= 2; #the weird devided by 2 error.
		$entries{$uid}{blocks_soft} /= 2; #may be solaris speicific
	}
$uids_read = $uid;
return $instance;
}

# write_quotas()
# write a quotas file
sub write_quotas
{
	my ($instance, $mountPoint) = @_;
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

	#For reverse-compatibility, check if $mountPoint has a trailing slash.
	#If it does not, then it is a file. Otherwise, append "/quotas".
	my $pathToFile = ($mountPoint =~ /\/$/)? "$mountPoint/quotas" : $mountPoint;
	
	open my $QUOTAS_HDL, '>', $pathToFile or die "File::quotas: cannot open $pathToFile: $!\n";
	foreach my $uid (sort {$a<=>$b} keys %entries) {
		write_one_quota($instance, $QUOTAS_HDL, $uid);
	}
	close $QUOTAS_HDL;

return $instance;
}

sub write_one_quota {
	my ($instance, $QUOTAS_HDL, $uid) = @_;
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
	
	my $pos = $uid * 32;
	seek($QUOTAS_HDL, $pos, 0);

	print $QUOTAS_HDL pack("L8",
			($entries{$uid}{blocks_hard} * 2),
			($entries{$uid}{blocks_soft} * 2),
			$entries{$uid}{blocks_used},
			$entries{$uid}{inodes_hard},
			$entries{$uid}{grace_used},
			$entries{$uid}{grace_full}
		);

return $instance;
}

# null_data()
# nulls out data in $instance, normally when load_quotas() is called.
sub null_data()
{
	my ($instance) = shift;
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);

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
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
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
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
	delete $entries{$uid};
return $instance;
}

sub set_entry()
{
	my ($instance, $uid, $blocks_soft, $blocks_hard, $inodes_soft, $inodes_hard) = @_;
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
	$entries{$uid}{blocks_used} = 0;
	$entries{$uid}{blocks_soft} = $blocks_soft;
	$entries{$uid}{blocks_hard} = $blocks_hard;
	$entries{$uid}{inodes_used} = 0;
	$entries{$uid}{inodes_soft} = $inodes_soft;
	$entries{$uid}{inodes_hard} = $inodes_hard;
return $instance;
}

sub get_entry()
{
	my($instance, $uid) = @_;
	die "File::quotas: expecting a __PACKAGE__\n" unless $instance->isa(__PACKAGE__);
	return ($entries{$uid}{blocks_used}, $entries{$uid}{blocks_soft}, $entries{$uid}{blocks_hard}, $entries{$uid}{inodes_used}, $entries{$uid}{inodes_soft}, $entries{$uid}{inodes_hard});
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

      # OR, to load data from a specific path
      $quotas = new File::quotas('/path/to/file/quotasFile');

      $quotas->display_quotas();

      # add the quota on uid 10
      $quotas->set_entry(10, '75000', '100000', '75000', '100000');

      $quotas->write_quotas('/path/to/file/quotasFile');

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
        You can also pass a direct path instead of a mount point.

      Decompresses quotas file and loads into object.


    write_quotas()
      parameters:
        $mountPoint, mount point to write 'quotas' to, like /export/home.
        You can also pass a direct path instead of a mount point.

      Recompresses relevant object data into quotas file.

    set_entry()
      parameters:
        $uid, UID or username to apply quota to.
        $blocks_soft, soft disk block limit in bytes.
        $blocks_hard, hard disk block limit in bytes.
        $inodes_soft, soft index node limit in bytes.
        $inodes_hard, hard index node limit in bytes.

      Sets quota entry for UID

    write_one_quota()
      parameters:
        $mountPoint, mount point with 'quotas' file you wish to update,
        or an exact path to a quotas file.
	$uid, the UID (not username) with a new entry.
      
      Before calling this method, you *must* make the entry using
      set_entry() first. This is generally an internal function.

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

Copyleft 2005-2012 Charles A Morris.

Additional contributions from:
Jesse L Becker (jbecker@northwestern.edu)

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
