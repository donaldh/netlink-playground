#!/usr/bin/bash
QDISCS=${QDISCS:-blackhole cake cbs choke codel drr etf ets pfifo bfifo pfifo_head_drop fq fq_codel \
       fq_pie noqueue pfifo_fast gred hfsc hhf htb ingress clsact mq mqprio multiq netem \
       pie plug prio qfq red sfb sfq taprio tbf}

iftype() {
    case $1 in
        mq | mqprio | multiq | taprio)
            echo "veth"
            ;;
        *)
            echo "dummy"
            ;;
    esac
}

parent() {
    case $1 in
        ingress | clsact)
            echo "4294967281"
            ;;
        *)
            echo "4294967295"
            ;;
    esac
}

options() {
    case $1 in
        cbs)
            echo ", \"options\": { \"parms\": \"00000000 00000000 00000000 00000000 00000000\" }"
            ;;
        choke)
            echo ", \"options\": { \"parms\": \"00000000 00000000 00000000 00000000\",
                    \"stab\": \"$(perl -e 'print "00" x 256')\" }"
            ;;
        etf)
            echo ", \"options\": { \"parms\": \"00000000 0b000000 00000000\" }"
            ;;
        ets)
            echo ", \"options\": { \"nbands\": 1 }"
            ;;
        gred)
            echo ", \"options\": { \"limit\": 1, \"dps\": \"01000000 00000000 00000000\" }"
            ;;
        hfsc)
            echo ", \"options\": { }"
            ;;
        htb)
            echo ", \"options\": { \"init\": { \"version\": 3 } }"
            ;;
        mqprio)
            echo ", \"options\": { \"num-tc\": 1, \"count\": \"01$(perl -e 'print "00" x 31')\" }"
            ;;
        multiq)
            echo ", \"options\": { \"bands\": 1, \"max-bands\": 16 }"
            ;;
        netem)
            echo ", \"options\": { } "
            ;;
        prio)
            echo ", \"options\": { \"bands\": 2 }"
            ;;
        red)
            echo ", \"options\": { \"parms\": \"$(perl -e 'print "00" x 16')\", \
                    \"stab\": \"$(perl -e 'print "00" x 256')\" }"
            ;;
        taprio)
            echo ", \"options\": { \"sched-cycle-time\": 1000, \"sched-clockid\": 11,
                    \"sched-entry-list\": { \"entry\": { \"cmd\": 0, \"gate-mask\": 1, \"interval\": 500000 } },
                    \"priomap\": \"01$(perl -e 'print "00" x 16')0001$(perl -e 'print "00" x 63')\" },
                    \"stab\": {\"base\": \"00000000 10000000 00000000 00000000 00000000 00000000\" }"
                    #\"stab\": {\"base\": {\"overhead\": 24 } }"
            ;;
        tbf)
            echo ", \"options\": { \"parms\": \"$(perl -e 'print "00" x 36')\",
                                       \"burst\": 1000 }"
            ;;
        *)
            echo ""
            ;;
    esac
}
for qdisc in ${QDISCS}
do
    echo ""
    echo "*** ${qdisc} ***"
    sudo ip link add ${qdisc} type $(iftype ${qdisc})
    INDEX=`ip -j link show ${qdisc} | jq -r '.[] | .ifindex'`
    sudo ./tools/net/ynl/cli.py \
         --spec Documentation/netlink/specs/tc.yaml \
         --create --replace \
         --do newqdisc --json "{
             \"ifindex\": ${INDEX}, \"parent\": $(parent ${qdisc}),
             \"kind\": \"${qdisc}\"$(options ${qdisc})
             }" 2>&1
done
true
