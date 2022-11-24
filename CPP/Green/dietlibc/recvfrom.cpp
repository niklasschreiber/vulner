static int output_sendto (int sock, const void *frame, int frame_size,
		struct sockaddr_in *addr)
{
	struct frame_info {
		int8_t 	mask[2];	// 'FM' const
		int32_t	len;	//
		int8_t	data[UDPDATA_MAX_SIZE];
	}__attribute__((__packed__));

	struct frame_info fm;
	fm.mask[0] = 'F';
	fm.mask[1] = 'M';
	fm.len = 0;

	unsigned char *p = NULL;
    p = (unsigned char *)frame;
    while(frame_size > 0) {
		static int cnt = 0;
    	if(frame_size < UDPDATA_MAX_SIZE)
    		fm.len = frame_size;
    	else
    		fm.len = UDPDATA_MAX_SIZE;

    	memcpy(fm.data, p, fm.len);
    	int i;
    	for(i = 0; i < 5; i++){
    		sendto(sock, &fm, sizeof(fm), 0, (struct sockaddr*)addr, sizeof(struct sockaddr_in));

    		char answer[128];
    		int len;
    		int ret;
    		fd_set input;
    		struct timeval timeout;
    		FD_ZERO(&input);
    		FD_SET(sock, &input);

    		timeout.tv_sec = 0;
    		timeout.tv_usec = 5000;
    		ret = select(sock + 1, &input, NULL, NULL, &timeout);
    		if (ret < 0) {
    			perror("select");
    			break;
    		} else if (ret == 0) {
				if(cnt == 0)
					printf("ERROR: no recv\n");
    			printf("%d\r", cnt++);
				fflush(stdout);
    		} else {
    			if (FD_ISSET(sock, &input)) {
					cnt = 0;
    	    		len = recvfrom(sock, answer, sizeof(answer), 0, NULL, 0);
    	    		if(len > 0)
    	    			if(strncmp(answer, "OK", 2) == 0)
    	    				break;
    			}
    		}

    	}
    	frame_size-=fm.len;
    	p += fm.len;
    }
    p = NULL;

    return 0;
}