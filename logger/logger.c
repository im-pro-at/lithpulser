//--------------------------------------------------------------------------------
// Company: im-pro.at
// Engineer: Patrick Knöbel
//
//   GNU GENERAL PUBLIC LICENSE Version 3
//
//----------------------------------------------------------------------------------

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <stdint.h>
#include <sched.h>
#include <inttypes.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

#include <sys/select.h>
#include <termios.h>

#define FATAL do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", \
  __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)
 
#define BASE_ADRESS 0x40000000UL
#define MAP_SIZE 131072UL
#define MAP_MASK (MAP_SIZE - 1)

#define SYSTEM_VERSION 0x0BADA550UL


struct termios orig_termios;

void reset_terminal_mode()
{
    tcsetattr(0, TCSANOW, &orig_termios);
}

void set_conio_terminal_mode()
{
    struct termios new_termios;

    /* take two copies - one for now, one for later */
    tcgetattr(0, &orig_termios);
    memcpy(&new_termios, &orig_termios, sizeof(new_termios));

    /* register cleanup handler, and set the new terminal mode */
    atexit(reset_terminal_mode);
    cfmakeraw(&new_termios);
    tcsetattr(0, TCSANOW, &new_termios);
}

int kbhit()
{
    struct timeval tv = { 0L, 0L };
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(0, &fds);
    return select(1, &fds, NULL, NULL, &tv);
}

void* map_base = (void*)(-1);

uint32_t read_value(uint32_t a_addr) {
	volatile void* virt_addr = map_base + (a_addr & MAP_MASK);
	uint32_t read_result = 0;
	read_result = *((uint32_t *) virt_addr);
	return read_result;
}

int hasnext(int take){
  static int last=0;
  int r=0;
  if(last){
    r=last;    
  }
  else{
    r=read_value(0x038);    
  }
  if(take){
    last = 0;    
  }
  else{
    last=r;
  }
  return r;
}

int exists(const char *fname)
{
    FILE *file;
    if ((file = fopen(fname, "r")))
    {
      fclose(file);
      return 1;
    }
    return 0;
}

int main(int argc, char **argv) {
	int fd = -1;
  struct stat st = {0};
  FILE *wf; 
  
  if (stat("./runs", &st) == -1) {
    mkdir("./runs", 0777);
  }
  
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) FATAL;

	/* Map one page */
	map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, BASE_ADRESS & ~MAP_MASK);
	if(map_base == (void *) -1) FATAL;
  
  if(read_value(0x000)!=SYSTEM_VERSION){
    printf("FPGA Designe not loaded! Loading fpga.bin ...\n");
    if(!exists("fpga.bin")) FATAL;
    system("cat fpga.bin >/dev/xdevcfg");
    printf("Check if loaded:\n");
    if(read_value(0x000)!=SYSTEM_VERSION) FATAL;
    printf("DONE!\n");
  }

  while (1){
    printf("Wait for RUN...(exit with ENTER)\n");
    while (read_value(0x004)==0 && hasnext(0)==0){
      sched_yield(); 
      if (kbhit()){ 
        //EXIT Application
        if (map_base != (void*)(-1)) {
          if(munmap(map_base, MAP_SIZE) == -1) FATAL;
          map_base = (void*)(-1);
        }

        if (map_base != (void*)(-1)) {
          if(munmap(map_base, MAP_SIZE) == -1) FATAL;
        }
        if (fd != -1) {
          close(fd);
        }

        return EXIT_SUCCESS;
      }
    }

    char fnamebin[100];
    time_t now = time(NULL);
    struct tm *t = localtime(&now);

    strftime(fnamebin, sizeof(fnamebin)-1, "./runs/%Y_%m_%d_%H%M%S.bin", t);
    printf("logging to %s\n", fnamebin);
    wf = fopen(fnamebin,"wb");
    
    uint64_t buffer[10000];
    uint16_t c=0;
    long gc=0;
    long lgc=0;

    while (read_value(0x004)==1 || hasnext(0)==1){ //While running or fifo has data
      //Buffer Data
      while (hasnext(1)==1){ //While FIFO not empty
        buffer[c]= read_value(0x030);
        buffer[c]= buffer[c] | (uint64_t)read_value(0x034)<<32; 
        c++;
        if(c==10000) break;
      }    
      //Write Data to File
      if(c!=0){
        fwrite(buffer,sizeof(uint64_t), c,wf);
        gc+=c;
        if(gc>lgc+10000){
          lgc=gc;
          printf("Events written %lu ...\n",gc);
        }
        c=0;
      }
      
      sched_yield();
    }
    fclose(wf);
    printf("Events written %lu\n",gc);

    char fnamedump[100];
    strftime(fnamedump, sizeof(fnamedump)-1, "./runs/%Y_%m_%d_%H%M%S.txt", t);
    printf("Counts to %s\n", fnamedump);
    wf = fopen(fnamedump,"wb");
    for(int i=0;i<16;i++){
      printf("Sequence %i executed: %"PRIu32" \n",i,read_value(0x10010+i*0x1000));
      fprintf(wf,"Sequence %i executed: %"PRIu32" \n",i,read_value(0x10010+i*0x1000)); 
    }
    if(read_value(0x03C)==1){
      printf("\n\nWARNING! OVERRUN you have lost LOG DATA!!!!!!\n");
      fprintf(wf,"\n\nWARNING! OVERRUN you have lost LOG DATA!!!!!!\n");
    }    
    fclose(wf);    
    printf("DONE!\n");

  }
}



