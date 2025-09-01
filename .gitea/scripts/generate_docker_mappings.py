#!/usr/bin/env python3
import os
import re
import json


def extract_docker_mappings():
    mappings = {}
    containers_dir = 'containers'

    for file in os.listdir(containers_dir):
        if not file.endswith('.nix'):
            continue

        service_name = file.replace('.nix', '')
        filepath = os.path.join(containers_dir, file)

        with open(filepath, 'r') as f:
            content = f.read()

        image_match = re.search(r'image\s*=\s*"([^:]+):(?:\${cfg\.version})', content)
        if image_match:
            mappings[service_name] = image_match.group(1)

    with open('docker-mappings.json', 'w') as f:
        json.dump(mappings, f, indent=2)


if __name__ == "__main__":
    extract_docker_mappings()