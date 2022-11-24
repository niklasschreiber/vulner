int main(int argc, char *argv[]) 
{ 
	pid_t pid, ppid, childpid, w;                 		 // For process ID, parent process ID, child process, and wait
	pid_t leader = getpid();							 // Used to make sure the child process finishes before the parent is killed
	int semid, semop_ret, sem_value, i, j, opt;			 // Semaphore ID, Semaphore value, i and j for for statement, and Semaphore option
	int N, status, k;									 // Number of processes, the status for wait, and the delay paramater
	char buf_num[MAX_CANON], *c_ptr;					 // Character buffer and pointer to navigate it
	key_t ipc_key; 										 // Key for Semaphore
	struct semid_ds sem_buf;							 // Allows access for Semaphore set and reference to the array of type sem 	

	/* Check input arguments are 4 */
	if (argc != 4)
	{
		printf("Invalid input.  The number of arguments must be 4.\n");
		exit(1);
	}
	/* Make sure number of precesses is more than 0 */
	if(atoi(argv[1]) > 0)
	{
		N = atoi(argv[1]);
	}
	else
	{
		printf("Invalid input. %d(N) must be greater then 0.\n", atoi(argv[1]));
		exit(1);
	}

	/* Declare the operation for semaphore protection */
	if (strcmp(argv[2], "n") == 0) /* No semaphore protection */		
	{
		opt = 0;
	}
	else if (strcmp(argv[2], "s") == 0) /* Semaphore protection */
 	{
 		opt = 1;
 	}
 	else
	{
		printf("Invalid input for the second argument. %s should be 'n' or 's'.\n", argv[1]);
		exit(1);
	}

	/* Initialize the delay parameter, 'k', if it is greater than 0 */
	if(atoi(argv[3]) > 0)
		k = atoi(argv[3]);
	else
	{
		printf("Invalid input. %d(k) must be greater then 0.\n", atoi(argv[3]));
		exit(1);
	}

	/* Decalre semaphore wait and increment */
	struct sembuf semwait[1]; 
 	struct sembuf semsignal[1];

 	/* Initialize semaphore element to 1 */ 
 	set_sembuf_struct(semwait, 0, -1, 0); 
 	set_sembuf_struct(semsignal, 0, 1, 0); 

	ipc_key = ftok(".", 'S'); 			// Generate a key from a pathname
	
	/* Create semaphore */
	/* A semaphore is always created reguardless of semaphore procetion. It is only used if k = s */ 
	if ((semid = semget(ipc_key, 1, IPC_CREAT | IPC_EXCL | 0666)) == -1) 
	{
        perror ("semget: IPC | 0666");
        exit(1);
	}

	/* Attempt to increment the semaphore */
	if(semop(semid, semsignal, 1) == -1) 
	{
	    printf("%ld: semaphore increment failed - %s\n", (long)getpid(), strerror(errno)); 
	    /* Remove the semaphore if unable to increment */
	        if (semctl(semid, 0, IPC_RMID) == -1) 
	            printf ("%ld: could not delete semaphore - %s\n", (long)getpid(), strerror(errno)); 
	            exit(1); 
	}
	
	/* Create the processes based on the value of 'N' */
	childpid = 0;
	for(i = 1; i < N; i++)
	{
		if(childpid = fork()) break; 
	}

	/* If semaphore protection is used, decrement the semaphore and enter it */
	if(opt)
	{
		while (( (semop_ret = semop(semid, semwait, 1) ) == -1) && (errno ==EINTR)); 
		    if (semop_ret == -1) 
		        printf ("%ld: semaphore decrement failed - %s\n", (long)getpid(), strerror(errno)); 
	}

	/* Create the output message and put in into a character buffer */
	sprintf(buf_num,"i: %d: process ID: %6ld parent ID: %6ld child ID: %6ld\n",i,(long)getpid(), (long)getppid(), (long)childpid);

	/* Direct the pointer to the char buffer */ 
	c_ptr = buf_num;

	/* Specifies the buffer to be used by the stream for I/O operations, which becomes a    */
	/* fully buffered stream. Or, alternatively, if buffer is a null pointer, buffering is  */
	/* disabled for the stream, which becomes an unbuffered stream. 						*/
	setbuf(stdout, NULL);

	/* Cycle through the char buffer using the pointer until it points to NULL */
	while (*c_ptr != '\0')
	{
		fputc(*c_ptr, stderr);
		/* Sleep in usec microsecond using the delay adjustment parameter */
		usleep(k);
		c_ptr++;
	}

	/* If semaphor protection is enabled, increment the semaphore */ 
	if(opt)
	{
		while ( ( (semop_ret = semop(semid, semsignal, 1) ) == -1) && (errno == EINTR) ); 
			if (semop_ret == -1) 
			    printf ("%ld: semaphore increment failed - %s\n", (long)getpid(), strerror(errno));
	}

	/* Wait for the child process to complete before the parent is killed */
	waitpid(childpid, &status, 0);

	/* Once the process has completed, remove the semaphore */
	if(leader == getpid())
	{
        if(semctl(semid, 0, IPC_RMID) == -1)
        {
            printf("%ld: couldn't delete semaphore - %s\n", (long)getpid(), strerror(errno));
            exit(1);
        }
    }
  exit(0);
} 

EXAMPLE #20
File: appmon_daemon.c Project: WeiY/mihini-repo
void SIGCHLD_handler(int s)
{
  int old_errno = errno;
  int child_status = 0, child_pid = 0;

  pid_t appmon_pid = getpid();
  SWI_LOG("APPMON", DEBUG, "SIGCHLD_handler: appmon_pid=%d =============>\n", appmon_pid);

  while (1)
  {
    do
    {
      errno = 0;
      //call waitpid trying to avoid suspend-related state changes.(no WUNTRACED or WCONTINUED options to waitpid)
      child_pid = waitpid(WAIT_ANY, &child_status, WNOHANG);
    } while (child_pid <= 0 && errno == EINTR);

    if (child_pid <= 0)
    {
      /* A real failure means there are no more
       stopped or terminated child processes, so return.  */
      errno = old_errno;
      SWI_LOG("APPMON", DEBUG, "SIGCHLD_handler: pid=%d =============< quit\n", appmon_pid);
      fflush(stdout);
      return;
    }

    app_t* app = find_by_pid(child_pid);
    if (NULL != app)
    {
      int exited = WIFEXITED(child_status);
      int exited_code = exited ? WEXITSTATUS(child_status) : -1;
      int signaled = WIFSIGNALED(child_status);

      //update exit status only if process is terminated.
      //if stopped/continued event on process is caught, don't update status
      if (!exited && !signaled)
      {
        SWI_LOG("APPMON", ERROR, "SIGCHLD_handler: status change looks like suspend events (STOP/CONT), ignored\n");
        continue; //go to next waipid call
      }

      //real child termination, update values
      app->last_exit_code = child_status;
      app_exit_status(app);

      SWI_LOG("APPMON", DEBUG, "SIGCHLD_handler: app terminated: id=%d, prog=%s was pid %d, calculated status =%s\n",
          app->id, app->prog, child_pid, app->last_exit_status);
      if (TO_BE_KILLED == app->status || (STARTED == app->status && exited && !exited_code))
      {
        //put flag to be used it stop_app
        app->status = KILLED;
        SWI_LOG("APPMON", DEBUG, "SIGCHLD_handler: status => KILLED\n");
      }
      else
      {
        if ((exited && exited_code > 0) | signaled)
        {
          SWI_LOG("APPMON", DEBUG, "SIGCHLD_handler: Child status error %d, application is set to  TO_BE_RESTARTED, %s\n",
              child_status, app->prog);
          //error has occur, restart app after delay
          // app will not be found if it has been stopped voluntarily, so it won't be restarted.
          app->status = TO_BE_RESTARTED;
          alarm(RESTART_DELAY);
        }
      }
    }
    else //app == NULL, pid not found in monitored apps
    {
      SWI_LOG("APPMON", DEBUG, "SIGCHLD_handler: unknown dead app, pid=%d\n", child_pid);
    }
  }
}
EXAMPLE #30
File: hydra-pcnfs.c Project: dummy3k/c-hydra
void service_pcnfs(char *ip, int sp, unsigned char options, char *miscptr, FILE * fp, int port) {
  int run = 1, next_run = 1, sock = -1;

  hydra_register_socket(sp);
  if (port == 0) {
    fprintf(stderr, "Error: pcnfs module called without -s port!\n");
    hydra_child_exit(0);
  }
  if ((options & OPTION_SSL) != 0) {
    fprintf(stderr, "Error: pcnfs module can not be used with SSL!\n");
    hydra_child_exit(0);
  }

  if (memcmp(hydra_get_next_pair(), &HYDRA_EXIT, sizeof(HYDRA_EXIT)) == 0)
    return;

  while (1) {
    next_run = 0;
    switch (run) {
    case 1:                    /* connect and service init function */
      {
        if (sock >= 0)
          sock = hydra_disconnect(sock);
//        usleep(275000);
        if ((sock = hydra_connect_udp(ip, port)) < 0) {
          fprintf(stderr, "Error: Child with pid %d terminating, can not connect\n", (int) getpid());
          hydra_child_exit(1);
        }
        next_run = 2;
        break;
      }
    case 2:                    /* run the cracking function */
      next_run = start_pcnfs(sock, ip, port, options, miscptr, fp);
      break;
    case 3:                    /* clean exit */
      if (sock >= 0)
        sock = hydra_disconnect(sock);
      hydra_child_exit(0);
      return;
    default:
      fprintf(stderr, "Caught unknown return code, exiting!\n");
      hydra_child_exit(0);
    }
    run = next_run;
  }
}
EXAMPLE #40
File: engine.c Project: opendnssec/opendnssec-svn
/**
 * Set up engine.
 *
 */
static ods_status
engine_setup(engine_type* engine)
{
    ods_status status = ODS_STATUS_OK;
    struct sigaction action;
    int result = 0;
    int sockets[2] = {0,0};

    ods_log_debug("[%s] setup signer engine", engine_str);
    if (!engine || !engine->config) {
        return ODS_STATUS_ASSERT_ERR;
    }
    /* set edns */
    edns_init(&engine->edns, EDNS_MAX_MESSAGE_LEN);

    /* create command handler (before chowning socket file) */
    engine->cmdhandler = cmdhandler_create(engine->allocator,
        engine->config->clisock_filename);
    if (!engine->cmdhandler) {
        return ODS_STATUS_CMDHANDLER_ERR;
    }
    engine->dnshandler = dnshandler_create(engine->allocator,
        engine->config->interfaces);
    engine->xfrhandler = xfrhandler_create(engine->allocator);
    if (!engine->xfrhandler) {
        return ODS_STATUS_XFRHANDLER_ERR;
    }
    if (engine->dnshandler) {
        if (socketpair(AF_UNIX, SOCK_DGRAM, 0, sockets) == -1) {
            return ODS_STATUS_XFRHANDLER_ERR;
        }
        engine->xfrhandler->dnshandler.fd = sockets[0];
        engine->dnshandler->xfrhandler.fd = sockets[1];
        status = dnshandler_listen(engine->dnshandler);
        if (status != ODS_STATUS_OK) {
            ods_log_error("[%s] setup: unable to listen to sockets (%s)",
                engine_str, ods_status2str(status));
        }
    }
    /* privdrop */
    engine->uid = privuid(engine->config->username);
    engine->gid = privgid(engine->config->group);
    /* TODO: does piddir exists? */
    /* remove the chown stuff: piddir? */
    ods_chown(engine->config->pid_filename, engine->uid, engine->gid, 1);
    ods_chown(engine->config->clisock_filename, engine->uid, engine->gid, 0);
    ods_chown(engine->config->working_dir, engine->uid, engine->gid, 0);
    if (engine->config->log_filename && !engine->config->use_syslog) {
        ods_chown(engine->config->log_filename, engine->uid, engine->gid, 0);
    }
    if (engine->config->working_dir &&
        chdir(engine->config->working_dir) != 0) {
        ods_log_error("[%s] setup: unable to chdir to %s (%s)", engine_str,
            engine->config->working_dir, strerror(errno));
        return ODS_STATUS_CHDIR_ERR;
    }
    if (engine_privdrop(engine) != ODS_STATUS_OK) {
        return ODS_STATUS_PRIVDROP_ERR;
    }
    /* set up hsm */ /* LEAK */
    result = lhsm_open(engine->config->repositories);
    if (result != HSM_OK) {
        fprintf(stderr, "Fail to open hsm\n");
        return ODS_STATUS_HSM_ERR;
    }
    /* daemonize */
    if (engine->daemonize) {
        switch ((engine->pid = fork())) {
            case -1: /* error */
                ods_log_error("[%s] setup: unable to fork daemon (%s)",
                    engine_str, strerror(errno));
                return ODS_STATUS_FORK_ERR;
            case 0: /* child */
                break;
            default: /* parent */
                engine_cleanup(engine);
                engine = NULL;
                xmlCleanupParser();
                xmlCleanupGlobals();
                xmlCleanupThreads();
                exit(0);
        }
        if (setsid() == -1) {
            hsm_close();
            ods_log_error("[%s] setup: unable to setsid daemon (%s)",
                engine_str, strerror(errno));
            return ODS_STATUS_SETSID_ERR;
        }
    }
    engine->pid = getpid();
    /* write pidfile */
    if (util_write_pidfile(engine->config->pid_filename, engine->pid) == -1) {
        hsm_close();
        return ODS_STATUS_WRITE_PIDFILE_ERR;
    }
    /* setup done */
    ods_log_verbose("[%s] running as pid %lu", engine_str,
        (unsigned long) engine->pid);
    /* catch signals */
    signal_set_engine(engine);
    action.sa_handler = signal_handler;
    sigfillset(&action.sa_mask);
    action.sa_flags = 0;
    sigaction(SIGTERM, &action, NULL);
    sigaction(SIGHUP, &action, NULL);
    sigaction(SIGINT, &action, NULL);
    sigaction(SIGILL, &action, NULL);
    sigaction(SIGUSR1, &action, NULL);
    sigaction(SIGALRM, &action, NULL);
    sigaction(SIGCHLD, &action, NULL);
    action.sa_handler = SIG_IGN;
    sigaction(SIGPIPE, &action, NULL);
    /* create workers/drudgers */
    engine_create_workers(engine);
    engine_create_drudgers(engine);
    /* start cmd/dns/xfr handlers */
    engine_start_cmdhandler(engine);
    engine_start_dnshandler(engine);
    engine_start_xfrhandler(engine);
    tsig_handler_init(engine->allocator);
    return ODS_STATUS_OK;
}
EXAMPLE #50
File: radvd.c Project: antonywcl/AR-5315u_PLD
int
main(int argc, char *argv[])
{
	char pidstr[16];
	ssize_t ret;
	int c, log_method;
	char *logfile, *pidfile;
	int facility, fd;
	char *username = NULL;
	char *chrootdir = NULL;
	int configtest = 0;
	int singleprocess = 0;
#ifdef HAVE_GETOPT_LONG
	int opt_idx;
#endif

	pname = ((pname=strrchr(argv[0],'/')) != NULL)?pname+1:argv[0];

	srand((unsigned int)time(NULL));

	log_method = L_STDERR_SYSLOG;
	logfile = PATH_RADVD_LOG;
	conf_file = PATH_RADVD_CONF;
	facility = LOG_DAEMON;    //brcm
	pidfile = PATH_RADVD_PID;

	/* parse args */
#define OPTIONS_STR "d:C:l:m:p:t:u:vhcs"
#ifdef HAVE_GETOPT_LONG
	while ((c = getopt_long(argc, argv, OPTIONS_STR, prog_opt, &opt_idx)) > 0)
#else
	while ((c = getopt(argc, argv, OPTIONS_STR)) > 0)
#endif
	{
		switch (c) {
		case 'C':
			conf_file = optarg;
			break;
		case 'd':
			set_debuglevel(atoi(optarg));
			break;
		case 'f':
			facility = atoi(optarg);
			break;
		case 'l':
			logfile = optarg;
			break;
		case 'p':
			pidfile = optarg;
			break;
		case 'm':
			if (!strcmp(optarg, "syslog"))
			{
				log_method = L_SYSLOG;
			}
			else if (!strcmp(optarg, "stderr_syslog"))
			{
				log_method = L_STDERR_SYSLOG;
			}
			else if (!strcmp(optarg, "stderr"))
			{
				log_method = L_STDERR;
			}
			else if (!strcmp(optarg, "logfile"))
			{
				log_method = L_LOGFILE;
			}
			else if (!strcmp(optarg, "none"))
			{
				log_method = L_NONE;
			}
			else
			{
				fprintf(stderr, "%s: unknown log method: %s\n", pname, optarg);
				exit(1);
			}
			break;
		case 't':
			chrootdir = strdup(optarg);
			break;
		case 'u':
			username = strdup(optarg);
			break;
		case 'v':
			version();
			break;
		case 'c':
			configtest = 1;
			break;
		case 's':
			singleprocess = 1;
			break;
		case 'h':
			usage();
#ifdef HAVE_GETOPT_LONG
		case ':':
			fprintf(stderr, "%s: option %s: parameter expected\n", pname,
				prog_opt[opt_idx].name);
			exit(1);
#endif
		case '?':
			exit(1);
		}
	}

	if (chrootdir) {
		if (!username) {
			fprintf(stderr, "Chroot as root is not safe, exiting\n");
			exit(1);
		}

		if (chroot(chrootdir) == -1) {
			perror("chroot");
			exit (1);
		}

		if (chdir("/") == -1) {
			perror("chdir");
			exit (1);
		}
		/* username will be switched later */
	}

	if (configtest) {
		log_method = L_STDERR;
	}

	if (log_open(log_method, pname, logfile, facility) < 0) {
		perror("log_open");
		exit(1);
	}

	if (!configtest) {
		flog(LOG_INFO, "version %s started", "1.8");
	}

	/* get a raw socket for sending and receiving ICMPv6 messages */
	sock = open_icmpv6_socket();
	if (sock < 0) {
		perror("open_icmpv6_socket");
		exit(1);
	}

#ifndef BRCM_CMS_BUILD //brcm
	/* check that 'other' cannot write the file
         * for non-root, also that self/own group can't either
         */
	if (check_conffile_perm(username, conf_file) < 0) {
		if (get_debuglevel() == 0) {
			flog(LOG_ERR, "Exiting, permissions on conf_file invalid.\n");
			exit(1);
		}
		else
			flog(LOG_WARNING, "Insecure file permissions, but continuing anyway");
	}

	/* if we know how to do it, check whether forwarding is enabled */
	if (check_ip6_forwarding()) {
		flog(LOG_WARNING, "IPv6 forwarding seems to be disabled, but continuing anyway.");
	}
#endif

	/* parse config file */
	if (readin_config(conf_file) < 0) {
		flog(LOG_ERR, "Exiting, failed to read config file.\n");
		exit(1);
	}

	if (configtest) {
		fprintf(stderr, "Syntax OK\n");
		exit(0);
	}

	/* drop root privileges if requested. */
	if (username) {
		if (!singleprocess) {
		 	dlog(LOG_DEBUG, 3, "Initializing privsep");
		 	if (privsep_init() < 0)
				flog(LOG_WARNING, "Failed to initialize privsep.");
		}

		if (drop_root_privileges(username) < 0) {
			perror("drop_root_privileges");
			exit(1);
		}
	}

	if ((fd = open(pidfile, O_RDONLY, 0)) > 0)
	{
		ret = read(fd, pidstr, sizeof(pidstr) - 1);
		if (ret < 0)
		{
			flog(LOG_ERR, "cannot read radvd pid file, terminating: %s", strerror(errno));
			exit(1);
		}
		pidstr[ret] = '\0';
		if (!kill((pid_t)atol(pidstr), 0))
		{
			flog(LOG_ERR, "radvd already running, terminating.");
			exit(1);
		}
		close(fd);
		fd = open(pidfile, O_CREAT|O_TRUNC|O_WRONLY, 0644);
	}
	else	/* FIXME: not atomic if pidfile is on an NFS mounted volume */
		fd = open(pidfile, O_CREAT|O_EXCL|O_WRONLY, 0644);

	if (fd < 0)
	{
		flog(LOG_ERR, "cannot create radvd pid file, terminating: %s", strerror(errno));
		exit(1);
	}

	/*
	 * okay, config file is read in, socket and stuff is setup, so
	 * lets fork now...
	 */

#ifndef BRCM_CMS_BUILD //brcm
	if (get_debuglevel() == 0) {

		/* Detach from controlling terminal */
		if (daemon(0, 0) < 0)
			perror("daemon");

		/* close old logfiles, including stderr */
		log_close();

		/* reopen logfiles, but don't log to stderr unless explicitly requested */
		if (log_method == L_STDERR_SYSLOG)
			log_method = L_SYSLOG;
		if (log_open(log_method, pname, logfile, facility) < 0) {
			perror("log_open");
			exit(1);
		}

	}
#endif

	/*
	 *	config signal handlers
	 */
#ifdef BRCM_CMS_BUILD //brcm
	signal(SIGHUP, SIG_IGN);
	signal(SIGTERM, sigterm_handler);
	signal(SIGPIPE, SIG_IGN);
	signal(SIGINT, SIG_IGN);
	signal(SIGUSR1, SIG_IGN);
#else
	signal(SIGHUP, sighup_handler);
	signal(SIGTERM, sigterm_handler);
	signal(SIGINT, sigint_handler);
	signal(SIGUSR1, sigusr1_handler);
#endif

	snprintf(pidstr, sizeof(pidstr), "%ld\n", (long)getpid());

	ret = write(fd, pidstr, strlen(pidstr));
	if (ret != strlen(pidstr))
	{
		flog(LOG_ERR, "cannot write radvd pid file, terminating: %s", strerror(errno));
		exit(1);
	}

	close(fd);

	config_interface();
	kickoff_adverts();
	main_loop();
	stop_adverts();
	unlink(pidfile);

	return 0;
}
EXAMPLE #60
File: proc.c Project: paulfariello/relayd
pid_t
proc_run(struct privsep *ps, struct privsep_proc *p,
    struct privsep_proc *procs, u_int nproc,
    void (*init)(struct privsep *, struct privsep_proc *, void *), void *arg)
{
	pid_t			 pid;
	struct passwd		*pw;
	const char		*root;
	struct control_sock	*rcs;
	u_int			 n;

	if (ps->ps_noaction)
		return (0);

	proc_open(ps, p, procs, nproc);

	/* Fork child handlers */
	switch (pid = fork()) {
	case -1:
		fatal("proc_run: cannot fork");
	case 0:
		/* Set the process group of the current process */
		setpgid(0, 0);
		break;
	default:
		return (pid);
	}

	pw = ps->ps_pw;

	if (p->p_id == PROC_CONTROL && ps->ps_instance == 0) {
		if (control_init(ps, &ps->ps_csock) == -1)
			fatalx(p->p_title);
		TAILQ_FOREACH(rcs, &ps->ps_rcsocks, cs_entry)
			if (control_init(ps, rcs) == -1)
				fatalx(p->p_title);
	}

	/* Change root directory */
	if (p->p_chroot != NULL)
		root = p->p_chroot;
	else
		root = pw->pw_dir;

	if (chroot(root) == -1)
		fatal("proc_run: chroot");
	if (chdir("/") == -1)
		fatal("proc_run: chdir(\"/\")");

	privsep_process = p->p_id;

	setproctitle("%s", p->p_title);

	if (setgroups(1, &pw->pw_gid) ||
	    setresgid(pw->pw_gid, pw->pw_gid, pw->pw_gid) ||
	    setresuid(pw->pw_uid, pw->pw_uid, pw->pw_uid))
		fatal("proc_run: cannot drop privileges");

	/* Fork child handlers */
	for (n = 1; n < ps->ps_instances[p->p_id]; n++) {
		if (fork() == 0) {
			ps->ps_instance = p->p_instance = n;
			break;
		}
	}

#ifdef DEBUG
	log_debug("%s: %s %d/%d, pid %d", __func__, p->p_title,
	    ps->ps_instance + 1, ps->ps_instances[p->p_id], getpid());
#endif

	event_init();

	signal_set(&ps->ps_evsigint, SIGINT, proc_sig_handler, p);
	signal_set(&ps->ps_evsigterm, SIGTERM, proc_sig_handler, p);
	signal_set(&ps->ps_evsigchld, SIGCHLD, proc_sig_handler, p);
	signal_set(&ps->ps_evsighup, SIGHUP, proc_sig_handler, p);
	signal_set(&ps->ps_evsigpipe, SIGPIPE, proc_sig_handler, p);
	signal_set(&ps->ps_evsigusr1, SIGUSR1, proc_sig_handler, p);

	signal_add(&ps->ps_evsigint, NULL);
	signal_add(&ps->ps_evsigterm, NULL);
	signal_add(&ps->ps_evsigchld, NULL);
	signal_add(&ps->ps_evsighup, NULL);
	signal_add(&ps->ps_evsigpipe, NULL);
	signal_add(&ps->ps_evsigusr1, NULL);

	proc_listen(ps, procs, nproc);

	if (p->p_id == PROC_CONTROL && ps->ps_instance == 0) {
		TAILQ_INIT(&ctl_conns);
		if (control_listen(&ps->ps_csock) == -1)
			fatalx(p->p_title);
		TAILQ_FOREACH(rcs, &ps->ps_rcsocks, cs_entry)
			if (control_listen(rcs) == -1)
				fatalx(p->p_title);
	}
EXAMPLE #70
File: demo_clone.c Project: Heuristack/Productivity
int
main(int argc, char *argv[])
{
    const int STACK_SIZE = 65536;       /* Stack size for cloned child */
    char *stack;                        /* Start of stack buffer area */
    char *stackTop;                     /* End of stack buffer area */
    int flags;                          /* Flags for cloning child */
    ChildParams cp;                     /* Passed to child function */
    const mode_t START_UMASK = S_IWOTH; /* Initial umask setting */
    struct sigaction sa;
    char *p;
    int status;
    ssize_t s;
    pid_t pid;

    printf("Parent: PID=%ld PPID=%ld\n", (long) getpid(), (long) getppid());

    /* Set up an argument structure to be passed to cloned child, and
       set some process attributes that will be modified by child */

    cp.exitStatus = 22;                 /* Child will exit with this status */

    umask(START_UMASK);                 /* Initialize umask to some value */
    cp.umask = S_IWGRP;                 /* Child sets umask to this value */

    cp.fd = open("/dev/null", O_RDWR);  /* Child will close this fd */
    if (cp.fd == -1)
        errExit("open");

    cp.signal = SIGTERM;                /* Child will change disposition */
    if (signal(cp.signal, SIG_IGN) == SIG_ERR)
        errExit("signal");

    /* Initialize clone flags using command-line argument (if supplied) */

    flags = 0;
    if (argc > 1) {
        for (p = argv[1]; *p != '\0'; p++) {
            if      (*p == 'd') flags |= CLONE_FILES;
            else if (*p == 'f') flags |= CLONE_FS;
            else if (*p == 's') flags |= CLONE_SIGHAND;
            else if (*p == 'v') flags |= CLONE_VM;
            else usageError(argv[0]);
        }
    }

    /* Allocate stack for child */

    stack = malloc(STACK_SIZE);
    if (stack == NULL)
        errExit("malloc");
    stackTop = stack + STACK_SIZE;  /* Assume stack grows downward */

    /* Establish handler to catch child termination signal */

    if (CHILD_SIG != 0) {
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART;
        sa.sa_handler = grimReaper;
        if (sigaction(CHILD_SIG, &sa, NULL) == -1)
            errExit("sigaction");
    }

    /* Create child; child commences execution in childFunc() */

    if (clone(childFunc, stackTop, flags | CHILD_SIG, &cp) == -1)
        errExit("clone");

    /* Parent falls through to here. Wait for child; __WCLONE option is
       required for child notifying with signal other than SIGCHLD. */

    pid = waitpid(-1, &status, (CHILD_SIG != SIGCHLD) ? __WCLONE : 0);
    if (pid == -1)
        errExit("waitpid");

    printf("    Child PID=%ld\n", (long) pid);
    printWaitStatus("    Status: ", status);

    /* Check whether changes made by cloned child have affected parent */

    printf("Parent - checking process attributes:\n");
    if (umask(0) != START_UMASK)
        printf("    umask has changed\n");
    else
        printf("    umask has not changed\n");

    s = write(cp.fd, "Hello world\n", 12);
    if (s == -1 && errno == EBADF)
        printf("    file descriptor %d has been closed\n", cp.fd);
    else if (s == -1)
        printf("    write() on file descriptor %d failed (%s)\n",
                cp.fd, strerror(errno));
    else
        printf("    write() on file descriptor %d succeeded\n", cp.fd);

    if (sigaction(cp.signal, NULL, &sa) == -1)
        errExit("sigaction");
    if (sa.sa_handler != SIG_IGN)
        printf("    signal disposition has changed\n");
    else
        printf("    signal disposition has not changed\n");

    exit(EXIT_SUCCESS);
}
EXAMPLE #80
File: app.cpp Project: dndusdndus12/ISA100.11a-Gateway-1
void HandlerFATAL(int p_signal)
{
	static char str[4098];	/// 11 bytes per address. Watch for overflow
	int i;
	int n=0, bContinue=1 ;	// used by BKTRACE macro
	*str=0;/// reset every time

// ARM/CYG has an older uClibc with no program_invocation_short_name support
// so use __progname
#if defined(ARM) || defined(CYG)
	extern const char *__progname;
#endif

	for ( i=0; bContinue && (i<16) ; ++i)
	{	switch (i)	/// parameter for __builtin_frame_address must be a constant integer
		{	case 0:	BKTRACE(0,n,bContinue);	break ;
// ARM doesn't support more than 1 stack unwind.
#if !defined(ARM) && !defined(CYG)
			case 1:	BKTRACE(1,n,bContinue);	break ;
			case 2:	BKTRACE(2,n,bContinue);	break ;
			case 3:	BKTRACE(3,n,bContinue);	break ;
			case 4:	BKTRACE(4,n,bContinue);	break ;
			case 5:	BKTRACE(5,n,bContinue);	break ;
			case 6:	BKTRACE(6,n,bContinue);	break ;
			case 7:	BKTRACE(7,n,bContinue);	break ;
			case 8:	BKTRACE(8,n,bContinue);	break ;
			case 9:	BKTRACE(9,n,bContinue);	break ;
			case 10:BKTRACE(10,n,bContinue);	break ;
			case 11:BKTRACE(11,n,bContinue);	break ;
			case 12:BKTRACE(12,n,bContinue);	break ;
			case 13:BKTRACE(13,n,bContinue);	break ;
			case 14:BKTRACE(14,n,bContinue);	break ;
			case 15:BKTRACE(15,n,bContinue);	break ;
#elif defined(ARM)
			case 1:
			n+=snprintf( str+n, sizeof(str)-n-1,
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				"x x x x x x x x "
				);
			break;
#endif
		}
	}

	log2flash("PANIC [%s] Pid[%lu] %s %u. Backtrace [%s]",
// ARM/CYG has an older uClibc with no program_invocation_short_name support
// so use __progname
#if !defined(ARM) && !defined(CYG)
		program_invocation_short_name,
#else
		__progname,
#endif
		getpid(),
		(p_signal == SIGSEGV) ? "SIGSEGV" :
		(p_signal == SIGABRT) ? "SIGABRT" :
		(p_signal == SIGFPE)  ? "SIGFPE" :"UNK", p_signal, str);
	/// make sure to flush the log to disk. Standard LOG does it at this time. Put an extra \n to be absolutely sure
	LOG("PANIC [%s] Pid[%lu] %s %u. Backtrace [%s]\n",
#if !defined(ARM) && !defined(CYG)
		program_invocation_short_name,
#else
		__progname,
#endif
		getpid(),
		(p_signal == SIGSEGV) ? "SIGSEGV" :
		(p_signal == SIGABRT) ? "SIGABRT" :
		(p_signal == SIGFPE)  ? "SIGFPE"  : "UNK", p_signal, str);
	exit(EXIT_FAILURE);
}
EXAMPLE #90
File: app.cpp Project: dndusdndus12/ISA100.11a-Gateway-1
/** make any necessary initialisation  */
int CApp::Init( const char *p_lpszLogFile, int p_nMaxLogSize /*= 524288*/ )
{
//Modified by Claudiu Hobeanu on 2004/10/25 14:34
//  Changes : move signals handle in CSignalsMgr

	CSignalsMgr::Ignore(SIGHUP);
	CSignalsMgr::Ignore(SIGTTOU);
	CSignalsMgr::Ignore(SIGTTIN);
	CSignalsMgr::Ignore(SIGTSTP);
	CSignalsMgr::Ignore(SIGPIPE);

	CSignalsMgr::Install( SIGTERM, HandlerSIGTERM );
	CSignalsMgr::Install( SIGINT, HandlerSIGTERM );

	///NEVER USE CSignalsMgr TO HANDLE SIGABRT/SIGSEGV
	signal( SIGABRT, HandlerFATAL );/// do NOT use delayed processing with HandlerFATAL. Stack trace must be dumped on event
	signal( SIGSEGV, HandlerFATAL );/// do NOT use delayed processing with HandlerFATAL. Stack trace must be dumped on event
	signal( SIGFPE,  HandlerFATAL );/// do NOT use delayed processing with HandlerFATAL. Stack trace must be dumped on event

	//close stdin, stdout and stderr then open them as /dev/null (fix problems with fd's after forking)
#if !defined( DONT_CLOSE_STD )
	close(0);
	close(1);
	close(2);
	open("/dev/null", O_RDWR);
	open("/dev/null", O_RDWR);
	open("/dev/null", O_RDWR);
#endif
	strcpy(m_szAppPidFile, p_lpszLogFile);
	int nLen = strlen(m_szAppPidFile);

	if (	m_szAppPidFile[nLen-1] == 'g' && m_szAppPidFile[nLen-2] == 'o'
		&&	m_szAppPidFile[nLen-3] == 'l' && m_szAppPidFile[nLen-4] == '.' )
	{	m_szAppPidFile[nLen-4] = 0;
	}

	char szLockFile[256];

	strcpy(szLockFile, m_szAppPidFile);
	strcat(szLockFile, ".flock");

	strcat(m_szAppPidFile, ".pid" );

    //open ilog file with default parameters... to have something...
    if( !g_stLog.Open(p_lpszLogFile, "Start session", p_nMaxLogSize))
        return 0;

    LOG( "CApp(%s)::Init - version: %s", m_szModule, version() );

    m_nSyncFd = open( szLockFile, O_RDWR | O_CREAT, 0666 );
    if( flock( m_nSyncFd, LOCK_EX | LOCK_NB ) )
    {
        LOG( "Process %d try to start but another instance of program is running ",getpid());
        return 0;
    }

	SetCloseOnExec(m_nSyncFd);

	LOG("System MEMORY Available: %dkB", GetSysFreeMemK() );

	if (!m_oModulesActivity.Open())
	{	return 0;
	}

    return 1;
}
EXAMPLE #100
File: gkd-main.c Project: bhull2010/mate-keyring
static void
fork_and_print_environment (void)
{
	int status;
	pid_t pid;
	int fd, i;

	if (run_foreground) {
		print_environment (getpid ());
		return;
	}

	pid = fork ();

	if (pid != 0) {

		/* Here we are in the initial process */

		if (run_daemonized) {

			/* Initial process, waits for intermediate child */
			if (pid == -1)
				exit (1);

			waitpid (pid, &status, 0);
			if (WEXITSTATUS (status) != 0)
				exit (WEXITSTATUS (status));

		} else {
			/* Not double forking, we know the PID */
			print_environment (pid);
		}

		/* The initial process exits successfully */
		exit (0);
	}

	if (run_daemonized) {

		/* Double fork if need to daemonize properly */
		pid = fork ();

		if (pid != 0) {

			/* Here we are in the intermediate child process */

			/*
			 * This process exits, so that the final child will inherit
			 * init as parent to avoid zombies
			 */
			if (pid == -1)
				exit (1);

			/* We've done two forks. Now we know the PID */
			print_environment (pid);

			/* The intermediate child exits */
			exit (0);
		}

	}

	/* Here we are in the resulting daemon or background process. */

	for (i = 0; i < 3; ++i) {
		fd = open ("/dev/null", O_RDONLY);
		sane_dup2 (fd, i);
		close (fd);
	}
}
EXAMPLE #110
File: javasysmon.c Project: AlanVerbner/javasysmon
JNIEXPORT jint JNICALL Java_com_jezhumble_javasysmon_SolarisMonitor_currentPid (JNIEnv *env, jobject obj)
{
  return (jint) getpid();
}
EXAMPLE #120
File: banipd.c Project: julp/banip
int main(int argc, char **argv)
{
    gid_t gid;
    addr_t addr;
    struct sigaction sa;
    int c, dFlag, vFlag;
    unsigned long max_message_size;
    const char *queuename, *tablename;

    ctxt = NULL;
    gid = (gid_t) -1;
    vFlag = dFlag = 0;
    tablename = queuename = NULL;
    if (NULL == (queue = queue_init())) {
        errx("queue_init failed"); // TODO: better
    }
    atexit(cleanup);
    sa.sa_handler = &on_signal;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sa.sa_flags = SA_RESTART;
    sigaction(SIGUSR1, &sa, NULL);
    if (NULL == (engine = get_default_engine())) {
        errx("no engine available for your system");
    }
    while (-1 != (c = getopt_long(argc, argv, optstr, long_options, NULL))) {
        switch (c) {
            case 'b':
            {
                unsigned long val;

                if (parse_ulong(optarg, &val)) {
                    queue_set_attribute(queue, QUEUE_ATTR_MAX_MESSAGE_SIZE, val); // TODO: check returned value
                }
                break;
            }
            case 'd':
                dFlag = 1;
                break;
            case 'e':
            {
                if (NULL == (engine = get_engine_by_name(optarg))) {
                    errx("unknown engine '%s'", optarg);
                }
                break;
            }
            case 'g':
            {
                struct group *grp;

                if (NULL == (grp = getgrnam(optarg))) {
                    errc("getgrnam failed");
                }
                gid = grp->gr_gid;
                break;
            }
            case 'l':
            {
                logfilename = optarg;
                if (NULL == (err_file = fopen(logfilename, "a"))) {
                    err_file = NULL;
                    warnc("fopen '%s' failed, falling back to stderr", logfilename);
                }
                break;
            }
            case 'p':
                pidfilename = optarg;
                break;
            case 'q':
                queuename = optarg;
                break;
            case 's':
            {
                unsigned long val;

                if (parse_ulong(optarg, &val)) {
                    queue_set_attribute(queue, QUEUE_ATTR_MAX_MESSAGE_IN_QUEUE, val); // TODO: check returned value
                }
                break;
            }
            case 't':
                tablename = optarg;
                break;
            case 'v':
                vFlag++;
                break;
            case 'h':
            default:
                usage();
        }
    }
    argc -= optind;
    argv += optind;

    if (0 != argc || NULL == queuename || NULL == tablename) {
        usage();
    }

    if (dFlag) {
        if (0 != daemon(0, !vFlag)) {
            errc("daemon failed");
        }
    }
    if (NULL != pidfilename) {
        FILE *fp;

        if (NULL == (fp = fopen(pidfilename, "w"))) {
            warnc("can't create pid file '%s'", pidfilename);
        } else {
            fprintf(fp, "%ld\n", (long) getpid());
            fclose(fp);
        }
    }

    if (((gid_t) -1) != gid) {
        if (0 != setgid(gid)) {
            errc("setgid failed");
        }
        if (0 != setgroups(1, &gid)) {
            errc("setgroups failed");
        }
    }
    CAP_RIGHTS_LIMIT(STDOUT_FILENO, CAP_WRITE);
    CAP_RIGHTS_LIMIT(STDERR_FILENO, CAP_WRITE);
    if (NULL != err_file/* && fileno(err_file) > 2*/) {
        CAP_RIGHTS_LIMIT(fileno(err_file), CAP_WRITE);
    }
    if (QUEUE_ERR_OK != queue_open(queue, queuename, QUEUE_FL_OWNER)) {
        errx("queue_open failed"); // TODO: better
    }
    if (QUEUE_ERR_OK != queue_get_attribute(queue, QUEUE_ATTR_MAX_MESSAGE_SIZE, &max_message_size)) {
        errx("queue_get_attribute failed"); // TODO: better
    }
    if (NULL == (buffer = calloc(++max_message_size, sizeof(*buffer)))) {
        errx("calloc failed");
    }
    if (NULL != engine->open) {
        ctxt = engine->open(tablename);
    }
    if (0 == getuid() && engine->drop_privileges) {
        struct passwd *pwd;

        if (NULL == (pwd = getpwnam("nobody"))) {
            if (NULL == (pwd = getpwnam("daemon"))) {
                errx("no nobody or daemon user accounts found on this system");
            }
        }
        if (0 != setuid(pwd->pw_uid)) {
            errc("setuid failed");
        }
    }
    CAP_ENTER();
    while (1) {
        ssize_t read;

        if (-1 == (read = queue_receive(queue, buffer, max_message_size))) {
            errc("queue_receive failed"); // TODO: better
        } else {
            if (!parse_addr(buffer, &addr)) {
                errx("parsing of '%s' failed", buffer); // TODO: better
            } else {
                engine->handle(ctxt, tablename, addr);
            }
        }
    }
    /* not reached */

    return BANIPD_EXIT_SUCCESS;
}
EXAMPLE #130
File: mock_comp.cpp Project: diegonc/Sistemas-Distribuidos-TP-Museo
int main (int argc, char** argv)
{
	std::cout << "Iniciando componente..." << std::endl;

	Cola<IPuertaMsg> mqComp (calcularRutaMQ (argv[0]), 'A');
	long mtype = getpid ();
	IPuertaMsg msg = {};
	IPuertaMsg res = {};
	int err;

	std::cout << "Aceptando mensajes..." << std::endl;

	while (true) {
		err = mqComp.leer (mtype, &msg);
		System::check (err);

		switch (msg.op) {
		case OP_SOLIC_ENTRAR_MUSEO_PERSONA:
			// Este componente siempre deja entrar las personas
			std::cout << "Persona entrando por puerta "
				<< msg.msg.semp.idPuerta << std::endl;
			res.mtype = msg.msg.semp.rtype;
			res.op = NOTIF_ENTRADA_PERSONA;
			res.msg.nep.res = ENTRO;
			err = mqComp.escribir (res);
			System::check (err);
			break;
		case OP_SOLIC_ENTRAR_MUSEO_INVESTIGADOR:
			// Este componente guarda las pertenencias en el numero
			// de locker.
			std::cout << "Investigador entrando por puerta "
					<< msg.msg.semi.idPuerta
					<< " con pertenencias "
					<< msg.msg.semi.pertenencias << std::endl;
			res.mtype = msg.msg.semi.rtype;
			res.op = NOTIF_ENTRADA_INVESTIGADOR;
			res.msg.nei.res = ENTRO;
			res.msg.nei.numeroLocker = msg.msg.semi.pertenencias;
			err = mqComp.escribir (res);
			System::check (err);
			break;
		case OP_SOLIC_SALIR_MUSEO_PERSONA:
			// Responde que salió
			std::cout << "Persona saliendo por puerta "
					<< msg.msg.ssmp.idPuerta << std::endl;
			res.mtype = msg.msg.ssmp.rtype;
			res.op = NOTIF_SALIDA_PERSONA;
			res.msg.nsp.res = SALIO;
			err = mqComp.escribir (res);
			System::check (err);
			break;
		case OP_SOLIC_SALIR_MUSEO_INVESTIGADOR:
			// Devuelve las pertenencias que guardo en el
			// numero de locker.
			// No checkea puerta correcta
			std::cout << "Investigador saliendo por puerta "
					<< msg.msg.ssmi.idPuerta
					<< " con numero de locker "
					<< msg.msg.ssmi.numeroLocker << std::endl;
			res.mtype = msg.msg.ssmi.rtype;
			res.op = NOTIF_SALIDA_INVESTIGADOR;
			res.msg.nsi.res = SALIO;
			res.msg.nsi.pertenencias = msg.msg.ssmi.numeroLocker;
			err = mqComp.escribir (res);
			System::check (err);
			break;
		default:
			std::cerr << "Componente recibio mensaje inválido: "
				<< msg.op << std::endl;
		}
	}

	/* not reached */
	return 0;
}
EXAMPLE #140
File: mysqlnd_auth.c Project: Distrotech/php-src
/* {{{ mysqlnd_sha256_get_rsa_key */
static RSA *
mysqlnd_sha256_get_rsa_key(MYSQLND_CONN_DATA * conn,
						   const MYSQLND_SESSION_OPTIONS * const session_options,
						   const MYSQLND_PFC_DATA * const pfc_data
						  )
{
	RSA * ret = NULL;
	const char * fname = (pfc_data->sha256_server_public_key && pfc_data->sha256_server_public_key[0] != '\0')?
								pfc_data->sha256_server_public_key:
								MYSQLND_G(sha256_server_public_key);
	php_stream * stream;
	DBG_ENTER("mysqlnd_sha256_get_rsa_key");
	DBG_INF_FMT("options_s256_pk=[%s] MYSQLND_G(sha256_server_public_key)=[%s]",
				 pfc_data->sha256_server_public_key? pfc_data->sha256_server_public_key:"n/a",
				 MYSQLND_G(sha256_server_public_key)? MYSQLND_G(sha256_server_public_key):"n/a");
	if (!fname || fname[0] == '\0') {
		MYSQLND_PACKET_SHA256_PK_REQUEST * pk_req_packet = NULL;
		MYSQLND_PACKET_SHA256_PK_REQUEST_RESPONSE * pk_resp_packet = NULL;

		do {
			DBG_INF("requesting the public key from the server");
			pk_req_packet = conn->payload_decoder_factory->m.get_sha256_pk_request_packet(conn->payload_decoder_factory, FALSE);
			if (!pk_req_packet) {
				SET_OOM_ERROR(conn->error_info);
				break;
			}
			pk_resp_packet = conn->payload_decoder_factory->m.get_sha256_pk_request_response_packet(conn->payload_decoder_factory, FALSE);
			if (!pk_resp_packet) {
				SET_OOM_ERROR(conn->error_info);
				PACKET_FREE(pk_req_packet);
				break;
			}

			if (! PACKET_WRITE(pk_req_packet)) {
				DBG_ERR_FMT("Error while sending public key request packet");
				php_error(E_WARNING, "Error while sending public key request packet. PID=%d", getpid());
				SET_CONNECTION_STATE(&conn->state, CONN_QUIT_SENT);
				break;
			}
			if (FAIL == PACKET_READ(pk_resp_packet) || NULL == pk_resp_packet->public_key) {
				DBG_ERR_FMT("Error while receiving public key");
				php_error(E_WARNING, "Error while receiving public key. PID=%d", getpid());
				SET_CONNECTION_STATE(&conn->state, CONN_QUIT_SENT);
				break;
			}
			DBG_INF_FMT("Public key(%d):\n%s", pk_resp_packet->public_key_len, pk_resp_packet->public_key);
			/* now extract the public key */
			{
				BIO * bio = BIO_new_mem_buf(pk_resp_packet->public_key, pk_resp_packet->public_key_len);
				ret = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
				BIO_free(bio);
			}
		} while (0);
		PACKET_FREE(pk_req_packet);
		PACKET_FREE(pk_resp_packet);

		DBG_INF_FMT("ret=%p", ret);
		DBG_RETURN(ret);

		SET_CLIENT_ERROR(conn->error_info, CR_UNKNOWN_ERROR, UNKNOWN_SQLSTATE,
			"sha256_server_public_key is not set for the connection or as mysqlnd.sha256_server_public_key");
		DBG_ERR("server_public_key is not set");
		DBG_RETURN(NULL);
	} else {
		zend_string * key_str;
		DBG_INF_FMT("Key in a file. [%s]", fname);
		stream = php_stream_open_wrapper((char *) fname, "rb", REPORT_ERRORS, NULL);

		if (stream) {
			if ((key_str = php_stream_copy_to_mem(stream, PHP_STREAM_COPY_ALL, 0)) != NULL) {
				BIO * bio = BIO_new_mem_buf(ZSTR_VAL(key_str), ZSTR_LEN(key_str));
				ret = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
				BIO_free(bio);
				DBG_INF("Successfully loaded");
				DBG_INF_FMT("Public key:%*.s", ZSTR_LEN(key_str), ZSTR_VAL(key_str));
				zend_string_release(key_str);
			}
			php_stream_close(stream);
		}
	}
	DBG_RETURN(ret);
}
EXAMPLE #150
File: minitrace.c Project: ccache/ccache
static inline int get_cur_process_id() {
	return (int)getpid();
}
EXAMPLE #160
File: eval.c Project: 28vicky/android_system_core
void
evaltree(union node *n, int flags)
{
	if (n == NULL) {
		TRACE(("evaltree(NULL) called\n"));
		exitstatus = 0;
		goto out;
	}
#ifdef WITH_HISTORY
	displayhist = 1;	/* show history substitutions done with fc */
#endif
	TRACE(("pid %d, evaltree(%p: %d, %d) called\n",
	    getpid(), n, n->type, flags));
	switch (n->type) {
	case NSEMI:
		evaltree(n->nbinary.ch1, flags & EV_TESTED);
		if (evalskip)
			goto out;
		evaltree(n->nbinary.ch2, flags);
		break;
	case NAND:
		evaltree(n->nbinary.ch1, EV_TESTED);
		if (evalskip || exitstatus != 0)
			goto out;
		evaltree(n->nbinary.ch2, flags);
		break;
	case NOR:
		evaltree(n->nbinary.ch1, EV_TESTED);
		if (evalskip || exitstatus == 0)
			goto out;
		evaltree(n->nbinary.ch2, flags);
		break;
	case NREDIR:
		expredir(n->nredir.redirect);
		redirect(n->nredir.redirect, REDIR_PUSH);
		evaltree(n->nredir.n, flags);
		popredir();
		break;
	case NSUBSHELL:
		evalsubshell(n, flags);
		break;
	case NBACKGND:
		evalsubshell(n, flags);
		break;
	case NIF: {
		evaltree(n->nif.test, EV_TESTED);
		if (evalskip)
			goto out;
		if (exitstatus == 0)
			evaltree(n->nif.ifpart, flags);
		else if (n->nif.elsepart)
			evaltree(n->nif.elsepart, flags);
		else
			exitstatus = 0;
		break;
	}
	case NWHILE:
	case NUNTIL:
		evalloop(n, flags);
		break;
	case NFOR:
		evalfor(n, flags);
		break;
	case NCASE:
		evalcase(n, flags);
		break;
	case NDEFUN:
		defun(n->narg.text, n->narg.next);
		exitstatus = 0;
		break;
	case NNOT:
		evaltree(n->nnot.com, EV_TESTED);
		exitstatus = !exitstatus;
		break;
	case NPIPE:
		evalpipe(n);
		break;
	case NCMD:
		evalcommand(n, flags, (struct backcmd *)NULL);
		break;
	default:
		out1fmt("Node type = %d\n", n->type);
		flushout(&output);
		break;
	}
out:
	if (pendingsigs)
		dotrap();
	if ((flags & EV_EXIT) != 0)
		exitshell(exitstatus);
}
EXAMPLE #170
File: gcenv.unix.cpp Project: chunseoklee/coreclr
// Get the process ID of the process.
uint32_t GCToOSInterface::GetCurrentProcessId()
{
    return getpid();
}
EXAMPLE #180
File: 12-1.c Project: shubmit/shub-ltp
int main()
{
	char tmpfname[256];
	int fd;

	struct aiocb *aiocbs[NUM_AIOCBS];
	char *bufs;
	int errors = 0;
	int ret;
	int err;
	int i;

	if (sysconf(_SC_ASYNCHRONOUS_IO) < 200112L)
		exit(PTS_UNSUPPORTED);

	snprintf(tmpfname, sizeof(tmpfname), "/tmp/pts_lio_listio_12_1_%d",
		  getpid());
	unlink(tmpfname);

	fd = open(tmpfname, O_CREAT | O_RDWR | O_EXCL, S_IRUSR | S_IWUSR);

	if (fd == -1) {
		printf(TNAME " Error at open(): %s\n",
		       strerror(errno));
		exit(PTS_UNRESOLVED);
	}

	unlink(tmpfname);

	bufs = (char *) malloc (NUM_AIOCBS*BUF_SIZE);

	if (bufs == NULL) {
		printf (TNAME " Error at malloc(): %s\n", strerror (errno));
		close (fd);
		exit(PTS_UNRESOLVED);
	}

	/* Queue up a bunch of aio writes */
	for (i = 0; i < NUM_AIOCBS; i++) {

		aiocbs[i] = (struct aiocb *)malloc(sizeof(struct aiocb));
		memset(aiocbs[i], 0, sizeof(struct aiocb));

		aiocbs[i]->aio_fildes = fd;
		aiocbs[i]->aio_offset = 0;
		aiocbs[i]->aio_buf = &bufs[i*BUF_SIZE];
		aiocbs[i]->aio_nbytes = BUF_SIZE;
		aiocbs[i]->aio_lio_opcode = LIO_WRITE;
	}

	/* Submit request list */
	ret = lio_listio(LIO_WAIT, aiocbs, NUM_AIOCBS, NULL);

	if (ret) {
		printf(TNAME " Error at lio_listio() %d: %s\n", errno, strerror(errno));
		for (i=0; i<NUM_AIOCBS; i++)
			free (aiocbs[i]);
		free (bufs);
		close (fd);
		exit (PTS_FAIL);
	}

	/* Check return code and free things */
	for (i = 0; i < NUM_AIOCBS; i++) {
	  	err = aio_error(aiocbs[i]);
		ret = aio_return(aiocbs[i]);

		if ((err != 0) && (ret != BUF_SIZE)) {
			printf(TNAME " req %d: error = %d - return = %d\n", i, err, ret);
			errors++;
		}

		free (aiocbs[i]);
	}

	free (bufs);

	close(fd);

	if (errors != 0)
		exit (PTS_FAIL);

	printf (TNAME " PASSED\n");

	return PTS_PASS;
}
EXAMPLE #190
File: proc.c Project: paulfariello/relayd
void
proc_init(struct privsep *ps, struct privsep_proc *procs, u_int nproc)
{
	u_int			 i, j, src, dst;
	struct privsep_pipes	*pp;

	/*
	 * Allocate pipes for all process instances (incl. parent)
	 *
	 * - ps->ps_pipes: N:M mapping
	 * N source processes connected to M destination processes:
	 * [src][instances][dst][instances], for example
	 * [PROC_RELAY][3][PROC_CA][3]
	 *
	 * - ps->ps_pp: per-process 1:M part of ps->ps_pipes
	 * Each process instance has a destination array of socketpair fds:
	 * [dst][instances], for example
	 * [PROC_PARENT][0]
	 */
	for (src = 0; src < PROC_MAX; src++) {
		/* Allocate destination array for each process */
		if ((ps->ps_pipes[src] = calloc(ps->ps_ninstances,
		    sizeof(struct privsep_pipes))) == NULL)
			fatal("proc_init: calloc");

		for (i = 0; i < ps->ps_ninstances; i++) {
			pp = &ps->ps_pipes[src][i];

			for (dst = 0; dst < PROC_MAX; dst++) {
				/* Allocate maximum fd integers */
				if ((pp->pp_pipes[dst] =
				    calloc(ps->ps_ninstances,
				    sizeof(int))) == NULL)
					fatal("proc_init: calloc");

				/* Mark fd as unused */
				for (j = 0; j < ps->ps_ninstances; j++)
					pp->pp_pipes[dst][j] = -1;
			}
		}
	}

	/*
	 * Setup and run the parent and its children
	 */
	privsep_process = PROC_PARENT;
	ps->ps_instances[PROC_PARENT] = 1;
	ps->ps_title[PROC_PARENT] = "parent";
	ps->ps_pid[PROC_PARENT] = getpid();
	ps->ps_pp = &ps->ps_pipes[privsep_process][0];

	for (i = 0; i < nproc; i++) {
		/* Default to 1 process instance */
		if (ps->ps_instances[procs[i].p_id] < 1)
			ps->ps_instances[procs[i].p_id] = 1;
		ps->ps_title[procs[i].p_id] = procs[i].p_title;
	}

	proc_open(ps, NULL, procs, nproc);

	/* Engage! */
	for (i = 0; i < nproc; i++)
		ps->ps_pid[procs[i].p_id] = (*procs[i].p_init)(ps, &procs[i]);
}
EXAMPLE #200
File: manager.c Project: expelliarms/OSLab
int main(int argc,char **argv)
{
    key_t keysem,keyque1,keyque2,keyque3;
    struct sembuf wait1,signal1;
    pid_t managerPID = getpid();
    MESSAGE msg;
    pid_t allPID[10];
    for(i=0;i<2*COUNT;++i)
        {
            for(j=0;j<2;++j)
            {
                matrix_array[i][j] = '0';
            }
            matrix_array[i][j] = '\0';
        }

    FILE * f;
    f = fopen("./matrix.txt","w");
    for(i=0;i<2*COUNT;++i)
    {
        fprintf(f, "%s\n",matrix_array[i]);
    }
    fclose(f);
    signal(SIGUSR1,produce);
    signal(SIGUSR2,consume);
    signal(SIGINT,delete_all);
    if(argc < 2)
    {
        printf("Incorrect Arguments\n");
        printf("Enter the type of process\n");
    }
    int type = atoi(argv[1]);
    wait1.sem_num = 0;
    wait1.sem_op = -1;
    wait1.sem_flg = 0;

     signal1.sem_num = 0;
    signal1.sem_op = 1;
    signal1.sem_flg = 0;


    keysem = ftok(".", 'M');
    int nsem=9;
    semID=semget(keysem, nsem, IPC_CREAT|0666);

    
    ushort val[11] = {1, 1, 1, 1, 1, 10, 0, 10, 0};
// 0 mutex file 1,2 mutex producer q1,q2  3,4 mutex consumer q1,q2 5,6 full,empty q1 7,8 full,empty q2  
    semctl(semID, 0, SETALL, val);

    
    keysem = ftok(".", '1');
    if((mID1 = msgget(keysem, IPC_CREAT | 0660))<0){
        printf("Error Creating Message Queue1\n");
        exit(-1);
    }
    
    
    keysem = ftok(".", '2');
    if((mID2 = msgget(keysem, IPC_CREAT | 0660))<0){
        printf("Error Creating Message Queue2\n");
        exit(-1);
    }
//Creating the producers and consumers
    i=0,j=0;
    while(i<COUNT)
    {
        char parameter1[10],parameter2[10];
        sprintf(parameter1,"%d",managerPID);
        sprintf(parameter2,"%d",i);
        if((allPID[j++] = fork()) == 0)
            {
                int execpro = execl("./producer","./producer",parameter1,parameter2,(const char*) NULL);
                if(execpro <0 ) perror("Error in making producer");
                exit(0);
            }
        i++;
    }
    i=0;
    while(i<COUNT)
    {
        char parameter1[10],parameter2[10];
        sprintf(parameter1,"%d",managerPID);
        sprintf(parameter2,"%d",i);
        if((allPID[j++] = fork()) == 0)
            {
                int execcon = execl("./consumer","./consumer",parameter1,parameter2,argv[1],(const char*) NULL);
                if(execcon < 0) perror("Error in making consumer");
                exit(0);
            }
        i++;
    }
    i=0,j=0;

     while(1)
     {
        sleep(2);
        semop(semID,&wait1,1);
        fp = fopen("matrix.txt", "r");
        if(fp == NULL){
            perror("fopen");
        }
        ssize_t read;
        char *line = NULL;
        size_t len = 0; 
        i=0,j=0;
        while ((read=getline(&line, &len, fp)) != -1)
        {
            // printf("line in manager= %s\n",line);
            for(i=0;i<2;++i)
            {
                matrix_array[j][i] = line[i];
            }
            j++;
        }
        fclose(fp);
        semop(semID,&signal1,1);
        // for(i=0;i<10;++i)
        // {
        //     for(j=0;j<2;++j)
        //     {
        //         printf("%c",matrix_array[i][j]);
        //     }
        //     printf("\n");
        // }
        makeResourceGraph();
        // for(i=0;i<12;++i)
        // {
        //     for(j=0;j<12;++j)
        //     {
        //         printf("%d",graph[i][j]);
        //     }
        //     printf("\n");
        // }
        int flag = checkDeadlock();
        semctl(semID, 0, GETALL, val);     
        if(flag == 1){
            // printf("Deadlock Detected\n");
             for(i=0;i<2*COUNT;++i)
            {
                kill(allPID[i],SIGKILL);
            }
            break;
        }   
    }
    fp = fopen("result.txt", "a");
    if(fp == NULL){
        perror("fopen");
    }
    fprintf(fp,"produce_count = %d consume_count = %d \n",produce_count,consume_count);
    fclose(fp);

    delete_all();
    return 0;
}
EXAMPLE #210
File: pthread_mutexunlock.c Project: justdoitding/Nuttx_PSoC4
int pthread_mutex_unlock(FAR pthread_mutex_t *mutex)
{
  int ret = OK;

  sdbg("mutex=0x%p\n", mutex);

  if (!mutex)
    {
      ret = EINVAL;
    }
  else
    {
      /* Make sure the semaphore is stable while we make the following
       * checks.  This all needs to be one atomic action.
       */

      sched_lock();

      /* Does the calling thread own the semaphore? */

      if (mutex->pid != (int)getpid())
        {
          /* No... return an error (default behavior is like PTHREAD_MUTEX_ERRORCHECK) */

          sdbg("Holder=%d returning EPERM\n", mutex->pid);
          ret = EPERM;
        }


      /* Yes, the caller owns the semaphore.. Is this a recursive mutex? */

#ifdef CONFIG_MUTEX_TYPES
      else if (mutex->type == PTHREAD_MUTEX_RECURSIVE && mutex->nlocks > 1)
        {
          /* This is a recursive mutex and we there are multiple locks held. Retain
           * the mutex lock, just decrement the count of locks held, and return
           * success.
           */
          mutex->nlocks--;
        }
#endif

      /* This is either a non-recursive mutex or is the outermost unlock of
       * a recursive mutex.
       */

      else
        {
          /* Nullify the pid and lock count then post the semaphore */

          mutex->pid    = -1;
#ifdef CONFIG_MUTEX_TYPES
          mutex->nlocks = 0;
#endif
          ret = pthread_givesemaphore((FAR sem_t *)&mutex->sem);
        }
      sched_unlock();
    }

  sdbg("Returning %d\n", ret);
  return ret;
}
EXAMPLE #220
File: hydra-http-proxy-urlenum.c Project: Bluelich/thc-hydra
void service_http_proxy_urlenum(char *ip, int sp, unsigned char options, char *miscptr, FILE * fp, int port) {
  int run = 1, next_run = 1, sock = -1;
  int myport = PORT_HTTP_PROXY, mysslport = PORT_HTTP_PROXY_SSL;

  hydra_register_socket(sp);
  if (memcmp(hydra_get_next_pair(), &HYDRA_EXIT, sizeof(HYDRA_EXIT)) == 0)
    return;

  while (1) {
    next_run = 0;
    switch (run) {
    case 1:                    /* connect and service init function */
      {
        if (sock >= 0)
          sock = hydra_disconnect(sock);
//        sleepn(275);
        if ((options & OPTION_SSL) == 0) {
          if (port != 0)
            myport = port;
          sock = hydra_connect_tcp(ip, myport);
          port = myport;
        } else {
          if (port != 0)
            mysslport = port;
          sock = hydra_connect_ssl(ip, mysslport);
          port = mysslport;
        }
        if (sock < 0) {
          if (quiet != 1) fprintf(stderr, "[ERROR] Child with pid %d terminating, can not connect\n", (int) getpid());
          hydra_child_exit(1);
        }
        next_run = 2;
        break;
      }
    case 2:                    /* run the cracking function */
      next_run = start_http_proxy_urlenum(sock, ip, port, options, miscptr, fp);
      break;
    case 3:                    /* clean exit */
      if (sock >= 0)
        sock = hydra_disconnect(sock);
      hydra_child_exit(0);
      return;
    default:
      fprintf(stderr, "[ERROR] Caught unknown return code, exiting!\n");
      hydra_child_exit(0);
    }
    run = next_run;
  }
}
EXAMPLE #230
File: ntp_filegen.c Project: traveller42/ntpsec
static void
filegen_open(
	FILEGEN *	gen,
	uint32_t		stamp,
	const time_t *	pivot
	)
{
	char *savename;	/* temp store for name collision handling */
	char *fullname;	/* name with any designation extension */
	char *filename;	/* name without designation extension */
	char *suffix;	/* where to print suffix extension */
	u_int len, suflen;
	FILE *fp;
	struct calendar cal;
	struct isodate	iso;

	/* get basic filename in buffer, leave room for extensions */
	len = strlen(gen->dir) + strlen(gen->fname) + 65;
	filename = emalloc(len);
	fullname = emalloc(len);
	savename = NULL;
	snprintf(filename, len, "%s%s", gen->dir, gen->fname);

	/* where to place suffix */
	suflen = strlcpy(fullname, filename, len);
	suffix = fullname + suflen;
	suflen = len - suflen;

	/* last octet of fullname set to '\0' for truncation check */
	fullname[len - 1] = '\0';

	switch (gen->type) {

	default:
		msyslog(LOG_ERR, 
			"unsupported file generations type %d for "
			"\"%s\" - reverting to FILEGEN_NONE",
			gen->type, filename);
		gen->type = FILEGEN_NONE;
		break;

	case FILEGEN_NONE:
		/* no suffix, all set */
		break;

	case FILEGEN_PID:
		gen->id_lo = getpid();
		gen->id_hi = 0;
		snprintf(suffix, suflen, "%c#%ld",
			 SUFFIX_SEP, gen->id_lo);
		break;

	case FILEGEN_DAY:
		/*
		 * You can argue here in favor of using MJD, but I
		 * would assume it to be easier for humans to interpret
		 * dates in a format they are used to in everyday life.
		 */
		ntpcal_ntp_to_date(&cal, stamp, pivot);
		snprintf(suffix, suflen, "%c%04d%02d%02d",
			 SUFFIX_SEP, cal.year, cal.month, cal.monthday);
		cal.hour = cal.minute = cal.second = 0;
		gen->id_lo = ntpcal_date_to_ntp(&cal); 
		gen->id_hi = (uint32_t)(gen->id_lo + SECSPERDAY);
		break;

	case FILEGEN_WEEK:
		isocal_ntp_to_date(&iso, stamp, pivot);
		snprintf(suffix, suflen, "%c%04dw%02d",
			 SUFFIX_SEP, iso.year, iso.week);
		iso.hour = iso.minute = iso.second = 0;
		iso.weekday = 1;
		gen->id_lo = isocal_date_to_ntp(&iso);
		gen->id_hi = (uint32_t)(gen->id_lo + 7 * SECSPERDAY);
		break;

	case FILEGEN_MONTH:
		ntpcal_ntp_to_date(&cal, stamp, pivot);
		snprintf(suffix, suflen, "%c%04d%02d",
			 SUFFIX_SEP, cal.year, cal.month);
		cal.hour = cal.minute = cal.second = 0;
		cal.monthday = 1;
		gen->id_lo = ntpcal_date_to_ntp(&cal); 
		cal.month++;
		gen->id_hi = ntpcal_date_to_ntp(&cal); 
		break;

	case FILEGEN_YEAR:
		ntpcal_ntp_to_date(&cal, stamp, pivot);
		snprintf(suffix, suflen, "%c%04d",
			 SUFFIX_SEP, cal.year);
		cal.hour = cal.minute = cal.second = 0;
		cal.month = cal.monthday = 1;
		gen->id_lo = ntpcal_date_to_ntp(&cal); 
		cal.year++;
		gen->id_hi = ntpcal_date_to_ntp(&cal); 
		break;

	case FILEGEN_AGE:
		gen->id_lo = current_time - (current_time % SECSPERDAY);
		gen->id_hi = gen->id_lo + SECSPERDAY;
		snprintf(suffix, suflen, "%ca%08ld",
			 SUFFIX_SEP, gen->id_lo);
	}
  
	/* check possible truncation */
	if ('\0' != fullname[len - 1]) {
		fullname[len - 1] = '\0';
		msyslog(LOG_ERR, "logfile name truncated: \"%s\"",
			fullname);
	}

	if (FILEGEN_NONE != gen->type) {
		/*
		 * check for existence of a file with name 'basename'
		 * as we disallow such a file
		 * if FGEN_FLAG_LINK is set create a link
		 */
		struct stat stats;
		/*
		 * try to resolve name collisions
		 */
		static u_long conflicts = 0;

#ifndef	S_ISREG
#define	S_ISREG(mode)	(((mode) & S_IFREG) == S_IFREG)
#endif
		if (stat(filename, &stats) == 0) {
			/* Hm, file exists... */
			if (S_ISREG(stats.st_mode)) {
				if (stats.st_nlink <= 1)	{
					/*
					 * Oh, it is not linked - try to save it
					 */
					savename = emalloc(len);
					snprintf(savename, len,
						"%s%c%dC%lu",
						filename, SUFFIX_SEP,
						(int)getpid(), conflicts++);

					if (rename(filename, savename) != 0)
						msyslog(LOG_ERR,
							"couldn't save %s: %m",
							filename);
					free(savename);
				} else {
					/*
					 * there is at least a second link to
					 * this file.
					 * just remove the conflicting one
					 */
					/* coverity[toctou] */
					if (unlink(filename) != 0)
						msyslog(LOG_ERR, 
							"couldn't unlink %s: %m",
							filename);
				}
			} else {
				/*
				 * Ehh? Not a regular file ?? strange !!!!
				 */
				msyslog(LOG_ERR, 
					"expected regular file for %s "
					"(found mode 0%lo)",
					filename,
					(unsigned long)stats.st_mode);
			}
		} else {
			/*
			 * stat(..) failed, but it is absolutely correct for
			 * 'basename' not to exist
			 */
			if (ENOENT != errno)
				msyslog(LOG_ERR, "stat(%s) failed: %m",
						 filename);
		}
	}

	/*
	 * now, try to open new file generation...
	 */
	DPRINTF(4, ("opening filegen (type=%d/stamp=%u) \"%s\"\n",
		    gen->type, stamp, fullname));

	fp = fopen(fullname, "a");
  
	if (NULL == fp)	{
		/* open failed -- keep previous state
		 *
		 * If the file was open before keep the previous generation.
		 * This will cause output to end up in the 'wrong' file,
		 * but I think this is still better than losing output
		 *
		 * ignore errors due to missing directories
		 */

		if (ENOENT != errno)
			msyslog(LOG_ERR, "can't open %s: %m", fullname);
	} else {
		if (NULL != gen->fp) {
			fclose(gen->fp);
			gen->fp = NULL;
		}
		gen->fp = fp;

		if (gen->flag & FGEN_FLAG_LINK) {
			/*
			 * need to link file to basename
			 * have to use hardlink for now as I want to allow
			 * gen->basename spanning directory levels
			 * this would make it more complex to get the correct
			 * fullname for symlink
			 *
			 * Ok, it would just mean taking the part following
			 * the last '/' in the name.... Should add it later....
			 */

			/* Windows NT does not support file links -Greg Schueman 1/18/97 */

#if defined(SYS_WINNT)
			SetLastError(0); /* On WinNT, don't support FGEN_FLAG_LINK */
#else  /* not WINNT ; DO THE LINK) */
			if (link(fullname, filename) != 0)
				if (EEXIST != errno)
					msyslog(LOG_ERR, 
						"can't link(%s, %s): %m",
						fullname, filename);
#endif /* SYS_WINNT */
		}		/* flags & FGEN_FLAG_LINK */
	}			/* else fp == NULL */
	
	free(filename);
	free(fullname);
	return;
}
EXAMPLE #240
File: delay_acct.c Project: allskyee/tools
int main(int argc, char* argv[])
{
    int c, ret = -1;
    char* log_file = NULL;
    char* cpu_mask = NULL;
    int rc, mode = 0, tid;

    while ((c = getopt(argc, argv, "c:l:m:")) != -1) {
        switch(c) {
        case 'l' :
            log_file = strdup(optarg);
            break;
        case 'c' :
            cpu_mask = strdup(optarg);
            break;
        case 'm' :
            if (strcmp(optarg, "1") == 0)
                mode = 1;
            else if (strcmp(optarg, "2") == 0)
                mode = 2;
            else if (strcmp(optarg, "3") == 0)
                mode = 3;
            break;
        default :
            fprintf(stderr, "unknown option %c\n", c);
            exit(-1);
        }
    }

    /*
     * checking an dealing with input parameters
     */
    if (log_file) {
        if (!(f = fopen(log_file, "w"))) {
            fprintf(stderr, "cannot open file\n");
            goto out;
        }
    }
    else {
        f = stdout;
    }

    if (!mode) {
        ERROR("must specify mode\n");
        goto out;
    }

    if (!cpu_mask) {
        ERROR("need to specify CPU type\n");
        goto out;
    }

    /*
     * setting up system stuff
     */
    if ((pid_max = get_pid_max()) < 0) {
        ERROR("unable to get pid_max\n");
        goto out;
    }

    PRINTF("pid_max is %d\n", pid_max);
    
    signal(SIGINT, sig_int_cb);
    if ((nl_sd = create_nl_socket(NETLINK_GENERIC)) < 0) {
        ERROR("error creating Netlink socket\n");
        goto out;
    }

    /*
     * register taskstats notifier
     */
    fam_id = __get_family_id(nl_sd);
    if (!fam_id) {
        ERROR("Error getting family id, errno %d\n", errno);
        goto out;
    }

    my_pid = getpid();
    if ((rc = send_cmd(TASKSTATS_CMD_GET,
        TASKSTATS_CMD_ATTR_REGISTER_CPUMASK, cpu_mask, strlen(cpu_mask))) < 0) {
        ERROR("error sending register cpumask\n");
        goto out;
    }

    /*
     * now for the main loop
     * modes of operations 
     * i) get all process stats and print
     * ii) wait until receive signal (be polling for dead process in meantime)
     *     then get all process stats
     * iii) get all process stats, then wait for signal and print diff
     */
    if (mode == 1) {
        fill_infos(infos1);
        for (tid = 0; tid < pid_max; tid++) {
            if (!infos1[tid])
                continue;
            print_taskstats(&infos1[tid]->t);
        }
    }
    else if (mode == 2) {
        PRINTF("waiting for signal\n");
        while (!sig_int)
            sleep(1);
        fill_infos(infos1);
        for (tid = 0; tid < pid_max; tid++) {
            if (!infos1[tid])
                continue;
            print_taskstats(&infos1[tid]->t);
        }
    }
    else if (mode == 3) {
        struct timeval start_since_epoch;
        struct timespec start, end;
        static struct taskstats ts_tot = {0};

        if (fill_infos(infos1) < 0) {
            ERROR("error before start\n");
            goto out;
        }

        if (clock_gettime(CLOCK_MONOTONIC, &start) < 0) {
            ERROR("unable to get start time\n");
            goto out;
        }

        if (gettimeofday(&start_since_epoch, NULL)) { 
            ERROR("unable to get start time since epoch\n");
            goto out;
        }

        PRINTF("waiting for signal\n");
        while (!sig_int) {
            ret = recv_taskstats(MSG_DONTWAIT, infos2);

            if (ret == 0 || ret == -EAGAIN) {
                usleep(10000);
                continue;
            }

            ERROR("unable to recv taskstats, %d\n", ret);
            goto out;
        }

        if (fill_infos(infos2) < 0) {
            ERROR("error at end\n");
            goto out;
        }
        if (clock_gettime(CLOCK_MONOTONIC, &end) < 0) {
            ERROR("unable to get end time\n");
            goto out;
        }

        PRINTF("--- task dump start ---\n");

        for (tid = 0; tid < pid_max; tid++) {
            struct proc_info* p1 = infos1[tid];
            struct proc_info* p2 = infos2[tid];

            if (!(p1 || p2))
                continue;
            else if (p1 && p2) {
                static struct taskstats ts;
                diff_taskstats(&ts, &p2->t, &p1->t);
                print_taskstats(&ts);
            }
            else if (p2) {
                print_taskstats(&p2->t);
            }
        }
        PRINTF("--- task dump end ---\n");

        PRINTF("Start since epoch (s) %d\n", start_since_epoch.tv_sec);
        PRINTF("Elapsed time (ns) %llu\n",
            ((long long)end.tv_sec - start.tv_sec) * 1000000000LL +
            end.tv_nsec - start.tv_nsec);
    }

out : 
    if (f != stdout)
        fclose(f);

    return ret;
}
EXAMPLE #250
File: appmon_daemon.c Project: WeiY/mihini-repo
static char* start_app(app_t* app)
{
  char* wd = app->wd, *prog = app->prog;
  int id = app->id;
  SWI_LOG("APPMON", DEBUG, "start_app, id=%d, wd=%s; prog=%s\n", id, wd, prog);
  char * res = check_params(wd, prog);
  if (res) //check param errors
    return res;

  pid_t child_pid = fork();
  if (-1 == child_pid)
  {
    perror("start_app");
    res = "Fork error, cannot create new process";
    SWI_LOG("APPMON", ERROR, "%s\n", res);
    return res;
  }
  if (0 == child_pid)
  { //in child
    // close inherited stuff
    // note: sig handlers are reset
    close(srv_skt);
    close(client_skt);
    //child will actually run the application
    if (-1 == chdir(wd))
    {
      perror("cannot change working dir: chdir error");
      exit(EXIT_FAILURE);
    }

    setpgrp(); //equivalent to setpgrp(0, 0).
    //the point is that the child process is getting its own process group id, and becomes this process group leader
    //then on stop() daemon will send TERM signal to the process group of the child so that all children of this command will receive this signal.
    //so that all children of the application are killed too.
    //TODO: check if using setsid() can do the same thing, setsid might be more POSIX friendly (setpgrp() is indicated System V)
    SWI_LOG("APPMON", DEBUG, "Child: id= %d, pid=%d,  process group id set to = %d\n", id, getpid(), getpgrp());

    //change uid/gid/priority if necessary
    if (!app->privileged)
    {
      umask(S_IWOTH); //umask man reports that umask always succeeds...
      //SWI_LOG("APPMON", ERROR,"Failed to set umask")

      //may call error
      set_uid_gids(uid, gid, id);

      if (INT_MAX != app_priority)
      {
        //compute nice increment to give to nice
        int current_priority = getpriority(PRIO_PROCESS, 0);
        int nice_inc = app_priority - current_priority;
        //see nice man page, need to test errno manually
        errno = 0;
        int res = nice(nice_inc);
        if (errno)
        {
          SWI_LOG("APPMON", ERROR, "Child: id= %d, error while doing nice failed :%s, target priority was: %d, starting app with priority =%d\n",
                   id, strerror(errno), app_priority, getpriority(PRIO_PROCESS, 0));
        }
        else
        {
          if (res != app_priority)
            SWI_LOG("APPMON", ERROR, "Child: id= %d, nice failed : new priority=%d\n", id, res);
          else
            SWI_LOG("APPMON", DEBUG, "Child: id= %d, new priority=%d\n", id, res);
        }
      }
    }
    else //privileged app
    {
      set_uid_gids(puid, pgid, id);
      //no process priority change for privileged app
    }
    SWI_LOG("APPMON", DEBUG, "Child: id= %d, running with uid=%d gid=%d, eff uid=%d\n", id, getuid(), getgid(), geteuid());

    char* const argv[] = { prog, NULL };
    execvp(prog, argv);
    perror("");
    SWI_LOG("APPMON", ERROR, "Child: execvp has returned, error must have occurred\n");
    exit(EXIT_FAILURE);
  }
  //in daemon: everything is ok, update app infos.
  app->status = STARTED;
  app->pid = child_pid;
  app->start_count++;
  return "ok";
}
EXAMPLE #260
File: main.cpp Project: kyusof/SilkJS
void AnsiSignalHandler(int sig) {
    signal(sig, AnsiSignalHandler);
    printf("Caught Signal %d for thread: %ld\n", sig, (size_t)getpid());
	exit(11);
}
EXAMPLE #270
File: appmon_daemon.c Project: WeiY/mihini-repo
int main(int argc, char** argv)
{
  char *buffer = NULL;
  int portno = 0, stop, optval;
  socklen_t clilen;
  struct sockaddr_in serv_addr, cli_addr;
  struct sigaction action_CHLD;
  struct sigaction action_ALRM;

  /* Preliminary signal configuration:
   * SIGCHLD and SIGALRM are used with different handler
   * configure each handler to mask the other signal during it's process
   * Note: within a handler called upon a signal SIGX, the SIGX signal is
   * automatically de-activated.
   */

  sigemptyset(&block_sigs);
  sigaddset(&block_sigs, SIGCHLD);
  sigaddset(&block_sigs, SIGALRM);

  action_CHLD.sa_flags = SA_RESTART;
  action_CHLD.sa_handler = SIGCHLD_handler;
  sigemptyset(&(action_CHLD.sa_mask));
  sigaddset(&(action_CHLD.sa_mask), SIGALRM);

  action_ALRM.sa_flags = SA_RESTART;
  action_ALRM.sa_handler = SIGALRM_handler;
  sigemptyset(&(action_ALRM.sa_mask));
  sigaddset(&(action_ALRM.sa_mask), SIGCHLD);

  PointerList_Create(&apps, 0);
  if (NULL == apps)
    err_exit("PointerList_Create");

  /* Command line arguments Parsing
   * Options
   * a : privileged app path
   * w : privileged app working directory
   * v : user id to use to start privileged app
   * h : group id to use to start privileged app
   * p : TCP port to receive commands
   * u : user id to use to start regular apps
   * g : group id to use to start regular apps
   * n : nice value (process priority) for regular apps
   */
  char* init_app = NULL;
  char* init_app_wd = NULL;
  app_t* privileged_app = NULL;
  int opt;
  char useropt_given = 0;
  char grpopt_given = 0;
  //optarg is set by getopt
  while ((opt = getopt(argc, argv, "a:w:v:h:p:u:g:n:")) != -1)
  {
    switch (opt)
    {
      case 'a':
        init_app = optarg;
        SWI_LOG("APPMON", DEBUG, "Command line arguments parsing: init_app %s\n", init_app);
        break;
      case 'w':
        init_app_wd = optarg;
        SWI_LOG("APPMON", DEBUG, "Command line arguments parsing: init_app_wd %s\n", init_app_wd);
        break;
      case 'p':
        parse_arg_integer(optarg, &portno, "Command line arguments parsing: bad format for port argument");
        SWI_LOG("APPMON", DEBUG, "Command line arguments parsing: port =%d\n", portno);
        if (portno > UINT16_MAX)
        {
          err_exit("Command line arguments parsing: bad value for port, range=[0, 65535]");
        }
        break;
      case 'u':
        useropt_given = 1; //used to set default value after cmd line option parsing
        get_uid_option(&uid);
        break;
      case 'v':
        get_uid_option(&puid);
        break;
      case 'g':
        grpopt_given = 1; //used to set default value after cmd line option parsing
        get_gid_option(&gid);
        break;
      case 'h':
        get_gid_option(&pgid);
        break;
      case 'n':
        parse_arg_integer(optarg, &app_priority,
            "Command line arguments parsing: app process priority must be an integer");
        if (19 < app_priority || -20 > app_priority)
        {
          err_exit("Command line arguments parsing: app process priority must be between -20 and 19");
        }
        SWI_LOG("APPMON", DEBUG, "Command line arguments parsing: nice increment =%d\n", app_priority);
        break;
      default: /* '?' */
        SWI_LOG("APPMON", ERROR, "Command line arguments parsing: unknown argument\n");
        break;
    }

  }
  if (NULL != init_app)
  {

    if (NULL == init_app_wd)
    { //using current working directory as privileged app wd.
      cwd = malloc(PATH_MAX);
      if (NULL == cwd)
      {
        err_exit("Cannot malloc init_app_wd");
      }
      cwd = getcwd(cwd, PATH_MAX);
      if (NULL == cwd)
      {
        err_exit("getcwd failed to guess privileged app default wd");
      }
      init_app_wd = cwd;
    }
    char * res = check_params(init_app_wd, init_app);
    if (NULL != res)
    {
      SWI_LOG("APPMON", ERROR, "check_params on privileged app failed: %s\n", res);
      err_exit("check_params on privileged app failed");
    }
    privileged_app = add_app(init_app_wd, init_app, 1);
    if (NULL == privileged_app)
    {
      err_exit("add_app on privileged app failed");
    }
  }

  if (!uid && !useropt_given)
  { //get default "nobody" user.
    uid = 65534;
  }

  if (!gid && !grpopt_given)
  { //get default "nogroup" group.
    gid = 65534;
  }

  SWI_LOG("APPMON", DEBUG, "Command line arguments parsing: will use uid=%d and gid=%d to run unprivileged apps\n",
      uid, gid);

  /* configuring signals handling */
  if (sigaction(SIGCHLD, &action_CHLD, NULL))
    err_exit("configuring signals handling: sigaction SIGCHLD call error");

  if (sigaction(SIGALRM, &action_ALRM, NULL))
    err_exit("configuring signals handling: sigaction SIGCHLD call error");

  srv_skt = socket(AF_INET, SOCK_STREAM, 0);
  if (srv_skt < 0)
    err_exit("socket configuration: opening socket error");

  // set SO_REUSEADDR on socket:
  optval = 1;
  if (setsockopt(srv_skt, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof optval))
    err_exit("socket configuration: setting SO_REUSEADDR on socket failed");

  bzero((char *) &serv_addr, sizeof(serv_addr));
  portno = portno ? portno : DEFAULT_LISTENING_PORT;

  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(portno);

  if (bind(srv_skt, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
    err_exit("socket configuration: error on binding");

  if (listen(srv_skt, 5))
    err_exit("socket configuration: error on listen");

  clilen = sizeof(cli_addr);
  stop = 0;

  SWI_LOG("APPMON", DEBUG, "Init successful, now running as daemon.\n");
  /* daemonize the later possible to enhance sync error reporting*/
  daemonize();
  /* Now we are a simple daemon */
  SWI_LOG("APPMON", DEBUG, "Daemon pid=%d, Listening port = %d\n", getpid(), portno);

  if (privileged_app)
  {
    SWI_LOG("APPMON", DEBUG, "Autostarting privileged app\n");
    start_app(privileged_app);
  }

  while (!stop)
  {
    fflush(stdout);
    client_skt = accept(srv_skt, (struct sockaddr *) &cli_addr, &clilen);
    if (client_skt < 0)
    {
      SWI_LOG("APPMON", ERROR, "socket configuration: error on accept: %s\n", strerror(errno));
      SWI_LOG("APPMON", ERROR, "Now going to crippled mode: cannot use socket API anymore!\n");
      if (client_skt)
        close(client_skt);
      if (srv_skt)
        close(srv_skt);
      // Sleep for 1.5 sec
      // sleep() function not used here, as it may disrupt the use of SIGALRM made in this program.
      struct timeval tv;
      while (1)
      {
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        int res = select(0, NULL, NULL, NULL, &tv);
        SWI_LOG("APPMON", DEBUG, "crippled mode: select, res = %d\n", res);
      }
      //never returning from here, need to kill the daemon
      // but apps should still be managed.
    }

    SWI_LOG("APPMON", DEBUG, "new client ...\n");
    buffer = readline(client_skt);

    //deal with all the requests coming from the new client
    while (NULL != buffer && !stop)
    {
      SWI_LOG("APPMON", DEBUG, "NEW cmd=[%s]\n", buffer);
      do
      {
        if (!strncmp(buffer, STOP_DAEMON, strlen(STOP_DAEMON)))
        {
          stop = 1;
          send_result("ok, destroy is in progress, stopping aps, closing sockets.");
          break;
        }
        if (!strncmp(buffer, PCONFIG, strlen(PCONFIG)))
        {
          send_result(
              fill_output_buf(
                  "appmon_daemon: version[%s], uid=[%d], gid=[%d], puid=[%d], pgid=[%d], app_priority=[%d]",
                  GIT_REV, uid, gid, puid, pgid, app_priority));
          break;
        }
        if (!strncmp(buffer, SETUP_APP, strlen(SETUP_APP)))
        {
          char* buf = buffer;
          strsep(&buf, " ");
          char* wd = strsep(&buf, " ");
          char* prog = strsep(&buf, " ");

          SWI_LOG("APPMON", DEBUG, "SETUP wd =%s, prog = %s\n", wd, prog);
          if (NULL == wd || NULL == prog)
          {
            send_result("Bad command format, must have wd and prog params");
            break;
          }
          char *res = check_params(wd, prog);
          if (res)
          {
            send_result(res);
            break;
          }
          sigprocmask(SIG_BLOCK, &block_sigs, NULL);
          app_t* app = add_app(wd, prog, 0);
          if (NULL == app)
            send_result("Cannot add app");
          else
            send_result(fill_output_buf("%d", app->id));

          sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);

          break;
        }
        if (!strncmp(buffer, START_APP, strlen(START_APP)))
        {
          char* str_id = buffer + strlen(START_APP);
          int id = atoi(str_id);
          SWI_LOG("APPMON", DEBUG, "START_APP, id =%d\n", id);
          if (id == 0)
          {
            send_result("Bad command format, start called with invalid app id");
            break;
          }
          sigprocmask(SIG_BLOCK, &block_sigs, NULL);
          app_t* app = find_by_id(id);
          if (app == NULL)
          {
            send_result("Unknown app");
            sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
            break;
          }
          if (app->privileged)
          {
            send_result("Privileged App, cannot act on it through socket.");
            sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
            break;
          }
          if (app->status != KILLED)
          {
            send_result("App already running (or set to be restarted), start command discarded");
            sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
            break;
          }
          send_result(start_app(app));
          sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
          break;
        }

        if (!strncmp(buffer, STOP_APP, strlen(STOP_APP)))
        {
          char* str_id = buffer + strlen(STOP_APP);
          int id = atoi(str_id);
          if (id == 0)
          {
            send_result("Bad command format, stop called with invalid app id");
            break;
          }
          sigprocmask(SIG_BLOCK, &block_sigs, NULL);
          app_t* app = find_by_id(id);
          if (NULL == app)
            send_result("Unknown app");
          else
          {
            if (app->privileged)
            {
              send_result("Privileged App, cannot act on it through socket.");
              sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
              break;
            }

            //stop command has effect only if application is running.
            if (app->status == STARTED || app->status == TO_BE_KILLED)
            {
              send_result(stop_app(app));
            }
            else
            { //application is already stopped (app->status could be KILLED or TO_BE_RESTARTED)
              app->status = KILLED; //force app->status =  KILLED, prevent app to be restarted if restart was scheduled. (see SIG ALRM handler)
              send_result("ok, already stopped, won't be automatically restarted anymore");
            }

          }
          sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
          break;
        }

        if (!strncmp(buffer, REMOVE_APP, strlen(REMOVE_APP)))
        {
          char* str_id = buffer + strlen(REMOVE_APP);
          int id = atoi(str_id);
          if (id == 0)
          {
            send_result("Bad command format, remove called with invalid app id");
            break;
          }
          sigprocmask(SIG_BLOCK, &block_sigs, NULL);
          app_t* app = find_by_id(id);
          if (NULL == app)
            send_result("Unknown app");
          else
          {
            if (app->privileged)
            {
              send_result("Privileged App, cannot act on it through socket.");
              sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
              break;
            }
            //stop command has effect only if application is running.
            if (app->status == STARTED || app->status == TO_BE_KILLED)
            {
              stop_app(app); //trying to stop, no big deal with it fails
            }

            app_t* app = NULL;
            unsigned int size, i = 0;
            PointerList_GetSize(apps, &size, NULL);
            for (i = 0; i < size; i++)
            {
              PointerList_Peek(apps, i, (void**) &app);
              if (app->id == id)
              {
                swi_status_t res = 0;
                if (SWI_STATUS_OK != (res = PointerList_Remove(apps, i, (void**) &app)))
                {
                  send_result(fill_output_buf("Remove: PointerList_Remove failed, AwtStatus =%d", res));
                }
                else
                {
                  free(app);
                  send_result("ok");
                }
                break;
              }
            }
          }
          sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
          break;
        }

        if (!strncmp(buffer, STATUS_APP, strlen(STATUS_APP)))
        {
          char* str_id = buffer + strlen(STATUS_APP);
          int id = atoi(str_id);
          if (id == 0)
          {
            send_result("Bad command format, status called with invalid app id");
            break;
          }

          sigprocmask(SIG_BLOCK, &block_sigs, NULL);
          app_t* app = find_by_id(id);
          if (NULL == app)
            send_result("Unknown app");
          else
          {
            SWI_LOG("APPMON", DEBUG, "sending app status...\n");
            send_result(create_app_status(app));
          }
          sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
          break;
        }
        if (!strncmp(buffer, LIST_APPS, strlen(LIST_APPS)))
        {
          SWI_LOG("APPMON", DEBUG, "sending app list ...\n");
          sigprocmask(SIG_BLOCK, &block_sigs, NULL);
          app_t* app = NULL;
          unsigned int size, i = 0;
          PointerList_GetSize(apps, &size, NULL);
          for (i = 0; i < size; i++)
          {
            PointerList_Peek(apps, i, (void**) &app);
            char* app_status_tmp = create_app_status(app);
            if (strlen(app_status_tmp) != write(client_skt, app_status_tmp, strlen(app_status_tmp)))
            {
              SWI_LOG("APPMON", ERROR, "list: cannot write res to socket\n");
            }
            SWI_LOG("APPMON", DEBUG, "list: send status, app_status_tmp=%s\n", app_status_tmp);
            char* statussep = "\t";
            if (strlen(statussep) != write(client_skt, statussep, strlen(statussep)))
            {
              SWI_LOG("APPMON", ERROR, "list: cannot write statussep: %s\n", statussep);
            }
          }
          send_result("");
          sigprocmask(SIG_UNBLOCK, &block_sigs, NULL);
          break;
        }
        if (!strncmp(buffer, SETENV, strlen(SETENV)))
        {
          char *arg, *varname, *tmp;

          arg = buffer + strlen(SETENV);
          varname = arg;
          tmp = strchr(arg, '=');
          *tmp++ = '\0';

          SWI_LOG("APPMON", DEBUG, "Setting Application framework environment variable %s = %s...\n", varname, tmp);
          setenv(varname, tmp, 1);

          send_result("");
          break;
        }

        //command not found
        send_result("command not found");
        SWI_LOG("APPMON", DEBUG, "Command not found\n");
      } while (0);

      if (stop)
        break;

      //read some data again to allow to send several commands with the same socket
      buffer = readline(client_skt);

    } //end while buffer not NULL: current client has no more data to send

    //current client exited, let's close client skt, wait for another connexion
    close(client_skt);
  }

  sigprocmask(SIG_BLOCK, &block_sigs, NULL);
  int exit_status_daemon = clean_all();
  SWI_LOG("APPMON", DEBUG, "appmon daemon end, exit_status_daemon: %d\n", exit_status_daemon);
  return exit_status_daemon;
}
EXAMPLE #280
File: list.c Project: snarlistic/jpnevulator
int main(int argc,char **argv) {
	list_t list;
	int index;
	char *arg;
	int elements;
	/* Initialize our list. */
	listInitialize(&list);
	/* Fill our list with all command line arguments given, but skip the
	 * first argument since that's our needle (see below -> listSearch()). */
	for(index=2;index<argc;index++) {
		/* Append the argument to our list. */
		if(listAppend(&list,(void *)argv[index])!=listRtrnOk) {
			fprintf(stderr,"Can't create item!\n");
			break;
		}
		/* Advance to this next position. By default listAppend() does not
		 * advance our current pointer to the appended element. */
		listNext(&list);
	}
	/* Print all our arguments from the first to the last. */
	printf("First to last:\n");
	/* Does any argument exist? */
	if((arg=(char *)listFirst(&list))!=NULL) {
		/* Yes, we print it and... */
		do {
			printf("[%s]\n",arg);
			/* ...advance to the next argument, untill none left. */
		} while((arg=(char *)listNext(&list))!=NULL);
	} else {
		printf("empty list\n");
	}
	/* Print all our arguments from the last to the first. */
	printf("Last to first:\n");
	/* Does any argument exist? */
	if((arg=(char *)listLast(&list))!=NULL) {
		/* Yes, we print it and... */
		do {
			printf("[%s]\n",arg);
			/* ...advance to the next argument, untill none left. */
		} while((arg=(char *)listPrevious(&list))!=NULL);
	} else {
		printf("empty list\n");
	}
	/* If there do exist enough arguments... */
	if(argc>=2) {
		/* ...search for the first one given... */
		arg=listSearch(&list,cmpr,(void *)argv[1]);
		/* ...and tell if it's found. */
		printf("searching for [%s]... %sfound\n",argv[1],arg!=NULL?"":"not ");
	}
	/* Randomly remove half of the arguments. */
	srandom(getpid());
	for(elements=listElements(&list)/2;elements>0;elements--) {
		int element=(random()%(argc-2))+2;
		arg=listSearch(&list,cmpr,(void *)argv[element]);
		printf("Removing [%s]... ",argv[element]);
		if(arg!=NULL) {
			listRemove(&list,NULL);
			printf("ok\n");
		} else {
			printf("not in the list!\n");
		}
	}
	/* Print all our arguments from the first to the last. */
	printf("First to last:\n");
	/* Does any argument exist? */
	if((arg=(char *)listFirst(&list))!=NULL) {
		/* Yes, we print it and... */
		do {
			printf("[%s]\n",arg);
			/* ...advance to the next argument, untill none left. */
		} while((arg=(char *)listNext(&list))!=NULL);
	} else {
		printf("empty list\n");
	}
	/* Print all our arguments from the last to the first. */
	printf("Last to first:\n");
	/* Does any argument exist? */
	if((arg=(char *)listLast(&list))!=NULL) {
		/* Yes, we print it and... */
		do {
			printf("[%s]\n",arg);
			/* ...advance to the next argument, untill none left. */
		} while((arg=(char *)listPrevious(&list))!=NULL);
	} else {
		printf("empty list\n");
	}

	/* Destroy the list and all its elements. */
	listDestroy(&list,garbageCollect);
	return(0);
}
EXAMPLE #290
File: autorespond.c Project: debdungeon/qint
int send_message(char * msg, char * from, char ** recipients, int num_recipients)
{
    /*	...Adds Date:
    	...Adds Message-Id:*/
    int r;
    int wstat;
    int i;
    struct tm * dt;
    unsigned long msgwhen;
    FILE * fdm;
    FILE * fde;
    pid_t pid;
    int pim[2];				/*message pipe*/
    int pie[2];				/*envelope pipe*/
    FILE *mfp;
    char msg_buffer[256];

    /*open a pipe to qmail-queue*/
    if(pipe(pim)==-1 || pipe(pie)==-1) {
        return -1;
    }
    pid = vfork();
    if(pid == -1) {
        /*failure*/
        return -1;
    }
    if(pid == 0) {
        /*I am the child*/
        close(pim[1]);
        close(pie[1]);
        /*switch the pipes to fd 0 and 1
          pim[0] goes to 0 (stdin)...the message*/
        if(fcntl(pim[0],F_GETFL,0) == -1) {
            /*			fprintf(stderr,"Failure getting status flags.\n");*/
            _exit(120);
        }
        close(0);
        if(fcntl(pim[0],F_DUPFD,0)==-1) {
            /*			fprintf(stderr,"Failure duplicating file descriptor.\n");*/
            _exit(120);
        }
        close(pim[0]);
        /*pie[0] goes to 1 (stdout)*/
        if(fcntl(pie[0],F_GETFL,0) == -1) {
            /*			fprintf(stderr,"Failure getting status flags.\n");*/
            _exit(120);
        }
        close(1);
        if(fcntl(pie[0],F_DUPFD,1)==-1) {
            /*			fprintf(stderr,"Failure duplicating file descriptor.\n");*/
            _exit(120);
        }
        close(pie[0]);
        if(chdir(QMAIL_LOCATION) == -1) {
            _exit(120);
        }
        execv(*binqqargs,binqqargs);
        _exit(120);
    }

    /*I am the parent*/
    fdm = fdopen(pim[1],"wb");					/*updating*/
    fde = fdopen(pie[1],"wb");
    if(fdm==NULL || fde==NULL) {
        return -1;
    }
    close(pim[0]);
    close(pie[0]);

    /*prepare to add date and message-id*/
    msgwhen = time(NULL);
    dt = gmtime((long *)&msgwhen);
    /*start outputting to qmail-queue
      date is in 822 format
      message-id could be computed a little better*/
    fprintf(fdm,"Date: %u %s %u %02u:%02u:%02u -0000\nMessage-ID: <%lu.%u.blah>\n"
            ,dt->tm_mday,montab[dt->tm_mon],dt->tm_year+1900,dt->tm_hour,dt->tm_min,dt->tm_sec,msgwhen,getpid() );

    mfp = fopen( msg, "rb" );

    while ( fgets( msg_buffer, sizeof(msg_buffer), mfp ) != NULL )
    {
        fprintf(fdm,"%s",msg_buffer);
    }

    fclose(mfp);

    fclose(fdm);


    /*send the envelopes*/

    fprintf(fde,"F%s",from);
    fwrite("",1,1,fde);					/*write a null char*/
    for(i=0; i<num_recipients; i++) {
        fprintf(fde,"T%s",recipients[i]);
        fwrite("",1,1,fde);					/*write a null char*/
    }
    fwrite("",1,1,fde);					/*write a null char*/
    fclose(fde);

    /*wait for qmail-queue to close*/
    do {
        r = wait(&wstat);
    } while ((r != pid) && ((r != -1) || (errno == EINTR)));
    if(r != pid) {
        /*failed while waiting for qmail-queue*/
        return -1;
    }
    if(wstat & 127) {
        /*failed while waiting for qmail-queue*/
        return -1;
    }
    /*the exit code*/

    if((wstat >> 8)!=0) {
        /*non-zero exit status
          failed while waiting for qmail-queue*/
        return -1;
    }
    return 0;
}
EXAMPLE #300
int
testAPI()
{
    struct logininfo *li1;
    struct passwd *pw;
    struct hostent *he;
    struct sockaddr_in sa_in4;
    char cmdstring[256], stripline[8];
    char username[32];
#ifdef HAVE_TIME_H
    time_t t0, t1, t2, logintime, logouttime;
    char s_t0[64],s_t1[64],s_t2[64];
    char s_logintime[64], s_logouttime[64]; /* ctime() strings */
#endif

    printf("**\n** Testing the API...\n**\n");

    pw = getpwuid(getuid());
    strlcpy(username, pw->pw_name, sizeof(username));

    /* gethostname(hostname, sizeof(hostname)); */

    printf("login_alloc_entry test (no host info):\n");

    /* FIXME fake tty more effectively - this could upset some platforms */
    li1 = login_alloc_entry((int)getpid(), username, NULL, ttyname(0));
    strlcpy(li1->progname, "OpenSSH-logintest", sizeof(li1->progname));

    if (be_verbose)
        dump_logininfo(li1, "li1");

    printf("Setting host address info for 'localhost' (may call out):\n");
    if (! (he = gethostbyname("localhost"))) {
        printf("Couldn't set hostname(lookup failed)\n");
    } else {
        /* NOTE: this is messy, but typically a program wouldn't have to set
         *  any of this, a sockaddr_in* would be already prepared */
        memcpy((void *)&(sa_in4.sin_addr), (void *)&(he->h_addr_list[0][0]),
               sizeof(struct in_addr));
        login_set_addr(li1, (struct sockaddr *) &sa_in4, sizeof(sa_in4));
        strlcpy(li1->hostname, "localhost", sizeof(li1->hostname));
    }
    if (be_verbose)
        dump_logininfo(li1, "li1");

    if ((int)geteuid() != 0) {
        printf("NOT RUNNING LOGIN TESTS - you are not root!\n");
        return 1;
    }

    if (nologtest)
        return 1;

    line_stripname(stripline, li1->line, sizeof(stripline));

    printf("Performing an invalid login attempt (no type field)\n--\n");
    login_write(li1);
    printf("--\n(Should have written errors to stderr)\n");

#ifdef HAVE_TIME_H
    (void)time(&t0);
    strlcpy(s_t0, ctime(&t0), sizeof(s_t0));
    t1 = login_get_lastlog_time(getuid());
    strlcpy(s_t1, ctime(&t1), sizeof(s_t1));
    printf("Before logging in:\n\tcurrent time is %d - %s\t"
           "lastlog time is %d - %s\n",
           (int)t0, s_t0, (int)t1, s_t1);
#endif

    printf("Performing a login on line %s ", stripline);
#ifdef HAVE_TIME_H
    (void)time(&logintime);
    strlcpy(s_logintime, ctime(&logintime), sizeof(s_logintime));
    printf("at %d - %s", (int)logintime, s_logintime);
#endif
    printf("--\n");
    login_login(li1);

    snprintf(cmdstring, sizeof(cmdstring), "who | grep '%s '",
             stripline);
    system(cmdstring);

    printf("--\nPausing for %d second(s)...\n", PAUSE_BEFORE_LOGOUT);
    sleep(PAUSE_BEFORE_LOGOUT);

    printf("Performing a logout ");
#ifdef HAVE_TIME_H
    (void)time(&logouttime);
    strlcpy(s_logouttime, ctime(&logouttime), sizeof(s_logouttime));
    printf("at %d - %s", (int)logouttime, s_logouttime);
#endif
    printf("\nThe root login shown above should be gone.\n"
           "If the root login hasn't gone, but another user on the same\n"
           "pty has, this is OK - we're hacking it here, and there\n"
           "shouldn't be two users on one pty in reality...\n"
           "-- ('who' output follows)\n");
    login_logout(li1);

    system(cmdstring);
    printf("-- ('who' output ends)\n");

#ifdef HAVE_TIME_H
    t2 = login_get_lastlog_time(getuid());
    strlcpy(s_t2, ctime(&t2), sizeof(s_t2));
    printf("After logging in, lastlog time is %d - %s\n", (int)t2, s_t2);
    if (t1 == t2)
        printf("The lastlog times before and after logging in are the "
               "same.\nThis indicates that lastlog is ** NOT WORKING "
               "CORRECTLY **\n");
    else if (t0 != t2)
        /* We can be off by a second or so, even when recording works fine.
         * I'm not 100% sure why, but it's true. */
        printf("** The login time and the lastlog time differ.\n"
               "** This indicates that lastlog is either recording the "
               "wrong time,\n** or retrieving the wrong entry.\n"
               "If it's off by less than %d second(s) "
               "run the test again.\n", PAUSE_BEFORE_LOGOUT);
    else
        printf("lastlog agrees with the login time. This is a good thing.\n");

#endif

    printf("--\nThe output of 'last' shown next should have "
           "an entry for root \n  on %s for the time shown above:\n--\n",
           stripline);
    snprintf(cmdstring, sizeof(cmdstring), "last | grep '%s ' | head -3",
             stripline);
    system(cmdstring);

    printf("--\nEnd of login test.\n");

    login_free_entry(li1);

    return 1;
} /* testAPI() */