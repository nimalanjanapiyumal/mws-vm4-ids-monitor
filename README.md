# VM4 - MWS IDS / Suricata Monitor Repository

This repository configures VM4 as the IDS monitoring VM.

## VM details

- Hostname: `mws-ids01`
- Static IP: `192.168.1.40/24`
- IDS: Suricata
- Monitored broker: `192.168.1.10:1883`
- Special monitored test host: `192.168.1.50`

## Single setup command

```bash
sudo bash setup.sh
```

## Important virtual network setting

For VM4 to see traffic between other VMs, enable one of the following:

- Promiscuous mode on the virtual switch/port group; or
- A mirrored/SPAN port; or
- Run packet captures on VM1 as supporting evidence if your hypervisor does not support mirroring.

## Verify

```bash
bash verify.sh
```

## Logs

```bash
sudo tail -f /var/log/suricata/fast.log
sudo journalctl -u mws-ids-watch -f
```
