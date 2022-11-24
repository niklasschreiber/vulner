int main(int argc,char *argv[]) {
    int i;
    for (i=0; i<1024; ++i) {
        printf("%08x%c",arc4random(),(i&15)==15 ? '\n' : ' ');
    }
    perror("write");
#if 0
    int n;
    struct ucontext uc;
    n=0;
    getcontext(&uc);
    puts("getcontext returned");
    if (n==0) {
        ++n;
        setcontext(&uc);
        puts("should not get here");
        exit(1);
    }
    puts("all ok");
    return 0;
#endif
#if 0
    char* a=malloc(-3);
    char* b=malloc(0xffffffffull+1);
    printf("%p %p\n",a,b);
#endif
#if 0
    printf("%u\n",getpagesize());
#endif
#if 0
    struct stat s;
    time_t t=time(0);
    struct tm* T;
    stat("/tmp/nyt.html",&s);
    T=gmtime(&s.st_mtime);
#endif
#if 0
    static struct mq_attr x;
    mqd_t a=mq_open("fnord",O_WRONLY|O_CREAT,0600,&x);
    mqd_t b=mq_open("fnord",O_RDONLY);
#endif
#if 0
    struct statfs s;
    if (statfs("/tmp",&s)!=-1) {
        printf("%llu blocks, %llu free\n",(unsigned long long)s.f_blocks,(unsigned long long)s.f_bfree);
    }
#endif
#if 0
    char* c=strndupa("fnord",3);
    puts(c);
#endif
#if 0
    char buf[100];
    __write2("foo!\n");
    memset(buf,0,200);
#endif
#if 0
    printf("%+05d\n",500);
#endif
#if 0
    char* c;
    printf("%d\n",asprintf(&c,"foo %d",23));
    puts(c);
#endif
#if 0
    struct winsize ws;
    if (!ioctl(0, TIOCGWINSZ, &ws)) {
        printf("%dx%d\n",ws.ws_col,ws.ws_row);
    }
#endif
#if 0
    struct termios t;
    if (tcgetattr(1,&t)) {
        puts("tcgetattr failed!");
        return 1;
    }
    printf("%d\n",cfgetospeed(&t));
#endif
#if 0
    printf("%p\n",malloc(0));
#endif
#if 0
    char* argv[]= {"sh","-i",0};
    char buf[PATH_MAX+100];
    int i;
    for (i=0; i<PATH_MAX+20; ++i) buf[i]='a';
    memmove(buf,"PATH=/",6);
    strcpy(buf+i,"/bin:/bin");
    putenv(buf);
    execvp("sh",argv);
    printf("%d\n",islower(0xfc));
#endif
#if 0
    char buf[101];
    __dtostr(-123456789.456,buf,100,6,2);
    puts(buf);
    return 0;
#endif
#if 0
    time_t t=1009921588;
    puts(asctime(localtime(&t)));
#endif
#if 0
    printf("%g\n",atof("30"));
#endif
#if 0
    char* buf[]= {"FOO=FNORD","A=B","C=D","PATH=/usr/bin:/bin",0};
    environ=buf;
    putenv("FOO=BAR");
    putenv("FOO=BAZ");
    putenv("BLUB=DUH");
    system("printenv");
#endif
#if 0
    char buf[1024];
    time_t t1=time(0);
    struct tm* t=localtime(&t1);
    printf("%d %s\n",strftime(buf,sizeof buf,"%b %d %H:%M",t),buf);
#endif
#if 0
    tzset();
    printf("%d\n",daylight);
#endif
#if 0
    struct in_addr addr;
    inet_aton("10.0.0.100\t",&addr);
    printf("%s\n",inet_ntoa(addr));
#endif
#if 0
    printf("%u\n",getuid32());
#endif
#if 0
    FILE *f;
    int i;
    char addr6p[8][5];
    int plen, scope, dad_status, if_idx;
    char addr6[40], devname[20];
    if ((f = fopen("/proc/net/if_inet6", "r")) != NULL) {
        while ((i=fscanf(f, "%4s%4s%4s%4s%4s%4s%4s%4s %02x %02x %02x %02x %20s\n",
                         addr6p[0], addr6p[1], addr6p[2], addr6p[3],
                         addr6p[4], addr6p[5], addr6p[6], addr6p[7],
                         &if_idx, &plen, &scope, &dad_status, devname)) != EOF) {
            printf("i=%d\n",i);
        }
    }
#endif
#if 0
    printf("%s\n",crypt("test","$1$"));
#endif
#if 0
    MD5_CTX x;
    unsigned char md5[16];
    MD5Init(&x);
    MD5Update(&x,"a",1);
    MD5Final(md5,&x);
    {
        int i;
        for (i=0; i<16; ++i) {
            printf("x",md5[i]);
        }
        putchar('\n');
    }
#endif
#if 0
    long a,b,c;
    char buf[20]="fnord";
    strcpy(buf,"Fnordhausen");
    strcpy2(buf,"Fnordhausen");
    rdtscl(a);
    strcpy(buf,"Fnordhausen");
    rdtscl(b);
    strcpy2(buf,"Fnordhausen");
    rdtscl(c);
    printf("C: %d ticks, asm: %d ticks\n",b-a,c-b);
#endif

    /*  printf("%d\n",strcmp(buf,"fnord")); */
#if 0
    regex_t r;
//  printf("regcomp %d\n",regcomp(&r,"^(re([\\[0-9\\]+])*|aw):[ \t]*",REG_EXTENDED));
    printf("regcomp %d\n",regcomp(&r,"^([A-Za-z ]+>|[]>:|}-][]>:|}-]*)",REG_EXTENDED));
    printf("regexec %d\n",regexec(&r,"Marketing-Laufbahn hinterdir.",1,0,REG_NOSUB));
#endif
#if 0
    FILE *f=fopen("/home/leitner/Mail/outbox","r");
    char buf[1024];
    int i=0;
    if (f) {
        while (fgets(buf,1023,f)) {
            ++i;
            printf("%d %lu %s",i,ftell(f),buf);
        }
    }
#endif
#if 0
    char template[]="/tmp/duh/fnord-XXXXXX";