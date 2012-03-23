/*
 Copyright (C) 2002 M. Marques, A. Castro, A. Rubio, G. Bertsch

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2, or (at your option)
 any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.

 $Id: varia.c 6722 2010-06-13 12:44:43Z acastro $
*/

#include <stdlib.h>
#include <math.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <termios.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <string.h>

#include <config.h>
#include "varia.h"


/* Gets the name of the machine */
void sysname(char **c)
{
  struct utsname name;
  uname(&name);
  *c = (char *)malloc(sizeof(name.nodename) + sizeof(name.sysname) + 4);
  strcpy(*c, name.nodename);
  strcat(*c, " (");
  strcat(*c, name.sysname);
  strcat(*c, ")");
}


/* optimizes the order of the fft
	 p is the maximum prime allowed in n */
void fft_optimize(int *n, int p, int par)
{
  if(*n <= 2) return;

  for(;; (*n)++){
    int i, n2;

    if((par > 0) && (*n % 2 != par)) continue;
    
    n2 = *n;
    for(i = 2; i<=n2; i++){
      if(n2 % i == 0){
	if(i > p) break;
	n2 = n2 / i; 
	i--; 
      }
    }
    if(i > n2) return;
  }
}

/* returns true if process is in the foreground
	 copied from openssh scp source */
static int foreground_proc(void)
{
  static pid_t pgrp = -1;
  int ctty_pgrp;
  
  if (pgrp == -1)
    pgrp = getpgrp();
  
#ifdef HAVE_TCGETPGRP
  return ((ctty_pgrp = tcgetpgrp(STDOUT_FILENO)) != -1 &&
	  ctty_pgrp == pgrp);
#else
  return ((ioctl(STDOUT_FILENO, TIOCGPGRP, &ctty_pgrp) != -1 &&
	   ctty_pgrp == pgrp));
#endif
}

int getttywidth(void)
{
  struct winsize winsize;
  
  if (ioctl(fileno(stdout), TIOCGWINSZ, &winsize) != -1)
    return (winsize.ws_col ? winsize.ws_col : 80);
  else
    return (80);
}

/* displays progress bar with a percentage */
void progress_bar(int actual, int max)
{
  static struct timeval start;
  static int old_pos, next_print;
  struct timeval now;
  char buf[512], fmt[64];
  int i, j, ratio, barlength, remaining;
  double elapsed;
  
  if(actual < 0) {
    (void) gettimeofday(&start, (struct timezone *) 0);
    actual  = 0;
    old_pos = 0;
    next_print = 10;
  }

  if(max > 0){
    ratio = 100 * actual / max;
    if(ratio < 0)   ratio = 0;
    if(ratio > 100) ratio = 100;
  }else
    ratio = 100;

  if(foreground_proc() == 0){
    if(old_pos == 0){
      printf("ETA: ");
    }

    barlength = getttywidth() - 6;

    j = actual*(barlength - 1)/max;
    if(j > barlength || actual == max) j = barlength;
    if(j < 1) j = 1;

    if(j > old_pos){
      for(i=old_pos+1; i<=j; i++)
	if(i*100/barlength >= next_print){
	  printf("%1d", next_print/10 % 10);
	  next_print += 10;
	}else
	  printf(".");
      old_pos = j;
      if(j == barlength) printf("\n");
    }

  }else{

    sprintf(buf, "%d", max);
    i = strlen(buf);
    if(i<3) i=3;
    sprintf(fmt, "\r[%%%dd/%%%dd]", i, i);
    sprintf(buf, fmt, actual, max);
    sprintf(buf + strlen(buf), " %3d%%" , ratio);
    
    barlength = getttywidth() - strlen(buf) - 16;
    if (barlength > 0) {
      i = barlength * ratio / 100;
      sprintf(buf + strlen(buf),
	      "|%.*s%*s|", i,
	      "*******************************************************"
	      "*******************************************************"
	      "*******************************************************"
	      "*******************************************************"
	      "*******************************************************"
	      "*******************************************************"
	      "*******************************************************",
	      barlength - i, "");
    }
    
    /* time information now */
    (void) gettimeofday(&now, (struct timezone *) 0);
    elapsed = now.tv_sec - start.tv_sec;
  
    if(elapsed <= 0.0 || actual <= 0) {
      sprintf(buf + strlen(buf),
	      "     --:-- ETA");
    }else{
      remaining = (int)(max / (actual / elapsed) - elapsed);
      if(remaining < 0) remaining = 0;
    
      i = remaining / 3600;
      if(i)
	sprintf(buf + strlen(buf), "%4d:", i);
      else
	sprintf(buf + strlen(buf), "     ");
      i = remaining % 3600;
      sprintf(buf + strlen(buf), "%02d:%02d%s", i / 60, i % 60, " ETA");
    }
    printf("%s", buf);

  }
  
  fflush(stdout);
}

#undef timersub
