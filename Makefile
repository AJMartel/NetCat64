# Project: NetCat64

CPP     = g++.exe
CC      = gcc.exe
WINDRES = windres.exe
RM      = rm -f

BIN     = nc64.exe
RES     = NetCat64_private.res
OBJ     = netcat64.o doexec.o $(RES)
LINKOBJ = netcat64.o doexec.o $(RES)
LIBS    = -lkernel32 -luser32 -lwinmm -lws2_32 -liphlpapi -s 

CXXINCS  = 
INCS     = 
CXXFLAGS = $(CXXINCS) -Wall -fexpensive-optimizations -O3 -DWIN32 -DNDEBUG -D_CONSOLE -DTELNET -DGAPING_SECURITY_HOLE -DSSODEBUG -DSSOTTL -DSSOBC -DCRLF -DMULTICAST -DIPv6SSM -DFIXINVALCONN -DFIXRELISTENHOST -DURGPTR -DSSOKEEPALIVE 
CFLAGS   = $(INCS) -Wall -fexpensive-optimizations -O3 -DWIN32 -DNDEBUG -D_CONSOLE -DTELNET -DGAPING_SECURITY_HOLE -DSSODEBUG -DSSOTTL -DSSOBC -DCRLF -DMULTICAST -DIPv6SSM -DFIXINVALCONN -DFIXRELISTENHOST -DURGPTR -DSSOKEEPALIVE 

all: nc64.exe

.PHONY: all clean

clean:
	$(RM) $(OBJ) $(BIN) netcat.layout

$(BIN): $(OBJ)
	$(CC) $(LINKOBJ) -o "nc64.exe" $(LIBS)

netcat64.o: netcat64.c
	$(CC) -c netcat64.c -o netcat64.o $(CFLAGS)

doexec.o: doexec.c
	$(CC) -c doexec.c -o doexec.o $(CFLAGS)

NetCat64_private.res: NetCat64_private.rc 
	$(WINDRES) -i NetCat64_private.rc --input-format=rc -o NetCat64_private.res -O coff
