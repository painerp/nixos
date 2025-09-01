#!/usr/bin/env python3
import os
import re
import json


def update_renovate_config():
    containers_dir = 'containers'
    custom_managers = []

    for file in os.listdir(containers_dir):
        if not file.endswith('.nix'):
            continue

        service_name = file.replace('.nix', '')
        filepath = os.path.join(containers_dir, file)

        with open(filepath, 'r') as f:
            content = f.read()

        image_match = re.search(r'image\s*=\s*"([^:]+):(?:\${cfg\.version})', content)
        if image_match:
            docker_image = image_match.group(1)

            custom_manager = {
                "customType": "regex",
                "managerFilePatterns": ["/variants/.+\\.nix$/"],
                "matchStrings": [
                    f"{service_name}\\s*=\\s*\\{{[^}}]*?version\\s*=\\s*\"(?<currentValue>[^\"]+)\"[^}}]*?\\}}"
                ],
                "datasourceTemplate": "docker",
                "versioningTemplate": "semver",
                "depNameTemplate": docker_image
            }

            if "linuxserver" in docker_image:
                custom_manager["extractVersionTemplate"] = "^(?<version>\\d+\\.\\d+\\.\\d+)$"

            custom_managers.append(custom_manager)

    with open('renovate.json', 'r') as f:
        renovate_config = json.load(f)

    renovate_config['customManagers'] = custom_managers

    with open('renovate.json', 'w') as f:
        json.dump(renovate_config, f, indent=2)


if __name__ == "__main__":
    update_renovate_config()