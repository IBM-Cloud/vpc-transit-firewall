#!/usr/bin/env python
import procin

c = procin.Command(print_command=True, json=True)
o = c.run(["terraform", "output", "-no-color", "-json"])
for spoke_key, spoke in o["spokes"]["value"].items():
  vpc_id = spoke["vpc_id"]
  for zone_key, zone in spoke["zones"].items():
    routing_table_id = zone["routing_table_id"]
    print(f"ibmcloud is vpc-routing-table-routes {vpc_id} {routing_table_id}")
