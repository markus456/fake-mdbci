#!/bin/env python3

import argparse
import subprocess
import os

translate = {
    "User": "whoami",
    "IdentityFile": "keyfile",
    "HostName": "network",
    "Host": "hostname"
}

vms = []
output = subprocess.run(["vagrant", "status"], cwd="./develop/", capture_output=True).stdout

for line in output.decode().split(os.linesep):
    if "running" in line:
        vms.append(line.split(" ")[0])

with open("develop_network_config", "w") as f:
    f.write("[__anonymous__]\n")
    for vm in vms:
        output = subprocess.run(["vagrant", "ssh-config", vm], cwd="./develop/", capture_output=True).stdout
        for line in [s.strip() for s in output.decode().split(os.linesep)]:
            print(line)
            (key, sep, val) = line.partition(" ")
            if key == "Host":
                host = val
                # We need to change these, otherwise the hostnames are wrong.
                if val == "maxscale_000":
                    val = "maxscale"
                elif val == "maxscale_001":
                    val = "maxscale2"
                else:
                    val = val.replace("_", "-")
            if key in translate:
                f.write("%s_%s = %s\n" % (host, translate[key], val))
