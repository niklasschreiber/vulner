#!/usr/bin/perl

$count = 0;

START:
$count = $count + 1;

if( $count > 4 ) {
   print "Exiting program\n";
} else {
   print "Count = $count, Jumping to START:\n";
   goto START;
}