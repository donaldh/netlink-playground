#!/usr/bin/env bash
DP='mydp'
for qdisc in blackhole cake cbs choke codel drr etf ets pfifo bfifo pfifo_head_drop fq fq_codel \
                       fq_pie noqueue pfifo_fast gred hfsc hhf htb ingress clsact mq mqprio multiq \
                       netem pie plug prio qfq red sfb sfq taprio tbf
do
    echo "*** ${qdisc} ***"
    sudo ip link del ${qdisc} 2>&1
done
true
