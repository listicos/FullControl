//
//  Arp.c
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 13/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

#include "Arp.h"
#include <sys/param.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#include <net/if.h>
#include <net/if_dl.h>

//#include <net/if_types.h>

#include <net/route.h>

#include <netinet/in.h>
#include <netinet/if_ether.h>

#include <arpa/inet.h>

#include <err.h>
#include <errno.h>
#include <netdb.h>
#include <nlist.h>
#include <paths.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define IFT_ETHER   0x6

static int nflag;

void
ether_print(cp)
u_char *cp;
{
    printf("%x:%x:%x:%x:%x:%x", cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]);
}


/*
 * Dump the entire arp table
 */
int
dump(addr)
u_long addr;
{
    int mib[6];
    size_t needed;
    char *host, *lim, *buf, *next;
    struct rt_msghdr *rtm;
    struct sockaddr_inarp *sin;
    struct sockaddr_dl *sdl;
    extern int h_errno;
    struct hostent *hp;
    int found_entry = 0;
    
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET;
    mib[4] = NET_RT_FLAGS;
    mib[5] = RTF_LLINFO;
    if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0)
        err(1, "route-sysctl-estimate");
    if ((buf = malloc(needed)) == NULL)
        err(1, "malloc");
    if (sysctl(mib, 6, buf, &needed, NULL, 0) < 0)
        err(1, "actual retrieval of routing table");
    lim = buf + needed;
    for (next = buf; next < lim; next += rtm->rtm_msglen) {
        rtm = (struct rt_msghdr *)next;
        sin = (struct sockaddr_inarp *)(rtm + 1);
        sdl = (struct sockaddr_dl *)(sin + 1);
        if (addr) {
            if (addr != sin->sin_addr.s_addr)
                continue;
            found_entry = 1;
        }
        if (nflag == 0)
            hp = gethostbyaddr((caddr_t)&(sin->sin_addr),
                               sizeof sin->sin_addr, AF_INET);
        else
            hp = 0;
        if (hp)
            host = hp->h_name;
        else {
            host = "?";
            if (h_errno == TRY_AGAIN)
                nflag = 1;
        }
        printf("%s (%s) at ", host, inet_ntoa(sin->sin_addr));
        if (sdl->sdl_alen)
            ether_print((u_char *)LLADDR(sdl));
        else
            printf("(incomplete)");
        if (rtm->rtm_rmx.rmx_expire == 0)
            printf(" permanent");
        if (sin->sin_other & SIN_PROXY)
            printf(" published (proxy only)");
        if (rtm->rtm_addrs & RTA_NETMASK) {
            sin = (struct sockaddr_inarp *)
            (sdl->sdl_len + (char *)sdl);
            if (sin->sin_addr.s_addr == 0xffffffff)
                printf(" published");
            if (sin->sin_len != 8)
                printf("(weird)");
        }
        printf("\n");
    }
    return (found_entry);
}

int main (int argc, char const *argv[])
{
    dump(0);
    return 0;
}