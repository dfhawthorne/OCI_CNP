#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Reads Terraform State to determine security lists and routing tables
# ------------------------------------------------------------------------------

import json

with open('terraform.tfstate', 'r') as f:
    data = json.load(f)

for resource in data['resources']:
    if resource['mode'] != 'managed': continue
    for key in ['type', 'name', 'provider']:
        print(f'{key}={resource[key]} ', end='')
    print('')
