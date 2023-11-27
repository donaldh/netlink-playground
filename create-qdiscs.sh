#!/usr/bin/env bash
DP='mydp'
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
            echo ", \"tca-options\": { \"parms\": \"00000000 00000000 00000000 00000000 00000000\" }"
            ;;
        choke)
            echo ", \"tca-options\": { \"parms\": \"00000000 00000000 00000000 00000000\",
                    \"stab\": \"$(perl -e 'print "00" x 256')\" }"
            ;;
        etf)
            echo ", \"tca-options\": { \"parms\": \"00000000 0b000000 00000000\" }"
            ;;
        ets)
            echo ", \"tca-options\": { \"nbands\": 1 }"
            ;;
        gred)
            echo ", \"tca-options\": { \"limit\": 1, \"dps\": \"01000000 00000000 00000000\" }"
            ;;
        hfsc)
            echo ", \"tca-options\": \"0000\""
            ;;
        htb)
            echo ", \"tca-options\": { \"init\": \"03000000 00000000 00000000 00000000 00000000\" }"
            ;;
        mqprio)
            echo ", \"tca-options\": \"01$(perl -e 'print "00" x 16')0001$(perl -e 'print "00" x 63')\""
            ;;
        multiq)
            echo ", \"tca-options\": \"01001000\""
            ;;
        netem)
            echo ", \"tca-options\": \"$(perl -e 'print "00" x 24')\""
            ;;
        prio)
            echo ", \"tca-options\": \"02000000$(perl -e 'print "00" x 16')\""
            ;;
        red)
            echo ", \"tca-options\": { \"parms\": \"$(perl -e 'print "00" x 16')\", \
                    \"stab\": \"$(perl -e 'print "00" x 256')\" }"
            ;;
        taprio)
            echo ", \"tca-options\": { \"sched-cycle-time\": 1000, \"sched-clockid\": 11,
                    \"sched-entry-list\": { \"entry\": { \"cmd\": 0, \"gate-mask\": 1, \"interval\": 500000 } },
                    \"priomap\": \"01$(perl -e 'print "00" x 16')0001$(perl -e 'print "00" x 63')\" },
                    \"tca-stab\": {\"base\": \"00000000 10000000 00000000 00000000 00000000 00000000\" }"
                    #\"tca-stab\": {\"base\": {\"overhead\": 24 } }"
            ;;
        tbf)
            echo ", \"tca-options\": { \"parms\": \"$(perl -e 'print "00" x 36')\",
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
             \"tcm-ifindex\": ${INDEX}, \"tcm-parent\": $(parent ${qdisc}),
             \"tca-kind\": \"${qdisc}\"$(options ${qdisc})
             }" 2>&1
done
true
