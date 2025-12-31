#!/usr/bin/env python3
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLIENT_ENV_EXAMPLE = ROOT / 'apps' / 'client' / '.env.example'
CLIENT_ENV = ROOT / 'apps' / 'client' / '.env'


def read_example_defaults():
    defaults = {'SERVER_IP': 'localhost', 'SERVER_PORT': '8080'}
    if CLIENT_ENV_EXAMPLE.exists():
        for line in CLIENT_ENV_EXAMPLE.read_text().splitlines():
            if '=' in line and not line.strip().startswith('#'):
                k, v = line.split('=', 1)
                defaults[k.strip()] = v.strip()
    return defaults


def prompt_input(prompt, default):
    raw = input(f"{prompt} [{default}]: ").strip()
    return raw if raw else default


def main():
    print('Setting up local .env for client...')
    defaults = read_example_defaults()

    if CLIENT_ENV.exists():
        ans = input(f'.env already exists at {CLIENT_ENV}. Overwrite? (y/N): ').strip().lower()
        if ans != 'y':
            print('Aborted. No changes made.')
            return

    ip = prompt_input('Server IP', defaults.get('SERVER_IP', 'localhost'))
    port = prompt_input('Server Port', defaults.get('SERVER_PORT', '8080'))

    content = f"SERVER_IP={ip}\nSERVER_PORT={port}\n"
    CLIENT_ENV.write_text(content)
    print(f'Wrote {CLIENT_ENV} with SERVER_IP={ip} SERVER_PORT={port}')


if __name__ == '__main__':
    main()
