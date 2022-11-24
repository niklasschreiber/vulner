static int
arm32_set_tp(struct thread *td, void *args)
{

#if __ARM_ARCH >= 6
	set_tls(args);
#else
	td->td_md.md_tp = (register_t)args;
	*(register_t *)ARM_TP_ADDRESS = (register_t)args;
#endif
	return (0);
}