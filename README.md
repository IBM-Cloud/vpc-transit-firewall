A source network address translation, SNAT, is required in the firewall to route traffic over the floating ip that is attached to the firewall.  The NLB has Direct Server Retuirn, DSR.  The return address in the packet is the originating instance in the spoke. The server in the cloud is found with
```
iptables-restore <<'EOF'
*filter
:INPUT ACCEPT 
:FORWARD ACCEPT
:OUTPUT ACCEPT
COMMIT

*nat
:PREROUTING ACCEPT
:INPUT ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
-A POSTROUTING -d 10.8.0.0/18 -p tcp -j ACCEPT
-A POSTROUTING -s 10.8.1.0/24 -p tcp -j SNAT --to-source 10.8.0.198
-A POSTROUTING -s 10.8.2.0/24 -p tcp -j SNAT --to-source 10.8.0.198
COMMIT
EOF
# second
iptables-restore <<'EOF'
*filter
:INPUT ACCEPT 
:FORWARD ACCEPT
:OUTPUT ACCEPT
COMMIT

*nat
:PREROUTING ACCEPT
:INPUT ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
-A POSTROUTING -d 10.8.0.0/18 -p tcp -j ACCEPT
-A POSTROUTING -s 10.8.1.0/24 -p tcp -j SNAT --to-source 10.8.0.196
-A POSTROUTING -s 10.8.2.0/24 -p tcp -j SNAT --to-source 10.8.0.196
COMMIT
EOF
```

```
# set
sysctl -w net.ipv4.ip_forward=1
# print
sysctl net.ipv4.ip_forward


apt install -y ntpsec-ntpdate
```