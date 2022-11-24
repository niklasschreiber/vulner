#!/usr/bin/perl

use lib '../lib';
use Codestriker::Repository::RepositoryFactory;
use Codestriker::Repository::Subversion;
use Codestriker::FileParser::SubversionDiff;
use Codestriker::FileParser::PatchUnidiff;

my $rep = Codestriker::Repository::RepositoryFactory->get('svn://file/var/svn/repos/fbi2/trunk');
my $fh = new FileHandle;
#$fh->open("/home/sits/tamarama/topic4116821.txt") || die "Can't open file: $!\n";
#$fh->open("/home/sits/codestriker/test/testtopictexts/differing_binaries.patch") || die "Can't open file: $!\n";
$fh->open("/home/sits/codestriker/luke.txt") || die "Can't open file: $!\n";
#$fh->open("/home/sits/codestriker/topic.txt") || die "Can't open file: $!\n";
#$fh->open("/home/sits/codestriker/bin/check.txt") || die "Can't open file: $!\n";

my @chunks = Codestriker::FileParser::SubversionDiff->parse($fh, $rep);
#my @chunks = Codestriker::FileParser::PatchUnidiff->parse($fh);
foreach my $chunk (@chunks)
{
    print "filename $chunk->{filename} old line $chunk->{old_linenumber} new $chunk->{new_linenumber}\n";
#    print "TEXT: $chunk->{text}\n";
}
