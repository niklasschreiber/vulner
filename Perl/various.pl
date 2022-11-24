#!/usr/bin/perl	
	$arg = shift;		# $arg is UNTRUSTED
    $hid = $arg . 'bar';	# $hid is also UNTRUSTED
    $line = <>;			# UNTRUSTED
    $line = <STDIN>;		# Also UNTRUSTED
    open FOO, "/home/me/bar" or die $!;
    $line = <FOO>;		# Still UNTRUSTED
    $path = $ENV{'PATH'};	# UNTRUSTED, but see below
    $data = 'abc';		# Not UNTRUSTED

    system "echo $arg";		# Insecure
    system "/bin/echo", $arg;	# Considered insecure
				# (Perl doesn't know about /bin/echo)
    system "echo $hid";		# Insecure
    system "echo $data";	# Insecure until PATH set

    $path = $ENV{'PATH'};	# $path now UNTRUSTED

    $ENV{'PATH'} = '/bin:/usr/bin';
    delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

    $path = $ENV{'PATH'};	# $path now NOT UNTRUSTED
    system "echo $data";	# Is secure now!

    open(FOO, "< $arg");	# OK - read-only file
    open(FOO, "> $arg"); 	# Not OK - trying to write

    open(FOO,"echo $arg|");	# Not OK
    open(FOO,"-|")
	or exec 'echo', $arg;	# Also not OK

    $shout = `echo $arg`;	# Insecure, $shout now UNTRUSTED

    unlink $data, $arg;		# Insecure
    umask $arg;			# Insecure

    exec "echo $arg";		# Insecure
    exec "echo", $arg;		# Insecure
    exec "sh", '-c', $arg;	# Very insecure!

    @files = <*.c>;		# insecure (uses readdir() or similar)
    @files = glob('*.c');	# insecure (uses readdir() or similar)

    # In either case, the results of glob are UNTRUSTED, since the list of
    # filenames comes from outside of the program.

    $bad = ($arg, 23);		# $bad will be UNTRUSTED
    $arg, `true`;		# Insecure (although it isn't really)