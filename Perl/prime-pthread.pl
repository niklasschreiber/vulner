#!/usr/bin/perl
# prime-pthread, courtesy of Tom Christiansen

use v5.36;

use threads;
use Thread::Queue;

sub check_num ($upstream, $cur_prime) {
     my $kid;
     my $downstream = Thread::Queue->new();
     while (my $num = $upstream->dequeue()) {
         next unless ($num % $cur_prime);
         if ($kid) {
             $downstream->enqueue($num);
         } else {
             print("Found prime: $num\n");
             $kid = threads->create(\&check_num, $downstream, $num);
             if (! $kid) {
                 warn("Sorry.  Ran out of threads.\n");
                 last;
             }
         }
     }
     if ($kid) {
         $downstream->enqueue(undef);
         $kid->join();
     }
 }

my $stream = Thread::Queue->new(3..1000, undef);
check_num($stream, 2);