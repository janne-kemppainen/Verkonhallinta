# IP-suunnitelma

Tämä dokumentti kuvaa `topology/golden.clab.yml`-topologian käytössä olevat
IP-verkot ja niissä määritellyt laiteosoitteet. Staattiset osoitteet perustuvat
topologian `exec`-määrityksiin ja reitittimien FRR-asetuksiin.

## Yhteenveto verkoista

| Verkko | Käyttötarkoitus | Yhdyskäytävä / reitittimet |
|---|---|---|
| `10.10.10.0/24` | Käyttäjäverkko | `r1`: `10.10.10.1` ja `10.10.10.254` |
| `10.10.20.0/24` | Palvelinverkko | `r2`: `10.10.20.1` |
| `10.10.30.0/24` | Haaratoimiston verkko | `r3`: `10.10.30.1` |
| `10.10.99.0/24` | Erillinen hallintapalveluiden LAN | `r2`: `10.10.99.1` |
| `10.255.12.0/30` | Reitittimien `r1`–`r2` välinen linkki | `r1`: `10.255.12.1`, `r2`: `10.255.12.2` |
| `10.255.23.0/30` | Reitittimien `r2`–`r3` välinen linkki | `r2`: `10.255.23.1`, `r3`: `10.255.23.2` |
| `172.20.20.0/24` | Containerlabin Docker-hallintaverkko `clab-mgmt` (noodien `eth0`) | Containerlab/Docker hallinnoi; reitittimien oletusyhdyskäytävä `172.20.20.1` |

## Staattiset laiteosoitteet

### Käyttäjäverkko — `10.10.10.0/24`

| Laite | Liitäntä | Osoite | Huomio |
|---|---|---|---|
| `r1` | `eth2` | `10.10.10.1/24` | Käyttäjäverkon yhdyskäytävä |
| `r1` | `eth3` | `10.10.10.254/24` | Erillinen linkki hyökkääjäkonttiin |
| `client1` | `eth1` | `10.10.10.101/24` | Oletusyhdyskäytävä `10.10.10.1` |
| `attacker` | `eth1` | `10.10.10.200/24` | Oletusyhdyskäytävä `10.10.10.1` |

`client1` ja `attacker` on kytketty topologiassa suoraan eri `r1`-liitäntöihin.
Molemmat linkit käyttävät samaa IP-aliverkkoa. Huomaa, että `attacker`-noodin
oletusyhdyskäytäväksi on määritelty `10.10.10.1`, vaikka sen suoraan kytketyn
`r1`-liitännän osoite on `10.10.10.254`. Tarkista tämä reititysristiriita, jos
hyökkääjän liikenne ei kulje odotetusti.

### Palvelinverkko — `10.10.20.0/24`

| Laite | Liitäntä | Osoite | Huomio |
|---|---|---|---|
| `r2` | `eth2` | `10.10.20.1/24` | Palvelinverkon yhdyskäytävä |
| `web1` | `eth1` | `10.10.20.101/24` | Oletusyhdyskäytävä `10.10.20.1` |
| `db1` | `eth1` | `10.10.20.102/24` | Oletusyhdyskäytävä `10.10.20.1` |

### Haaratoimiston verkko — `10.10.30.0/24`

| Laite | Liitäntä | Osoite | Huomio |
|---|---|---|---|
| `r3` | `eth2` | `10.10.30.1/24` | Haaratoimiston yhdyskäytävä |
| `branch-client` | `eth1` | `10.10.30.101/24` | Oletusyhdyskäytävä `10.10.30.1` |

### Hallintapalveluiden LAN — `10.10.99.0/24`

| Laite | Liitäntä | Osoite | Huomio |
|---|---|---|---|
| `r2` | `eth3` | `10.10.99.1/24` | Hallintaverkon yhdyskäytävä |
| `ansible` | `eth1` | `10.10.99.10/24` | |
| `prometheus` | `eth1` | `10.10.99.20/24` | |
| `cadvisor` | `eth1` | `10.10.99.21/24` | |
| `grafana` | `eth1` | `10.10.99.30/24` | |
| `zabbix` | `eth1` | `10.10.99.40/24` | |
| `syslog` | `eth1` | `10.10.99.50/24` | Lisäksi staattinen osoite `clab-mgmt`-verkossa |

Hallintapalvelut on kytketty `mgmt-br|mgmt-bp`-L2-siltaan. Silta yhdistää
palvelut ja `r2`:n samaan `10.10.99.0/24`-verkkoon; se ei itsessään jaa
IP-osoitteita.

### Reitittimien väliset linkit

| Verkko | Laite | Liitäntä | Osoite |
|---|---|---|---|
| `10.255.12.0/30` | `r1` | `eth1` | `10.255.12.1/30` |
| `10.255.12.0/30` | `r2` | `eth1` | `10.255.12.2/30` |
| `10.255.23.0/30` | `r2` | `eth4` | `10.255.23.1/30` |
| `10.255.23.0/30` | `r3` | `eth1` | `10.255.23.2/30` |

Nämä ovat suorat reititinlinkit ilman erillistä oletusyhdyskäytävää.

## Containerlabin hallintaverkko — `clab-mgmt`

Containerlabin `mgmt`-asetuksessa määritelty `172.20.20.0/24` on erillinen
Docker-hallintaverkko. Se ei ole sama verkko kuin topologian
`10.10.99.0/24`-hallinta-LAN. Noodit saavat `eth0`-liitännälleen osoitteen
Containerlabin hallintaverkosta; dynaamiset noodikohtaiset osoitteet
määräytyvät käyttöönotossa. Reitittimien bootstrap-määritys asettaa
oletusreitiksi `172.20.20.1`.

| Laite | Liitäntä | Osoite |
|---|---|---|
| `syslog` | `eth0` / Containerlab mgmt | `172.20.20.50/24` (topologiassa staattinen) |
| Muut Containerlab-noodit | `eth0` / Containerlab mgmt | DHCP-/Docker-osoite, tarkista käynnissä olevasta ympäristöstä; reitittimien oletusyhdyskäytävä `172.20.20.1` |

Tarkista käynnissä olevan ympäristön hallintaosoitteet esimerkiksi komennoilla:

```bash
sudo containerlab inspect -t topology/golden.clab.yml
docker network inspect clab-mgmt
```

## DNS-asetus

`client1`, `web1`, `db1` ja `branch-client` määrittävät DNS-palvelimeksi
`10.255.255.254`. Osoitetta ei määritellä tässä topologiassa minkään noodin
osoitteeksi eikä sille ole topologiassa kuvattua aliverkkoa. Se on siten
ympäristön ulkopuolinen tai muuten erikseen järjestettävä DNS-palvelin, ei
topologian sisäinen host-osoite.
