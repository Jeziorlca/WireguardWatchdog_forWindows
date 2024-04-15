# WireguardWatchdog_forWindows

Why does this script exist?
I have run into problems where the Wireguard VPN is not up and running or stopps runing on my windows hosts. Preventing remote access to them. Reason unknown, I haven't looked into why this happens.

## How to use this script

This script is intended to run as a scheduled task to keep Wireguard VPN up and running.
It will look for a config file in the given path, which name is based on the hostname.

## ToDo:

- additional error handling
