#!/bin/bash
# add 2018-05-02 by PascalWithopf, released under ASL 2.0
. $srcdir/diag.sh init
./have_relpSrvSetOversizeMode
if [ $? -eq 1 ]; then
  echo "imrelp parameter oversizeMode not available. Test stopped"
  exit 77
fi;
generate_conf
add_conf '
module(load="../plugins/imrelp/.libs/imrelp")
global(maxMessageSize="230")


input(type="imrelp" port="13514" maxdatasize="300")

template(name="outfmt" type="string" string="%rawmsg%\n")
action(type="omfile" template="outfmt"
				 file="rsyslog.out.log")
'
# TODO: add tcpflood option to specific EXACT test message size!
startup
. $srcdir/diag.sh tcpflood -Trelp-plain -p13514 -m1 -d 240
shutdown_when_empty # shut down rsyslogd when done processing messages
wait_shutdown

# We need the ^-sign to symbolize the beginning and the $-sign to symbolize the end
# because otherwise we won't know if it was truncated at the right length.
grep "^<167>Mar  1 01:00:00 172.20.245.8 tag msgnum:00000000:240:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX$" rsyslog.out.log > /dev/null
if [ $? -ne 0 ]; then
        echo
        echo "FAIL: expected message not found. rsyslog.out.log is:"
        cat rsyslog.out.log
        error_exit 1
fi

grep "message too long.*begin of message is:" rsyslog.out.log > /dev/null
if [ $? -ne 0 ]; then
        echo
        echo "FAIL: expected message not found. rsyslog.out.log is:"
        cat rsyslog.out.log
        error_exit 1
fi


exit_test