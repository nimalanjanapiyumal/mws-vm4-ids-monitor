# Evidence Notes - VM4 IDS / Suricata Monitor

## What to capture

- Hostname: `mws-ids01`
- Static IP: `192.168.1.40/24`
- Setup command: `sudo bash setup.sh`
- Verification command: `bash verify.sh`
- Role: Suricata IDS sensor and log watcher for MQTT traffic and unauthorised lab VM activity

## Suggested screenshot commands

```bash
hostnamectl --static
ip -4 addr
bash verify.sh
```
