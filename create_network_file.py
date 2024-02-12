#!/bin/env python3

import argparse
import subprocess
import os

output = subprocess.run(["vagrant", "ssh-config"], cwd="./develop/", capture_output=True).stdout

translate = {
    "User": "whoami",
    "IdentityFile": "keyfile",
    "HostName": "network",
    "Host": "hostname"
}

with open("develop_network_config", "w") as f:
    f.write("[__anonymous__]\n")
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
        if key in translate:
            f.write("%s_%s = %s\n" % (host, translate[key], val))
