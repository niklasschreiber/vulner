/**
 * Sockwatch Module Handler
 * If you use Sockwatch Module, this should run in the main loop
 * @ingroup sockwatch_module
 */
void sockwatch_run(void)
{
#define WCF_HANDLE(item_v, ret_v) \
do { \
	BITCLR(watch_sock[i], item_v); \
	watch_cb[i](i, item_v, ret_v); \
} while(0)

	uint8_t i;
	int32_t ret;

	S2E_Packet *value = get_S2E_Packet_pointer();
	MQTTPacket_connectData mqttConnectData = MQTTPacket_connectData_initializer;

	for(i=0; i<TOTAL_SOCK_NUM; i++) {
		if(watch_sock[i] == 0) continue;
		if(atci.mqtt_run == 1) {
			ret = MQTTYield(&mqttClient, mqttConnectData.keepAliveInterval);
#ifdef __ATC_MODE_MQTT_DEBUG__
			if(ret != SUCCESSS) {
				printf("MQTT yield error - ret : %d\r\n", ret);
			}
#endif
		}
		if(watch_sock[i] & WATCH_SOCK_RECV) {	// checked every time when 'connected' state
			getsockopt(i, SO_RECVBUF, (uint16_t*)&ret);
			if((uint16_t)ret > 0) WCF_HANDLE(WATCH_SOCK_RECV, RET_OK);
		}
		if(watch_sock[i] & WATCH_SOCK_CLS_EVT) {	// checked every time when 'connected' state
			getsockopt(i, SO_STATUS, (uint8_t*)&ret);
			switch((uint8_t)ret) {
			case SOCK_CLOSED:
				WCF_HANDLE(WATCH_SOCK_CLS_EVT, RET_OK);
				break;
			case SOCK_CLOSE_WAIT:
				disconnect(i);
				//close(i);
				break;
			default:
				break;
			}
		}
		if(watch_sock[i] & WATCH_SOCK_CONN_EVT) {	// checked every time when 'listen' state
			getsockopt(i, SO_STATUS, (uint8_t*)&ret);
			switch((uint8_t)ret) {
			case SOCK_ESTABLISHED:
				WCF_HANDLE(WATCH_SOCK_CONN_EVT, RET_OK);
				break;
			default:
				break;
			}
		}
		if((watch_sock[i] & WATCH_SOCK_MASK_LOW) == 0) continue;	// things which occurs occasionally will be checked all together
		if(watch_sock[i] & WATCH_SOCK_CLS_TRY) {
			getsockopt(i, SO_STATUS, (uint8_t*)&ret);
			switch((uint8_t)ret) {
			case SOCK_LISTEN:
				close(i);
			case SOCK_CLOSED:
				WCF_HANDLE(WATCH_SOCK_CLS_TRY, RET_OK);
				break;
			case SOCK_FIN_WAIT:
				close(i);	
				break;
			default:
				ctlsocket(i, CS_GET_INTERRUPT, (uint8_t*)&ret);
				if((uint8_t)ret & Sn_IR_TIMEOUT){
					//ctlsocket(i, CS_CLR_INTERRUPT, (uint8_t*)&ret);
					close(i);
					WCF_HANDLE(WATCH_SOCK_CLS_TRY, SOCKERR_TIMEOUT);
				}
				disconnect(i);
				//close(i);
				break;
			}
		}
		if(watch_sock[i] & WATCH_SOCK_CONN_TRY) {
			getsockopt(i, SO_STATUS, (uint8_t*)&ret);
			switch((uint8_t)ret) {
			case SOCK_ESTABLISHED:
				WCF_HANDLE(WATCH_SOCK_CONN_TRY, RET_OK);
				if(atci.mqtt_con == 1) {
					if(getSn_IR(i) & Sn_IR_CON) {
						setSn_IR(i,Sn_IR_CON);

						mqttConnectData.MQTTVersion			= 4;
						mqttConnectData.clientID.cstring 	= value->module_name;
						mqttConnectData.username.cstring 	= value->options.mqtt_user;
						mqttConnectData.password.cstring 	= value->options.mqtt_pw;
						mqttConnectData.willFlag 			= 0;
						mqttConnectData.keepAliveInterval   = 60;
						mqttConnectData.cleansession        = 1;

						ret = MQTTConnect(&mqttClient, &mqttConnectData);
#ifdef __ATC_MODE_MQTT_DEBUG__
						if(ret != SUCCESSS) {
							printf("MQTT connect error - ret : %d\r\n", ret);
						}
#endif
						atci.mqtt_con = 0;
						atci.mqtt_run = 1;
					}
				}
				break;
			default:
				ctlsocket(i, CS_GET_INTERRUPT, (uint8_t*)&ret);
				if((uint8_t)ret & Sn_IR_TIMEOUT){
					//ctlsocket(i, CS_CLR_INTERRUPT, (uint8_t*)&ret);
					close(i);
					WCF_HANDLE(WATCH_SOCK_CONN_TRY, SOCKERR_TIMEOUT);
				}
				break;
			}
		}
		if(watch_sock[i] & WATCH_SOCK_TCP_SEND) {
			// 블로킹 모드로만 동작함 그러므로 Watch할 필요가 없음
		}
		if(watch_sock[i] & WATCH_SOCK_UDP_SEND) {
			if(checkAtcUdpSendStatus < 0) {
				WCF_HANDLE(WATCH_SOCK_UDP_SEND, RET_NOK);
			}
			else {
				WCF_HANDLE(WATCH_SOCK_UDP_SEND, RET_OK);
			}
		}
	}

	// ToDo: not socket part
	
}

EXAMPLE #20
File: scanner.c Project: raymon-tian/sniffer_socket
//扫描指定ip的指定port
void do_scan(struct sockaddr_in *des_add){
	int sock_fd;
	int result;
	socklen_t len;
	struct hostent *hptr;

	//printf("%s\n",inet_ntoa(des_add->sin_addr));
	if((sock_fd = socket(AF_INET,SOCK_STREAM,0)) < 0){
		perror("error: socket\n");
		return;
	}
	//设置为非阻塞模式
	int flags = fcntl(sock_fd,F_GETFL,0);
	fcntl(sock_fd,F_SETFL,flags|O_NONBLOCK);
	//建立连接
	len = sizeof(*des_add);
	result = connect(sock_fd,(struct sockaddr*)des_add,len);
	if(result && errno != EINPROGRESS){
		close(sock_fd);
		return;
	}
	if(result == 0){
		//connect连接成功，恢复套接字阻塞状态
		fcntl(sock_fd,F_SETFL,flags);
		hptr = gethostbyaddr(&(des_add->sin_addr),4,AF_INET);
		printf("ip:%s\thostname:%s\tport:%d\n",inet_ntoa(des_add->sin_addr),hptr->h_name,ntohs(des_add->sin_port));
		close(sock_fd);
		return;
	}
	//连接失败，设置等待或者超时
	fd_set rd,wd,ed;
	FD_ZERO(&rd);
	FD_SET(sock_fd,&rd);
	wd = rd;
	ed = rd;
	int maxfd = sock_fd;
	struct timeval tv = {0,3000};
	int ret = select(maxfd+1,&rd,&wd,&ed,&tv);
	int val;
	if(ret <= 0){
		close(sock_fd);
		return;
	}else{
		if(!FD_ISSET(sock_fd,&rd)&&!FD_ISSET(sock_fd,&wd)){
			close(sock_fd);
			return;
		}
		if(getsockopt(sock_fd,SOL_SOCKET,SO_ERROR,&val,&len)<0){
			close(sock_fd);
			return;
		}
		if(val!=0){
			close(sock_fd);
			return;
		}
		//connect正确返回，恢复阻塞状态
		fcntl(sock_fd,F_SETFL,flags);
		hptr = gethostbyaddr(&(des_add->sin_addr),4,AF_INET);
		if(hptr == NULL)	printf("\t\t\t\t\tip:%s\thostname:unkown\tport:%d\n",inet_ntoa(des_add->sin_addr),ntohs(des_add->sin_port));
		else	printf("\t\t\t\t\tip:%s\thostname:%s\tport:%d\n",inet_ntoa(des_add->sin_addr),hptr->h_name,ntohs(des_add->sin_port));
		close(sock_fd);
	}
}

EXAMPLE #30
File: connection.c Project: blakawk/Aio4c
Connection* ConnectionInit(Connection* connection) {
    ErrorCode code = AIO4C_ERROR_CODE_INITIALIZER;

#ifndef AIO4C_WIN32
    if ((connection->socket = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
        code.error = errno;
#else /* AIO4C_WIN32 */
    if ((connection->socket = socket(PF_INET, SOCK_STREAM, 0)) == SOCKET_ERROR) {
        code.source = AIO4C_ERRNO_SOURCE_WSA;
#endif /* AIO4C_WIN32 */
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_SOCKET_ERROR, &code);
    }

#ifndef AIO4C_WIN32
    if (fcntl(connection->socket, F_SETFL, O_NONBLOCK) == -1) {
        code.error = errno;
#else /* AIO4C_WIN32 */
    unsigned long ioctl = 1;
    if (ioctlsocket(connection->socket, FIONBIO, &ioctl) == SOCKET_ERROR) {
        code.source = AIO4C_ERRNO_SOURCE_WSA;
#endif /* AIO4C_WIN32 */
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_FCNTL_ERROR, &code);
    }

    ConnectionState(connection, AIO4C_CONNECTION_STATE_INITIALIZED);

    return connection;
}

Connection* ConnectionConnect(Connection* connection) {
    ErrorCode code = AIO4C_ERROR_CODE_INITIALIZER;
    ConnectionState newState = AIO4C_CONNECTION_STATE_CONNECTING;

    if (connection->state != AIO4C_CONNECTION_STATE_INITIALIZED) {
        code.expected = AIO4C_CONNECTION_STATE_INITIALIZED;
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_DEBUG, AIO4C_CONNECTION_STATE_ERROR, &code);
    }

    if (connect(connection->socket, AddressGetAddr(connection->address), AddressGetAddrSize(connection->address)) == -1) {
#ifndef AIO4C_WIN32
        code.error = errno;
        if (errno == EINPROGRESS) {
#else /* AIO4C_WIN32 */
        int error = WSAGetLastError();
        code.source = AIO4C_ERRNO_SOURCE_WSA;
        if (error == WSAEINPROGRESS || error == WSAEALREADY || error == WSAEWOULDBLOCK) {
#endif /* AIO4C_WIN32 */
            newState = AIO4C_CONNECTION_STATE_CONNECTING;
        } else {
            return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_CONNECT_ERROR, &code);
        }
    } else {
        newState = AIO4C_CONNECTION_STATE_CONNECTED;
    }

    ConnectionState(connection, newState);

    return connection;
}

Connection* ConnectionFinishConnect(Connection* connection) {
    ErrorCode code = AIO4C_ERROR_CODE_INITIALIZER;
    int soError = 0;
    socklen_t soSize = sizeof(int);

#ifdef AIO4C_HAVE_POLL
    aio4c_poll_t polls[1] = { { .fd = connection->socket, .events = POLLOUT, .revents = 0 } };

#ifndef AIO4C_WIN32
    if (poll(polls, 1, -1) == -1) {
        code.error = errno;
#else /* AIO4C_WIN32 */
    if (WSAPoll(polls, 1, -1) == SOCKET_ERROR) {
        code.source = AIO4C_ERRNO_SOURCE_WSA;
#endif /* AIO4C_WIN32 */
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_POLL_ERROR, &code);
    }

    if (polls[0].revents > 0) {
#else /* AIO4C_HAVE_POLL */
    fd_set writeSet;
    fd_set errorSet;

    FD_ZERO(&writeSet);
    FD_ZERO(&errorSet);
    FD_SET(connection->socket, &writeSet);
    FD_SET(connection->socket, &errorSet);

#ifndef AIO4C_WIN32
    if (select(connection->socket + 1, NULL, &writeSet, &errorSet, NULL) == -1) {
        code.error = errno;
#else /* AIO4C_WIN32 */
    if (select(connection->socket + 1, NULL, &writeSet, &errorSet, NULL) == SOCKET_ERROR) {
        code.source = AIO4C_ERRNO_SOURCE_WSA;
#endif /* AIO4C_WIN32 */
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_SELECT_ERROR, &code);
    }

    if (FD_ISSET(connection->socket, &writeSet) || FD_ISSET(connection->socket, &errorSet)) {
#endif /* AIO4C_HAVE_POLL */

#ifndef AIO4C_WIN32
        if (getsockopt(connection->socket, SOL_SOCKET, SO_ERROR, &soError, &soSize) != 0) {
            code.error = errno;
#else /* AI4OC_WIN32 */
        if (getsockopt(connection->socket, SOL_SOCKET, SO_ERROR, (char*)&soError, &soSize) == SOCKET_ERROR) {
            code.source = AIO4C_ERRNO_SOURCE_WSA;
#endif /* AIO4C_WIN32 */
            return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_GETSOCKOPT_ERROR, &code);
        }

        if (soError != 0) {
#ifndef AIO4C_WIN32
            code.error = soError;
#else /* AIO4C_WIN32 */
            code.source = AIO4C_ERRNO_SOURCE_SOE;
            code.soError = soError;
#endif /* AIO4C_WIN32 */
            return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_FINISH_CONNECT_ERROR, &code);
        }
    }

    return connection;
}

Connection* ConnectionRead(Connection* connection) {
    Buffer* buffer = NULL;
    ssize_t nbRead = 0;
    ErrorCode code = AIO4C_ERROR_CODE_INITIALIZER;
    aio4c_byte_t* data = NULL;

    buffer = connection->readBuffer;

    if (!BufferHasRemaining(buffer)) {
        code.buffer = buffer;
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_BUFFER_OVERFLOW_ERROR, &code);
    }

    data = BufferGetBytes(buffer);
    if ((nbRead = recv(connection->socket, (void*)&data[BufferGetPosition(buffer)], BufferRemaining(buffer), 0)) < 0) {
#ifndef AIO4C_WIN32
        code.error = errno;
#else /* AIO4C_WIN32 */
        code.source = AIO4C_ERRNO_SOURCE_WSA;
#endif /* AIO4C_WIN32 */
        return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_ERROR, AIO4C_READ_ERROR, &code);
    }

    ProbeSize(AIO4C_PROBE_NETWORK_READ_SIZE, nbRead);

    if (nbRead == 0) {
        if (connection->state == AIO4C_CONNECTION_STATE_PENDING_CLOSE) {
            ConnectionState(connection, AIO4C_CONNECTION_STATE_CLOSED);
            return connection;
        } else {
            return _ConnectionHandleError(connection, AIO4C_LOG_LEVEL_INFO, AIO4C_CONNECTION_DISCONNECTED, &code);
        }
    }

    if (!connection->canRead) {
        Log(AIO4C_LOG_LEVEL_WARN, "received data on connection %s when reading is not allowed", connection->string);
        BufferReset(buffer);
        return connection;
    }

    BufferPosition(buffer, BufferGetPosition(buffer) + nbRead);

    _ConnectionEventHandle(connection, AIO4C_INBOUND_DATA_EVENT);

    return connection;
}