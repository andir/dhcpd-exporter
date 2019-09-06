#! /usr/bin/env python3

import time
import ipaddress
import argparse
from datetime import datetime, timedelta
from itertools import chain
from prometheus_client.core import (
    GaugeMetricFamily,
    CounterMetricFamily,
    HistogramMetricFamily,
)
from prometheus_client import CollectorRegistry, start_http_server
import isc_dhcp_filter

_fake_now = None


class DHCPCollector:
    def __init__(self, filename, subnets):
        self._filename = filename
        self._subnets = subnets

    def _read_file(self):
        leases = isc_dhcp_filter.parse(self._filename)
        return leases

    def collect(self):
        leases = self._read_file()

        total_metric = GaugeMetricFamily(
            "dhcpd_leases_total", "Total known DHCP leases", None, ["network"]
        )
        in_use_metric = GaugeMetricFamily(
            "dhcpd_leases_in_use_total", "In use DHCP leases", None, ["network"]
        )
        expired_metric = GaugeMetricFamily(
            "dhcpd_leases_expired", "Expired DHCP leaess", None, ["network"]
        )

        _buckets = [60, 300, 600, 900, 1200, 1500, 1800, 2100, 2400, 2700, 3600]

        buckets = list(zip(chain([0], _buckets), chain(_buckets, ["+Inf"])))

        now = datetime.utcnow()

        def age(t):
            d = now - t
            return d

        active_lease_age_metric = HistogramMetricFamily(
            "dhcpd_leases_in_use_age_histogram",
            "In use leases by age",
            labels=("network",),
        )

        for subnet in self._subnets:
            n = "{}".format(subnet)

            l = leases.filter(lambda lease: ipaddress.IPv4Address(lease.ip) in subnet)

            total = l.count()
            in_use = l.active.valid.count()
            expired = l.filter(lambda l: l.binding_state == "free").count()

            in_use_metric.add_metric([n], in_use)
            expired_metric.add_metric([n], expired)
            total_metric.add_metric([n], total)

            b = {}
            for (prev, bucket) in buckets:
                if bucket == "+Inf":
                    prev = timedelta(seconds=prev)
                    c = l.active.filter(lambda l: age(l.start) > prev).count()
                else:
                    prev = timedelta(seconds=prev)
                    upper = timedelta(seconds=bucket)
                    c = l.active.filter(lambda l: prev < age(l.start) <= upper).count()

                b[str(bucket)] = c

            sum_age = sum(map(lambda l: age(l.start).seconds, l.active))

            active_lease_age_metric.add_metric([n], list(b.items()), sum_age)

        yield in_use_metric
        yield expired_metric
        yield total_metric
        yield active_lease_age_metric


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("lease_file", type=str)
    parser.add_argument("subnets", nargs="+")

    args = parser.parse_args()

    subnets = [ipaddress.IPv4Network(subnet) for subnet in args.subnets]

    registry = CollectorRegistry()
    registry.register(DHCPCollector(args.lease_file, subnets))

    start_http_server(9267, registry=registry)

    while True:
        time.sleep(30)


if __name__ == "__main__":
    main()
