#include <stdio.h>
#include <sys/mman.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#define LENGTH (2UL*1024*1024)
#define FILE_NAME "/dev/hugepages/hugepagefile"
static void write_bytes(char *addr)
{
        unsigned long i;

        for (i = 0; i < LENGTH; i++)
                *(addr + i) = (char)i;
}
int main ()
{
   void *addr;
   int i;
   char buf[32];
   int fd;

   for (i = 0 ; i < 16 ; i++ ) {
           sprintf(buf, "%s_%d", FILE_NAME, i);
           fd = open(buf, O_CREAT | O_RDWR, 0755);
           addr = mmap((void *)(0x0UL), LENGTH, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_HUGETLB , fd, 0);

           printf("address returned %p \n", addr);

           if (addr == MAP_FAILED) {
                   perror("mmap ");
           } else {
                write_bytes(addr);
                //munmap(addr, LENGTH);
                //unlink(FILE_NAME);
           }
           close(fd);
   }
   while (1){}
   return 0;
}