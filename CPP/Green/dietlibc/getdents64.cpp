//XXX:carefull, the dentry type is not supported by all fs
static void dir_parse(i parent_fd)
{
  ++depth;
  u8 dirents[DIRENTS_BUF_SZ];
  while(1){
    l r=getdents64(parent_fd,dirents,DIRENTS_BUF_SZ);
    if(ISERR(r)){
      PERR("ERROR(%ld):getdents error\n",r);
      exit(-1);
    }
    if(!r) break;
    l j=0;
    while(j<r){
      struct dirent64 *d=(struct dirent64*)(dirents+j);

      dout(d);

      if(d->type==DT_DIR&&!is_current(d->name)&&!is_parent(d->name)){
        i dir_fd;
        do
          dir_fd=(i)openat(parent_fd,d->name,RDONLY|NONBLOCK);
        while(dir_fd==-EINTR);
        if(ISERR(dir_fd))
          PERR("ERROR(%d):unable to open subdir:%s\n",dir_fd,d->name);
        else{
          dir_parse(dir_fd);
          l r1;
          do r1=close(dir_fd); while(r1==-EINTR);
        }
      }
      j+=d->rec_len;
    }
  }
  depth--;
}