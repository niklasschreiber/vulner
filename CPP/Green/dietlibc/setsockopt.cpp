void *Switch_Control::TCP_Accept_Control_thread(void *arg)
{

	Switch_Control *this0 = (Switch_Control*)arg;

	int BUFFER_SIZE = 4096;
	struct sockaddr_in s_addr;
	int sock;
	socklen_t addr_len;


	if ( (sock = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))  == -1) {
		perror("socket");
		fflush(stderr);
		LOG_ERROR("ERROR  SWM : Create Socket ERROR \n");
		return NULL;
	} else
		printf("create socket.\n\r");
	fflush(stdout);

	memset(&s_addr, 0, sizeof(struct sockaddr_in));
	s_addr.sin_family = AF_INET;

	s_addr.sin_port = htons(this0->m_iMsiPort);


	s_addr.sin_addr.s_addr = inet_addr(this0->SW_ip.c_str());//INADDR_ANY;

	int optval = 1;
	if ((setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,&optval,sizeof(int))) == -1)
	{
		close(sock);
		LOG_ERROR("ERROR  SWM : Set Socket ReUSED ERROR \n");
		return NULL;
	}

	if ( (bind(sock, (struct sockaddr*)&s_addr, sizeof(s_addr))) == -1 ) {
		perror("bind");
		fflush(stderr);
		LOG_ERROR("ERROR  SWM : Bind Socket ERROR \n");
		return NULL;
	}else
		printf("bind address to socket.\n\r");
	fflush(stdout);

	if(listen(sock,10)<0)
	{
		perror("listen");
		fflush(stderr);
		LOG_ERROR("ERROR  SWM : Listen Socket ERROR \n");
		return NULL;
	}

	int accept_fd = -1;
	struct sockaddr_in remote_addr;
	memset(&remote_addr,0,sizeof(remote_addr));

	this0->m_MsiacceptSocket = -1;
	
	while( 1 )
	{  
		
	    socklen_t sin_size = sizeof(struct sockaddr_in); 
		if(( accept_fd = accept(sock,(struct sockaddr*) &remote_addr,&sin_size)) == -1 )  
         {  
             	printf( "Accept error!\n");  
				fflush(stdout);
                //continue;  
	     }  
         printf("Received a connection from %s\n",(char*) inet_ntoa(remote_addr.sin_addr));  

		fflush(stdout);

		if(this0->m_MsiacceptSocket != -1)
		{
			//需要释放之前的链接
		}
		this0->m_MsiacceptSocket = accept_fd;

		//将socket加入队列
		pthread_mutex_lock(&this0->m_lockerQuesocket);
		this0->m_QueSokcet.push(accept_fd);
		pthread_mutex_unlock(&this0->m_lockerQuesocket);
		
		pthread_t tcp_recv_thread1;
		pthread_create(&tcp_recv_thread1, NULL, Parse_recv_MSI_thread, this0);
		pthread_detach(tcp_recv_thread1);
		

	}


}