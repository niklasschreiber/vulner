#!/usr/bin/perl -t
=test comment
prova cmulti comment
=cut

#package Dog 2.0;  #  contenere anche la versione
use v5.14;
package student;	 # classe student
package student_NOK;	 # classe student

use warnings;

say "We can use v5.14's features here";
use 5.10;        # VIOLAZ 
use "5.10.1";        # VIOLAZ 
use '5.10';        # VIOLAZ 

use threads::shared;
use Thread::Queue;
use diagnostics -verbose;
use autodie; # VIOLAZ
use autodie qw(:all); # OK
use base "Foo"; # VIOLAZ
use AutoLoader;
use Pod::Html;  # VIOLAZ
use Pod::Html::Util; # OK
use UNIVERSAL qw(can);  # VIOLAZ
use LWP::UserAgent (); # VIOLAZ
use test;
use fields qw(foo bar _Foo_private); # VIOLAZ
use threads ('yield',
             'stack_size' => 64*4096,
             'exit' => 'threads_only',
             'stringify');
use Net::DNS; # VIOLAZ
use Net::DNS::Paranoid; # OK
use 'My/Perl/Module.pm';  # VIOLAZ
use My::Perl::Module;     #ok


$session = CGI::Session->new();
$session = "";

$var = $ENV{'ERROR'};
$port    = getservbyname("smtp", "tcp") || 25;
$global_config = $2;
$prop_file = $1;
$session = CGI::Session->new();

my $user="auser"; # VIOLAZ
my $password="abc123"; # VIOLAZ
my %args = (user => "$user", password => "$password"); 
my $sftp = Net::SFTP::Foreign->new(host=>$server,user=>$user,password=>$password) or die "unable to connect"; 

my $fetch_q = Thread::Queue->new();

exit;
print "123\n"; # VIOLAZ
exit if !$xyz;
print "123\n"; # ok
for ( 1 .. 10 ) {
    next;
    print 1; # VIOLAZ
}
for ( 1 .. 10 ) {
    next if $_ == 5;
    print 1; # ok
}

sub foo {
    my $bar = shift;
    return;
    print 1; # VIOLAZ
}

die;
print "123\n"; # VIOLAZ
die;
LABEL: print "123\n"; # ok, c’è la label
open(my $fh, "<", "input.txt")
    or die "Can't open < input.txt: $!";
print "123\n"; # VIOLAZ
croak;
do_something(); # VIOLAZ
croak;
sub do_something {} # ok, è una sub

sub PERL_D103 {
	sub PERL_D103_INNER {
	}
}

# VIOLAZ
format EMPLOYEE =
===================================
@<<<<<<<<<<<<<<<<<<<<<< @<< 
$name $age
@#####.##
$salary
===================================
.

sub sh {
	
	$bar = param ();
	$test = $bar;
	$dbh->do( $sql, undef, $bar, $test );  # VIOLAZ
	
	$arg = shift;  
	umask $arg; # VIOLAZ

	while (false)
	{
	}
	
	while (true)
	{
	}
	
	@output = ` ls $directory`;            #ok
	
}

sub shlongmethod_32car_test_CWE398LONG {
	
	@output = ` ls $directory`;            #ok
	$shlongmethod_32car_test_CWE398LONG_var = "";
}

sub other {
	
	foreach ( keys %{ $hash_ref } ){}           #ok
	$arg = shift;  
	system "/bin/echo", $arg; # VIOLAZ, $arg è Untrusted
	` ls $directory`;                      # VIOLAZ
	$output = ` ls $directory`;            #ok
	@output = ` ls $directory`;            #ok
	
}
sub perl_19_20
{
	eval "print $foo";        # VIOLAZ
	eval 'print $foo';        # VIOLAZ
	eval {print $foo};        # ok
	eval 'use Foo';             # ok
	eval 'require Foo';         # ok
	eval 'use Foo; blah;';      # VIOLAZ due statements
	eval 'require Foo; 2; 1;';  # VIOLAZ  3 statements

	open( $fh, '>output.txt' );          # VIOLAZ
	open( $fh, q{>}, 'output.txt' );     # ok
	open( $fh, 'foo.txt' );       # VIOLAZ
	open( $fh, '<', 'foo.txt' );  # OK

	$arg = shift;  
	$arg, `true`; # VIOLAZ


	$bar =$ARGV[2];  
	$baz = "1";
	my $sql = "INSERT INTO foo (bar, baz) VALUES ( $bar, $baz )";
	$sql ->execute( $bar, $baz );  # VIOLAZ $bar è Untrusted e non è stata validata
	$name = "Smith";
	$table = $ARGV[1];
	$dbh->do('INSERT INTO ' . $dbh->quote_identifier($table) . ' (id, name) VALUES '
		'(NULL, ' . $dbh->quote($name) . ')'); # VIOLAZ $table è Untrusted e non è stata validata

	my $sth = $dbh->prepare( $sql );
	$sth->execute( $sth, $baz );  # OK $sth è stata validata dalla prepare()
	$dbh->do( $sql, undef, $sth, $baz );  # OK $sth è stata validata dalla prepare()



}
sub useInTo {
	
	# VIOLAZ if-elsif-else
	if ($a == 1) { use Module; }
	if ($a == 1) { } elsif ($a == 2) { use Module; }
	if ($a == 1) { } else { use Module; }
	# VIOLAZ for/foreach
	for (1..$a) { use Module; }
	foreach (@a) { use Module; }
	 # VIOLAZ while
	while ($a == 1) { use Module; }
	 # VIOLAZ unless
	unless ($a == 1) { use Module; }
	 # VIOLAZ until
	until ($a == 1) { use Module; }
	 # VIOLAZ do-condition
	do { use Module; } if $a == 1;
	do { use Module; } while $a == 1;
	do { use Module; } unless $a == 1;
	do { use Module; } until $a == 1;
	 # VIOLAZ operator-do
	$a == 1 || do { use Module; };
	$a == 1 && do { use Module; };
	$a == 1 or do { use Module; };
	$a == 1 and do { use Module; };
	# VIOLAZ non-string eval
	eval { use Module; };

}
sub new {
    my $class = shift;
    my $self = bless {};          # # VIOLAZ
    my $self = bless {}, $class;  # ok
	
	$message = '';      # VIOLAZ
	$message = "";      # VIOLAZ
	$message = "     "; # VIOLAZ
	message = "27.168.125.126"; # VIOLAZ
	
	$str = "\x7F\x06\x22Z";                         # VIOLAZ
	use charnames ':full';
	$str = "\N{DELETE}\N{ACKNOWLEDGE}\N{CANCEL}Z";  # ok

    return $self;
	
	# a BEGIN block that gets executed at compile time.
	BEGIN { <...code...> }  # OK
	# an ordinary labeled block that gets executed at run time.
	BEGIN: { <...code...> } # VIOLAZ

	until ($foo ne 'blah') {          # VIOLAZ
	}

	no critic                     # VIOLAZ
	no critic ''                  # VIOLAZ
	no critic ()                  # VIOLAZ
	no critic qw()                # VIOLAZ k
	no critic   (Policy1, Policy2)  # ok
	no critic   (Policy1 Policy2)   # ok (can use spaces to separate)
	no critic qw(Policy1 Policy2)   # ok (the preferred style)
	use constant FOOBAR => 42;  # VIOLAZ
	
}


sub AUTOLOAD  # VIOLAZ
{
    print "AUTOLOAD is set to $AUTOLOAD\n";
    print "with arguments ", "@_\n";
	our @ISA = qw(Foo)
}


sub fetch {
	
	print "matched\n" if grep { print "$_\n"; $_&1 } 1..31  # VIOLAZ
	@matches = grep  /pattern/,    @list;        # VIOLAZ
	@matches = grep { /pattern/ }  @list;        #ok
	@mapped = map  transform($_),    @list;      # VIOLAZ
	@mapped = map { transform($_) }  @list;      #ok

		@files = <*.pl>;              # VIOLAZ
		@files = glob '*.pl';         # ok


	grep{ print frobulate($_) } @list;           # VIOLAZ
	print map{ frobulate($_) } @list;            #ok
	grep{ $_ = lc $_ } @list;                    # VIOLAZ
	for( @list ){ $_ = lc $_  };                 #ok
	map{ push @frobbed, frobulate($_) } @list;   # VIOLAZ
	@frobbed = map { frobulate($_) } @list;      #ok

    while (defined( my $job = $fetch_q->dequeue() )) {
        if ($job) {
            print threads->tid, " Starting to sleep\n";
            sleep(5); # VIOLAZ
            print threads->tid, " Finished sleeping\n";
        }
        else {
            print threads->tid, " Starting to sleep\n";
            sleep(10); # VIOLAZ
            print threads->tid, " Finished sleeping\n";
        }
    }
	
	my $now_string = localtime;  # e.g., "Thu Oct 13 04:54:34 1994"
	
	my $x :shared = 4;
	my $y :shared = 'foo';
	my $thr1 = threads->create(sub {
		lock($x); # VIOLAZ
		sleep(20);
		lock($y);  # VIOLAZ
	});
	my $thr2 = threads->create(sub {
		lock($y); # VIOLAZ
		sleep(20);
		lock($x); # VIOLAZ
	});
	
	select undef, undef, undef, 0.25;         # VIOLAZ
	
	@patron_IDs = sort { 
		&fines($b) <=> &fines($a) or 
		$items{$b} <=> $items{$a} or 
		$family_name{$a} cmp $family_name{$a} or 
		$personal_name{$a} cmp $family_name{$b} or
		$a <=> $b 
		} @patron_IDs;  # VIOLAZ

		open FH, '<', $some_file;           # VIOLAZ
		open STDIN, '<', $some_file;       #ok
		open my $fh, '<', $some_file;       #ok
		open our $fh, '<', $some_file;       #ok

		my $passwd = prompt 'Password:'; # VIOLAZ
		my $passwd_ok = prompt 'Password:', -echo=>'*'; #ok
		
		select((select($fh), $|=1)[0]);     # VIOLAZ
		select $fh;                         # VIOLAZ
		
		for (<>){};
		for my $line ( <$file_handle> ){ do_something($line) }      # VIOLAZ
		foreach ( <$file_handle>) { # VIOLAZ
			print "\$_ is $_";
			}

		our @EXPORT      = qw(foo $bar @baz);                  # VIOLAZ
		our @EXPORT_OK   = qw(foo $bar @baz);                  # ok
		our %EXPORT_TAGS = ( all => [ qw(foo $bar @baz) ] );   # ok

}

sub PERL_33
{
	enable diagnostics;
	$arg = $2;  # $arg diventa UNTRUSTED
	open(FOO, "< $arg");  #  OK <FOO> TRUSTED è in sola lettura
	open(FOO, '<', '$arg');  # OK <FOO> TRUSTED è in sola lettura
	open(FOO, "> $arg") or die "Couldn't open file file.txt, $!";  # VIOLAZ <FOO> UNTRUSTED (> significa in scrittura)
	open(FOO, ">> $arg");  # VIOLAZ <FOO> UNTRUSTED (>> significa in append)
	sysopen(FOO, "$arg", O_RDWR|O_TRUNC);  # VIOLAZ <FOO> UNTRUSTED
	use open ':encoding(utf8)'; # OK c’è la use davanti

	open (HTML, "/usr/bin/txt2html /usr/stats/$username|");  # VIOLAZ
	open (HTML, "-|"); # OK
	@ISA = qw(AutoLoader);
	$PROGRAM_NAME = "test"; # VIOLAZ
	($PROGRAM_NAME, "test"); # VIOLAZ
	$0 = 'test'; # VIOLAZ
	($0, 'test'); # VIOLAZ
	$( = 10235; # VIOLAZ
	$( = 10235+0; # OK
	('$(', 10235); # VIOLAZ
	warn "No PerlIO!\n" if "$]" < 5.008;  # VIOLAZ
	$EXECUTABLE_NAME;
}

sub test (@@)
	{
	}	
	

sub read_file {
    my $file = shift;
    -f $file || return undef;  # VIOLAZ
    #Continue reading file...
	
	return sort @list;  # VIOLAZ
	@sorted_list = sort @list;
	return @sort        # ok
	no strict 'refs'; # VIOLAZ

	my @a;
	{
		no warning;
		my $b = @a[0];
	}

}


sub Other 
{
	$expr=$ARGV[1];  
	my $v = eval "use utf8; '$expr'";  # VIOLAZ $expr è untrusted

	$user = $ARGV[1];
	$password = $ARGV[2];
	$dbh = DBI->connect($dsn, $user, $password,
                    { RaiseError => 1, AutoCommit => 0 });  # VIOLAZ $user e $password sono untrusted
	my $self = shift if UNIVERSAL::isa($_[0], __PACKAGE__);  # VIOLAZ
	print UNIVERSAL::isa($a,"CGI");  # VIOLAZ
	UNIVERSAL::VERSION = '5.10';
	print "$user";
	syswrite "$user";
	
	my $foo = new Foo; # VIOLAZ
	my $foo = Foo->new; # OK

	push @$array_ref, 'foo', 'bar', 'baz';      # VIOLAZ
	push @{ $array_ref }, 'foo', 'bar', 'baz';  #ok
	foreach ( keys %$hash_ref ){}               # VIOLAZ
	foreach ( keys %{ $hash_ref } ){}           #ok


	$arg = shift;  
	system "/bin/echo", $arg; # VIOLAZ, $arg è Untrusted
	system "echo $arg";	 # VIOLAZ, $arg è Untrusted
	exec "echo $arg"; # VIOLAZ
	exec "echo", $arg; # VIOLAZ
	exec "sh", '-c', $arg; # VIOLAZ
	
	unlink $data, $arg; # VIOLAZ
	rename ("/usr/test/file1.txt", "$arg" ); # VIOLAZ
	umask $arg; # VIOLAZ
	do "$arg";  # VIOLAZ
	do sub($var1); # VIOLAZ 
	$obj->$method(@args);  # VIOLAZ 
	print $`, $&, $'; # VIOLAZ
	$^H;
	${^OPEN} ;
}
sub foo
{

	&{$foo}(@args);
	$foo->(@args);

}
sub PERL_18
{
	
	$website = <STDIN>;
	$ldap = Net::LDAP->new( '$website' )  or  die "$@"; # VIOLAZ $website è untrusted, $ldap diventa untrusted
	$ldap = Net::LDAP->new( 'ldap.example.com' )  or  die "$@";  # OK
	$srch = $ldap->search( base   => "c=US",     # VIOLAZ $ldap è untrusted
						   filter => "(&(sn=Barr)(o=Texas Instruments))"
						 );
	$ldap2 = $ARGV[1];  
	$mesg = $ldap->bind( 'cn=root, o=University of Michigan, c=us',
						 password => 'secret'
					   );  # OK
	$mesg = $ldap->bind( 'cn=$ldap2, o=University of Michigan, c=us',
						 password => 'secret'
					   );  # VIOLAZ $ldap2 è untrusted

	$result = $ldap->add( 'cn=Barbara Jensen, o=University of Michigan, c=US',
						  attrs => [
							cn          => [$ldap2, 'Barbs Jensen'],
							sn          => 'Jensen',
							mail        => 'b.jensen@umich.edu',
							objectclass => ['top', 'person',
											'organizationalPerson',
											'inetOrgPerson' ],
						  ]
						);  # VIOLAZ $ldap2 è untrusted
	$mesg = $ldap->compare( $dn,
							attr  => 'cn',
							value => '$ldap2'
						  ); # VIOLAZ $ldap2 è untrusted
	$dn = $ARGV[2];  
	$mesg = $ldap->delete( $dn ); # VIOLAZ $dn è untrusted
	$mesg = $ldap->moddn( $dn, newrdn => 'cn=Graham Barr' ); # VIOLAZ $dn è untrusted
	$mesg = $ldap->modify( $dn,
	  add => {
		description => 'List of members',    # Add description attribute
		member      => [
		  'cn=member1,ou=people,dc=example,dc=com',    
		  'cn=member2,ou=people,dc=example,dc=com',
		]
	  }
	); # VIOLAZ $dn è untrusted
	$capath = $ARGV[3];  

	$mesg = $ldap->start_tls(
							  verify => 'require',
							  clientcert => 'mycert.pem',
							  clientkey => 'mykey.pem',
							  keydecrypt => sub { 'secret'; },
							  capath => '$capath'
							);  # VIOLAZ $capath è untrusted

}
sub PERL_02 # 
{
	my $user="auser"; # VIOLAZ
	my $class = shift;
	my $self = {
				_StudentFirstName => shift;
				_StudentLastName => shift;
	};
				
	print "Student's First Name is $self ->{_StudentFirstName}\n";
	print "Student's Last Name is $self ->{_StudentLastName}\n";
	bless $self, $class;
	return $self;
	
	my @l = (1..4);
	say @l[9]; # VIOLAZ
	print @l[9]; # VIOLAZ
	my $x = @l[9];  # VIOLAZ
	my @ages = (25, 30, 40);
	
	print @ages[7]; # VIOLAZ
	
}

sub PERL_17
{
	$r = HTTP::Response->new( $code );
	$value = <>;
	$r->header( $field => $value ); # VIOLAZ
	
	$r = HTTP::Response->parse( $str );
	$r->header( $field => $value ); # VIOLAZ

}
sub PERL_16
{
	$node = <>;
	my $xp = XML::XPath->new( context => $node ); # VIOLAZ $node è untrusted
	my $nodeset = $xp->find( shift @ARGV ); # VIOLAZ
	print XML::XPath::XMLParser::as_string( $node ) . "\n"; # VIOLAZ
	my $node_cnt = $xp->findvalue("count($node)");  # VIOLAZ
	my @node_cnt = $xp->findnodes("count($node)");  # VIOLAZ

}
sub PERL_14
{
	$query = $ENV{'QUERY'};
	$session->param('f_name', '$var'); # VIOLAZ
	$session->param(-name=>'l_name', -value=>$var); # VIOLAZ
	$s = CGI::Session->new("driver:db_file", $query); # VIOLAZ
	$batch_url = "https://www.example.com/";
	my $r = HTTP::Request->new('POST', $batch_url, [
		'Accept-Encoding' => 'gzip',
		# if we don't provide a boundary here, HTTP::Message will generate
		# one for us. We could use UUID::uuid() here if we wanted.
		'Content-Type' => 'multipart/mixed; boundary=END_OF_PART'
	]);
	$r->add_part($var, $query); # VIOLAZ

}
sub PERL_09_11
{
	$username = $1;
	$stats = `cat /usr/stats/$username`; # VIOLAZ
	my $ua = LWP::UserAgent->new(timeout => 10); # VIOLAZ

	my $dns = Net::DNS::Paranoid->new; # OK
	print Net::DNS->version, "\n"; # VIOLAZ
	$time = 30;
	$session->expire(60); # VIOLAZ
	$time1 = 10;
	$session->expire($time1); 
	$time1 = 80;
	$session->expire($time1); # VIOLAZ

	redirect '/error?This%20$var'; # VIOLAZ

}
sub PERL_08
{
	rand();
}
sub PERL_07
{
	$filename = '/path/to/your/file.doc';
	if (-e $filename) {  # VIOLAZ
		print "File Exists!";
	}
	unless (-e $filename) { # VIOLAZ
		print "File Doesn't Exist!";
	}

}
sub PERL_06 
{
	my $cipher = Crypt::GCrypt->new(
	  type => 'cipher',
	  algorithm => 'aes',  # VIOLAZ
	  mode => 'cbc'
	);

		my @foo = sort { $b cmp $a } @bar;         # VIOLAZ
		my @foo = reverse sort @bar;               #ok
		my @foo = sort { $b <=> $a } @bar;         # VIOLAZ
		my @foo = reverse sort { $a <=> $b } @bar; #ok

		my @result = map {   # VIOLAZ
			my @digits = split //, $_; 
			if ($digits[-1] == 4) { 
			@digits; 
			} else { 
			(  );
			}
		} @input_numbers; 

		my @result = map { split //, $_ } @input_numbers;  # OK
		
		substr($something, 1, 2) = $newvalue;     # VIOLAZ
		substr($something, 1, 2, $newvalue);      # ok

		@names = split '|', $string; # VIOLAZ
		@names = split m/[|]/, $string; #ok

		print UNIVERSAL::can($obj, 'Foo::Bar') ? 'yes' : 'no';  # VIOLAZ
		print eval { $obj->can('Foo::Bar') } ? 'yes' : 'no';    #ok
		print UNIVERSAL::isa($obj, 'Foo::Bar') ? 'yes' : 'no';  # VIOLAZ
		print eval { $obj->isa('Foo::Bar') } ? 'yes' : 'no';    #ok

		for ( @list ) {
		if ( length( $_ ) == 4 ) { my $size = -s; }} # VIOLAZ
		for ( @list ) {
		if ( length == 4 ) { my $size = -s; }} # OK
		for ( @list ) {
		my @args = split /\t/, $_;}  # VIOLAZ
		for ( @list ) {
		my @args = split /\t/;}  # OK
		for ( @list ) {
		my $backwards = reverse $_;} # VIOLAZ
		for ( @list ) {
		my $backwards = reverse;} # OK


}
sub PERL_05
{
	my $prkey = Crypt::Perl::RSA::Generate::generate(258); # VIOLAZ
	my $prkey = Crypt::Perl::RSA::Generate::generate(2048); # OK
	open (my($fh), $ARGV[0]) or die "Could not open myself! $!";  # VIOLAZ


}


sub PERL_04 {

    my ($host, $port) = @_;
	$*;
	$#;
	$[=4;
	${^ENCODING};
	${^WIN32_SLOPPY_STAT};
	${^UTF8CACHE};
	$PROCESS_ID = 1037; # VIOLAZ
	($PROCESS_ID, 1037); # VIOLAZ

	$host = hostname(); # OK
	$host = hostname("argument"); # VIOLAZ
	$host = hostname($var); # VIOLAZ
	File::Glob::glob();
	goto LINE;

    return IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => 5326
    ) || die "Unable to connect to $host:$port: $!";


	LINE: for ($i=0; defined($i); $i++) {
	flock(FILE,2) or next LINE;
	}
}

	$portNumeric = 9040;
	$sock = IO::Socket::INET->new( PeerAddr => 'localhost',
                               PeerPort => $portNumeric, # VIOLAZ
                               LocalPort => 9000,         # VIOLAZ      
                               Proto     => 'tcp')
                               or die "\nunable to bind on localhost : $port...";



sub PERL_03
{

	my $user_config = Config::Properties->new(file => '/home/jsmith/.foo/foo.properties',
											  defaults => $global_config); # VIOLAZ
	my $config = Config::Properties->new(file => $prop_file,
												defaults => \%defaults); # VIOLAZ
	$value = $3;
	$properties->setProperty('DOMAIN', $value); # VIOLAZ
	$key = <>;
	$properties->setProperty($key, 'trustdomain1'); # VIOLAZ

	require 5.6.0;  # OK 
	require "5.6.0";  # OK
	require 5.2.8;  # OK 
	require "5.2.8";  # OK
	use 5.1.0;  # VIOLAZ
	require 5.1.0;  # VIOLAZ
	require "5.1.0";  # VIOLAZ
	require 5.006;  # VIOLAZ
	require "5.006";  # VIOLAZ
	use "5.006";  # VIOLAZ
	require 4.000;  # VIOLAZ
	require "4.000";  # VIOLAZ
	require 3.000;  # VIOLAZ
	require "3.000";  # VIOLAZ
	require 2.000;  # VIOLAZ
	require "2.000";  # VIOLAZ
	require 1.000;  # VIOLAZ
	require "1.000";  # VIOLAZ

	use v5.14;
	say "We can use v5.14's features here";
	use 5.10;        # VIOLAZ 
	use "5.10.1";        # VIOLAZ 
	use '5.10';        # VIOLAZ 

}

# Object creating and constructor calling
my $Data = new student_data student("Geeks","forGeeks");
 
# Printing the data
print "$Data->{'StudentFirstName'}\n";
print "$Data->{'StudentLastName'}\n";


