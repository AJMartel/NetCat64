netcat64 - v1.11.6.4 NT


SUMMARY:

This is a combination of:
    Netcat 1.11 NT (nc111nt.zip) from Weld Pond <weld@vulnwatch.org>
    Netcat6 (nc6_src.zip) from Sphinx Software [based on 1.10 NT]
    Various options available on the Unix versions of Netcat
    A few fixes
    Additional options

  nc64.exe     - netcat with IPv6 and IPv4 (compiled as 64-bit)
  nc64-32.exe  - netcat with IPv6 and IPv4 (compiled as 32-bit)


BACKGROUND:

The goal was to get a netcat that did *both* IPv4 and IPv6.  Netcat 
handles IPv4 nicely and the netcat6 port mentioned above does only 
IPv6 as well as the original handles IPv4.  There needed to be an 
IPv4 *and* IPv6 version of netcat.

Nmap.org publishes a utility - ncat - which is netcat updated and does 
both IPv4 and IPv6, but the -e GAPING_SECURITY_HOLE option is implemented 
by launching a "cmd.exe" shell with the /c option.  This has the effect 
of launching a Command Prompt on the machine where Netcat is running 
with the -e option.  So much for stealth.

The doexec.c included with the Windows versions of netcat listed above 
does well to mitigate this and so building IPv4 *and* IPv6 on the 
'original' code is more desirable than using the ncat utility - although 
ncat certainly remains very useful and incorporates additional features.


FIXES:

While some of these aren't really fixes - like adding "UDP" or "TCP" to 
the verbose output in listen mode - some do address issues seen in the 
original netcat this was compiled from.

Invalid Connections:
  When specifying a hostname in listen mode, netcat will attempt to 
  validate the connecting host matches the hostname [optional port] 
  provided.  If it does not, the connection is terminated with an 
  "invalid connection ..." error.  If using -L (or -k in this version) 
  to keep connections open, the entire program is terminated, even 
  though the -L (keep open) option is specified.  This fix simply 
  drops the connection and keeps netcat open for business.  Note, if 
  only using -l (do *not* keep open), invalid connections will cause 
  program termination as usual.

  This option can be conditionally compiled by adding -DFIXINVALCONN


Re-listen Argument Fix:
  When re-listening (-L or -k), netcat cycles through the getopt() 
  section again.  This has the effect of incrementing optind - the pointer 
  to the current option index.  This doesn't matter if there are no 
  arguments, but if a listener and port are specified in listen context:

    nc -Lp 5001 10.10.10.1 50000

  (This will only allow host 10.10.10.1 from port 50000 to connect.)
  When the first connection is dropped (or indeed if the first connection 
  is invalid and the above fix is applied), the next cycle through to 
  start listening increments optind so the hostname is no longer pointing 
  to 10.10.10.1; instead, it's pointing to 50000.  Netcat has trouble with 
  the reverse lookup (if in verbose mode) and subsequent connections will 
  fail as the host cannot possibly match 50000 - or whatever IP address 
  that converts to.  In some cases, netcat crashes - even observed in the 
  original netcat.  The solution is to conditionally pre-decrement optind 
  before getopt() is called if and only if listen mode is selected *and* 
  a remote address (like 10.10.10.1 in the above example) is specified.

  This option can be conditionally compiled by adding -DFIXRELISTENHOST


ADDITIONAL FEATURES:

Some of the additional features in this version can be conditionally 
compiled with -D<DEFINE> compiler directives.  Below describes the 
features and provides the define statements required.  Note that the 
included Makefile compiles *ALL* the following features by default.  In
addition to all the original features and usages mentioned in the 
readme.txt, the additions brought by this netcat64 are:

IPv4 and IPv6:
        -4              force IPv4 only
        -6              force IPv6 only

  IPv6 is preferred as the new get*info() lookup routines return IPv6 
  addresses first.  The gethostpoop() routine was completely rewritten 
  to accommodate both IPv4 and IPv6 and determine which to use if both 
  are found.  These switches force IPv4 or IPv6 only and will cause an 
  error if the proper address family is not found.


Broadcast:
        -b              disable bi-directional UDP (cli->srv only)
                          also sets SO_BROADCAST option if UDPv4

  When listening, netcat will connect() to the source to allow 
  bi-directional UDP communications (client<->server), "which also has 
  the side effect that now anything from a different source or even a 
  different port on the other end won't show up and will cause ICMP 
  errors" [original netcat*.c comments].  Since listening to broadcast 
  messages doesn't make sense from a single host the -b option bypasses 
  the connect().  This allows multiple reconnects from the same or 
  different clients to the server, but has the side effect of not allowing 
  the listening netcat to send data back to the source.  One way UDP 
  communications (client->server) only.

  Additionally, this option enables the setsockopt() SO_BROADCAST option 
  on the socket if netcat is operating in IPv4 mode.

  This option can be conditionally compiled by adding -DSSOBC


Carriage Return / Line Feed:
        -C              send CRLF as line-ending

  An option on Unix versions of netcat, this is the default on the Windows 
  version.  Compiling in this feature switches the default line ending 
  from "\n" to "\x0a".  Enabling this switch sends "\x0d\x0a" as the line 
  ending.

  This option can be conditionally compiled by adding -DCRLF


Debug:
        -D              set SO_DEBUG option

  An option on Unix versions of netcat, this doesn't seem to do anything 
  for the Windows version.  Additionally, from MSDN:  "Microsoft providers 
  currently do not output any debug information."

  This option can be conditionally compiled by adding -DSSODEBUG


Multicast:
        -j group        join multicast group and listen [UDP only] (-lu)
                          use [hostname] for specific source [v4 only]

  While Windows allowed sending to multicast groups over UDP, listening 
  was not so easy.  This option allows a listening netcat to 'join' the 
  provided multicast group and listen on UDP.  The default multicast 
  interface is used for listening.  This is usually the same as the 
  default multicast sending interface, found with the 'route print' 
  command and the interface with the lowest metric for the multicast 
  route is the 'winner'.  The listening (as well as sending) interface 
  can be changed with the standard netcat -s option.  Also, source 
  specific multicast can be specified by providing a hostname in the 
  netcat listener context.

  Additionally, as with broadcast described above, the -j switch will 
  not issue the connect() allowing multicast from several sources (if 
  not locked down by issuing a hostname in listen context) but not 
  allowing the multicast listening netcat to send data back.

  Examples (note -vv for verbose is *not* needed, only here to show 
            feedback):
    IPv4
    --
    Join 239.192.1.1 on UDP port 5001:
      C:\> nc64 -vv -j 239.192.1.1 -p 5001
      listening on [0.0.0.0] 5001 (UDP) ... {*,239.192.1.1}

    Send to the above listening netcat:
      C:\> nc64 -u 239.192.1.1 5001

    --
    To specify a default interface to listen on:
      C:\> nc64 -vv -j 239.192.1.1 -p 5001 -s 192.168.10.100
      listening on [192.168.10.100] 5001 (UDP) ... {*,239.192.1.1}

    To specify a default interface to send from:
      C:\> nc64 -u 239.192.1.1 5001 -s 192.168.10.100

    --
    To specify a specific multicast source:
      C:\> nc64 -vv -j 239.192.1.1 -p 5001 192.168.10.100
      listening on [0.0.0.0] 5001 (UDP) ... {192.168.10.100,239.192.1.1}

    --
    IPv6
    --
    Join ff05::1:2:3 on UDP port 5001:
      C:\> nc64 -vv -j ff05::1:2:3 -p 5001
      listening on [::] 5001 (UDP) ... {*,ff05::1:2:3}

    Send to the above listening netcat:
      C:\> nc64 -u ff05::1:2:3 5001

    --
    To specify a default interface to listen on:
      C:\> nc64 -vv -j ff05::1:2:3 -p 5001 -s 2001:db8::1
      listening on [2001:db8::1] 5001 (UDP) ... {*,ff05::1:2:3}

    To specify a default interface to send from:
      C:\> nc64 -u ff05::1:2:3 5001 -s 2001:db8::1

  This option can be conditionally compiled by adding -DMULTICAST

  NOTE:  Windows does not provide the ipv6_mreq_source structure or 
         the setsockopt() IPV6_ADD_SOURCE_MEMBERSHIP call.  Instead, 
         multicast is implemented with new structures GROUP_REQ and 
         GROUP_SOURCE_REQ, the latter of which addresses source 
         specific joins.  Furthermore, these structures and associated 
         calls are only available on Windows Vista or Server 2008 
         minimum - the documentation is confusing.

  To try to compile IPv6 source specific multicast, Windows Vista or 
  later is required and can be conditionally compiled by adding -DIPv6SSM


Keep Open:
        -k              keep inbound sockets open for multiple connects

  This option is available on Unix versions of netcat and included now 
  for compatibility.  -k requires -l and has the same effect as just 
  using -L on the Windows version.  -L remains for compatibility also.


Keepalive:
        -K secs         set SO_KEEPALIVE interval [TCP only]

  This enables the SO_KEEPALIVE socket option and sets the keepalive 
  interval to the 'secs' provided.  1<=secs<=7200

  This option can be conditionally compiled by adding -DSSOKEEPALIVE

  
Time To Live:
        -T ttl          v4: time to live / v6: hop limit (0<=ttl<=255)

  This enables the setsockopt() IP_TTL and IPV6_UNICAST_HOPS calls to 
  set the time to live (v4) and hop limit (v6).
  Additionally, if multicast is enabled, the IP_MULTICAST_TTL and 
  IPV6_MULTICAST_HOPS are also set / controlled with this option when 
  sending / receiving in multicast context.

  NOTE:  This does conflict with -T being used for Type of Service byte 
         manipulation on certain Unix versions of netcat.  Windows no 
         longer supports setsockopt() IP_TOS (as of Windows XP) or 
         implements an equivalent for the Traffic Class byte in IPv6 
         headers.  Several bloated APIs have come and gone to address 
         QoS in Windows and now manipulation of the ToS or TC bytes 
         seems all but impossible by end-user applications.  For the 
         current Windows 7 API, search for "QoS2 API, qos2.h, qWAVE".

  This option can be conditionally compiled by adding -DSSOTTL

  
Urgent Pointer:
        -U              set URG pointer in TCP

  This forces the URG flag to be set in the TCP header and the urgent 
  pointer is set to the length of the data field + 1 (as per normal).
  This works by setting the MSG_OOB flag on the send socket of the 
  TCP stream connection.

  This option can be conditionally compiled by adding -DURGPTR
  ONLY IF -DWIN32 is specified already.
