my $type="mysql";
my $database="database_one";
my $host="localhost";
my $port="3306";
my $user="root";
my $pwd="*****";
my $dsn="dbi:$type:$database:$host:$port";
my $connect=DBI->connect($dsn,$user,$pwd);

>> HTML CODE HERE <<

$query=qq{SELECT * FROM login WHERE username=? AND password=?};
$queryhandle=$connect->prepare($query);
my $login=$queryhandle->execute($param{username},$param{password});
if($login!=0){
 ...
}else{
 ...
}

Post - Code

>>HTML CODE HERE<<
$query=qq{INSERT INTO feed(details,name,date)VALUES(?,?,?)};
$queryhandle=$connect->prepare($query);
$queryhandle->execute("$postparam{details}","$postparam{name}","$postp
+aram{date}");
$queryhandle->finish;

my $query="Select * FROM users where username =".$dbh->quote(param('username')) . " and password =".$dbh->quote(param('password')); 

my $sth = $dbh->prepare($query);
$sth->execute();

# Perl's DBI, available on the CPAN, supports parameterized SQL calls. 
# Both the do method and prepare method support parameters ("placeholders", 
# as they call them) for most database drivers. For example:
$sth = $dbh->prepare("SELECT * FROM users WHERE email = ?");
foreach my $email (@emails) {
    $sth->execute($email);
    $row = $sth->fetchrow_hashref;
    [...]
}
#However, you can't use parameterization for identifiers 
# (table names, column names) so you need to use DBI's 
# quote_identifier() method for that:
# Make sure a table name we want to use is safe:
my $quoted_table_name = $dbh->quote_identifier($table_name);

# Assume @cols contains a list of column names you need to fetch:
my $cols = join ',', map { $dbh->quote_identifier($_) } @cols;

my $sth = $dbh->prepare("SELECT $cols FROM $quoted_table_name ...");
