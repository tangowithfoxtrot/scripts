#!/usr/bin/env python3
"""
A simple script to manage DigitalOcean droplets.
"""
import requests
import json
import sys
import os

API_URL = "https://api.digitalocean.com/v2"

class DigitalOcean(object):
    def __init__(self, token):
        self.token = token
        self.headers = {
            'Authorization': 'Bearer {}'.format(self.token),
            'Content-Type': 'application/json'
        }

    def get(self, url):
        return requests.get(url, headers=self.headers)

    def post(self, url, data):
        return requests.post(url, headers=self.headers, data=data)

    def delete(self, url):
        return requests.delete(url, headers=self.headers)

    def put(self, url, data):
        return requests.put(url, headers=self.headers, data=data)

    def get_droplets(self):
        return self.get(API_URL + '/droplets?page=1&per_page=1')

    def get_droplet_id_by_name(self, name):
        r = self.get_droplets()
        if r.status_code != 200:
            return None
        droplets = json.loads(r.text)['droplets']
        for droplet in droplets:
            if droplet['name'] == name:
                return droplet['id']
        return None

    def create_droplet(self, name, region, image, size):
        if size == 'smallest':
            sizes = self.get_sizes_in_region(region)
            size = sizes[0]
        elif size == 'smaller':
            sizes = self.get_sizes_in_region(region)
            size = sizes[1]
        elif size == 'small':
            sizes = self.get_sizes_in_region(region)
            size = sizes[2]
        elif size == 'medium':
            sizes = self.get_sizes_in_region(region)
            size = sizes[3]
        else:
            sys.write.stderr("Invalid size \"{}\"".format(size))
            sys.exit(1)
        keys = []
        for ssh_key in self.list_ssh_keys().json()['ssh_keys']:
            keys.append(ssh_key['id'])
        data = {
            'name': name,
            'region': region,
            'size': size,
            'image': image,
            'ssh_keys': keys
            # 'backups': False,
            # 'ipv6': True,
            # 'user_data': None,
            # 'private_networking': None
        }
        print(data)
        return self.post(API_URL + '/droplets', json.dumps(data))

    def get_droplet_ip_by_name(self, name):
        r = self.get_droplets()
        if r.status_code != 200:
            return None
        droplets = json.loads(r.text)['droplets']
        for droplet in droplets:
            if droplet['name'] == name:
                return droplet['networks']['v4'][0]['ip_address']
        return None

    def delete_droplet(self, droplet_id):
        return self.delete(API_URL + '/droplets/{}'.format(droplet_id))

    def get_sizes_in_region(self, region_slug):
        response = self.get(API_URL + '/regions')
        regions = response.json()['regions']
        for r in regions:
            if r['slug'] == region_slug:
                return r['sizes']
        return []

    def list_ssh_keys(self):
        return self.get(API_URL + '/account/keys')

do = DigitalOcean(os.environ['DO_TOKEN'])

def main():
    if len(sys.argv) == 1:
        print("Usage: do.py [create|delete|list]")
        sys.exit(1)
    if sys.argv[1] == 'create':
        if len(sys.argv) != 6:
            print("Usage: do.py create [name] [region] [image] [size]")
            sys.exit(1)
        name = sys.argv[2]
        region = sys.argv[3]
        image = sys.argv[4]
        size = sys.argv[5]
        r = do.create_droplet(name, region, image, size)
        print(r.status_code)
        print(r.text)
    elif sys.argv[1] == 'delete':
        if len(sys.argv) != 3:
            print("Usage: do.py delete [name]")
            sys.exit(1)
        name = sys.argv[2]
        droplet_id = do.get_droplet_id_by_name(name)
        if droplet_id is None:
            print("Droplet \"{}\" not found".format(name))
            sys.exit(1)
        r = do.delete_droplet(droplet_id)
        print(r.status_code)
        print(r.text)
    elif sys.argv[1] == 'list' or sys.argv[1] == 'ls':
        if sys.argv[2] == 'ssh_keys':
            r = do.list_ssh_keys()
            keys = []
            for ssh_key in do.list_ssh_keys().json()['ssh_keys']:
                keys.append(ssh_key['fingerprint'])
            print(keys)

        if sys.argv[2] == 'droplets':
            r = do.get_droplets()
            print(r.status_code)
            print(r.text)
    elif sys.argv[1] == 'get':
        if sys.argv[2] == 'ip':
            if len(sys.argv) != 4:
                print("Usage: do.py get ip [name]")
                sys.exit(1)
            name = sys.argv[3]
            ip = do.get_droplet_ip_by_name(name)
            if ip is None:
                print("Droplet \"{}\" not found".format(name))
                sys.exit(1)
            print(ip)
    else:
        print("Usage: do.py [create|delete|list|get]")
        sys.exit(1)

if __name__ == '__main__':
    main()
