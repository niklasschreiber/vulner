void
myEpoll::loop()
{
    if(!handler) {
        perror("loop: do_use_fd no defined");
    }
    for (;;) {
        nfds = Epoll_wait(epollfd, events, MAX_EVENTS, -1);
        int n;
        for (n = 0; n < nfds; ++n) {
            if (events[n].data.fd == listen_sock) {

                conn_sock = sock.Accept(listen_sock);

                std::cout << "new client: " << sock.Sock_ntop() << std::endl;

                sock.setnonblocking(conn_sock);
                write(conn_sock, hello, strlen(hello) ); //!!aghtung send helloworld!!

                //		do_use_fd(conn_sock); //! ololo del

                ev.events = EPOLLIN | EPOLLET;
                ev.data.fd = conn_sock;

                if( Epoll_ctl(epollfd, EPOLL_CTL_ADD, conn_sock, &ev) < 0) {
                    perror("loop: Epoll_ctl");
                }

            } else {
                // by analogy with True branch, epoll ok
                printf("READY\n");
                //! do use fd
                (*handler) (events[n].data.fd);
                // FIXME да, звать прикладную логику через хендлер - очень хорошее решение.
                // Примерно то, что делает Boost::asio и, может быть, libevent
                // Хотя... Не всегда это нужно...
                // Суть в том, что для маленьких проектов важна скорость разработки без
                // потери качества (легкости, надежности и производительности) кода.
                // Такие же generic-решения хороши для намного больших проектов.
                // Предугадываться же какие части будут использоватсья в другом проекти
                // или расширяться в существующем - это не всегда тревиальный вопрос.
            }
        }
    }
}