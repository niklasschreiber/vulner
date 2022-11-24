void shared_mutex::imp_wait()
{
#ifdef _WIN32
	NtWaitForKeyedEvent(nullptr, &m_value, false, nullptr);
#else
	while (true)
	{
		// Load new value, try to acquire c_sig
		auto [value, ok] = m_value.fetch_op([](u32& value)
		{
			if (value >= c_sig)
			{
				value -= c_sig;
				return true;
			}

			return false;
		});

		if (ok)
		{
			return;
		}

		futex(reinterpret_cast<int*>(&m_value.raw()), FUTEX_WAIT_BITSET_PRIVATE, value, nullptr, nullptr, c_sig);
	}
#endif
}
int futex_wait(fsem_t* p, const timespec* end_time)
 {
   int err = 0;
   timespec remain;
   if (decrement_if_positive(&p->val_) > 0)
   {}
   else
   {
     __sync_fetch_and_add(&p->nwaiters_, 1);
     while(1)
     {
       calc_remain_timespec(&remain, end_time);
       if (remain.tv_sec < 0)
       {
         err = ETIMEDOUT;
         break;
       }
       if (0 != futex(&p->val_, FUTEX_WAIT, 0, &remain, NULL, 0))
       {
         err = errno;
       }
       if (0 != err && EWOULDBLOCK != err && EINTR != err)
       {
         break;
       }
       if (decrement_if_positive(&p->val_) > 0)
       {
         err = 0;
         break;
       }
     }
     __sync_fetch_and_add(&p->nwaiters_, -1);
   }
   return err;
 }