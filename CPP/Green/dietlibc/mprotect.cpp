void MemoryMappedFile::_unlock() {
     if (! views.empty() ) assert(mprotect(views[0], len, PROT_READ) == 0);
 }