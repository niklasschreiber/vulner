use SOAP::Lite;
#arguments: [hostname] [username] [password] [relevance expression]
#hostname only, e.g. 'example.com' rather than 'http://example.com/webreports'
my $host = $ARGV[0];
my $username = SOAP::Data->name('username' => $ARGV[1] );
my $password = SOAP::Data->name('password' => $ARGV[2] );
my $expr = SOAP::Data->name('relevanceExpr' => $ARGV[3] );
my $service = SOAP::Lite -> uri( 'http://' . $host . '/webreports?wsdl' )
-> proxy('http://' . $host );
my $result = $service -> GetRelevanceResult( $expr, $username, $password );
if( $result->fault ) {
print "faultcode: " . $result->faultcode . "\n";
print "faultstring: " . $result->faultstring . "\n";
}
else {
  foreach my $answer ( $result->valueof( "//GetRelevanceResultResponse/a" ) ) {
    print $answer . "\n";
  }
}