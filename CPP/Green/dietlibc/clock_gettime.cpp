int
sleeptest(int (*test)(struct timespec *, struct timespec *),
	   bool subsec, bool sim_remain)
{
	struct timespec tsa, tsb, tslp, tremain;
	int64_t delta1, delta2, delta3, round;

	sig = 0;
	signal(SIGALRM, sigalrm);

	if (subsec) {
		round = 1;
		delta3 = FUZZ;
	} else {
		round = 1000000000;
		delta3 = round;
	}

	tslp.tv_sec = delta3 / 1000000000;
	tslp.tv_nsec = delta3 % 1000000000;

	while (tslp.tv_sec <= MAXSLEEP) {
		/*
		 * disturb sleep by signal on purpose
		 */ 
		if (tslp.tv_sec > ALARM && sig == 0)
			alarm(ALARM);

		clock_gettime(CLOCK_REALTIME, &tsa);
		(*test)(&tslp, &tremain);
		clock_gettime(CLOCK_REALTIME, &tsb);

		if (sim_remain) {
			timespecsub(&tsb, &tsa, &tremain);
			timespecsub(&tslp, &tremain, &tremain);
		}

		delta1 = (int64_t)tsb.tv_sec - (int64_t)tsa.tv_sec;
		delta1 *= BILLION;
		delta1 += (int64_t)tsb.tv_nsec - (int64_t)tsa.tv_nsec;

		delta2 = (int64_t)tremain.tv_sec * BILLION;
		delta2 += (int64_t)tremain.tv_nsec;

		delta3 = (int64_t)tslp.tv_sec * BILLION;
		delta3 += (int64_t)tslp.tv_nsec - delta1 - delta2;

		delta3 /= round;
		delta3 *= round;

		if (delta3 > FUZZ || delta3 < -FUZZ) {
			if (!sim_remain)
				atf_tc_expect_fail("Long reschedule latency "
				    "due to PR kern/43997");

			atf_tc_fail("Reschedule latency %"PRId64" exceeds "
			    "allowable fuzz %lld", delta3, FUZZ);
		}
		delta3 = (int64_t)tslp.tv_sec * 2 * BILLION;
		delta3 += (int64_t)tslp.tv_nsec * 2;

		delta3 /= round;
		delta3 *= round;
		if (delta3 < FUZZ)
			break;
		tslp.tv_sec = delta3 / BILLION;
		tslp.tv_nsec = delta3 % BILLION;
	}
	ATF_REQUIRE_MSG(sig == 1, "Alarm did not fire!");

	atf_tc_pass();
}