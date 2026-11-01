# Viikko 2: SNMP ja verkon perustason valvonta

## 1. Johdanto

SNMP (Simple Network Management Protocol) on standardoitu protokolla, jolla valvontajärjestelmä kerää tietoa verkon laitteista ja palvelimista. SNMP perustuu manager-agent-malliin:

- **Agentti** (tässä `snmpd`) toimii valvottavassa laitteessa ja vastaa kyselyihin.
- **Manageri** (tässä ansible-kontin komentorivityökalut `snmpget`, `snmpwalk`, `snmptranslate`) lähettää kyselyt ja vastaanottaa vastaukset.

Tiedot on järjestetty puumaiseksi hierarkiaksi. Jokaisella objektilla on numeerinen tunniste, OID (Object Identifier), ja MIB-tiedostot (Management Information Base) antavat OID:eille luettavat nimet ja kuvaukset. Kyselyt kulkevat UDP-portissa 161.

Tehtävässä käytettiin SNMPv2c:tä, jossa pääsy perustuu yhteisönimeen (community string) `public`.

## 2. Asennus

### Agentti web1:lle

```bash
docker exec -it clab-hamk-verkonhallinta-golden-web1 bash
apt update
apt install snmp snmpd -y
```

Ubuntun oletuskonfiguraatio (`/etc/snmp/snmpd.conf`) ei sellaisenaan sopinut tehtävään:

```text
agentaddress  127.0.0.1,[::1]
view   systemonly  included   .1.3.6.1.2.1.1
view   systemonly  included   .1.3.6.1.2.1.25.1
rocommunity  public default -V systemonly
```

- `agentaddress 127.0.0.1,[::1]`: agentti kuuntelee vain localhostia, joten ansible-kontti ei saisi yhteyttä.
- `rocommunity public default -V systemonly`: `public` näkee vain system-haaran (`.1.3.6.1.2.1.1`) ja hrSystem-haaran (`.1.3.6.1.2.1.25.1`). Rajapintatiedot (`ifDescr`, `.1.3.6.1.2.1.2`) eivät olisi näkyneet.

Alkuperäinen tiedosto varmuuskopioitiin (`snmpd.conf.orig`) ja rivit muutettiin:

```bash
cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
sed -i 's/^agentaddress.*/agentaddress udp:161/' /etc/snmp/snmpd.conf
sed -i 's/^rocommunity .*/rocommunity public/' /etc/snmp/snmpd.conf
service snmpd restart
```

Kontissa ei ole systemd:tä, joten palvelua hallittiin `service`-komennolla (`systemctl` ei toimi).

### MIB-tiedostot

Ensimmäinen testi nimellä epäonnistui, mutta numeerinen OID toimi:

```text
$ snmpget -v2c -c public localhost sysName.0
sysName.0: Unknown Object Identifier (Sub-id not found: (top) -> sysName)

$ snmpget -v2c -c public localhost 1.3.6.1.2.1.1.5.0
iso.3.6.1.2.1.1.5.0 = STRING: "web1"
```

Agentti siis toimi, mutta kyselytyökalu ei tuntenut nimiä. Ubuntun `snmp`-paketti ei sisällä standardi-MIBejä (esim. SNMPv2-MIB, IF-MIB) lisenssisyistä. Ratkaisuna asennettiin `snmp-mibs-downloader` ja poistettiin MIBien lataamisen estävä rivi:

```bash
apt install snmp-mibs-downloader -y
sed -i 's/^mibs :/#mibs :/' /etc/snmp/snmp.conf
```

Tämän jälkeen sama kysely palautti `SNMPv2-MIB::sysName.0 = STRING: web1`.

Asennuksen tulosteet: [week02-web1-install.txt](week02-web1-install.txt)

### Manageri (ansible)

Ansible-konttiin asennettiin vain kyselytyökalut ja MIBit, ei agenttia: `snmp` ja `snmp-mibs-downloader`.

### db1 ja branch-client

Molemmat konfiguroitiin samalla tavalla kuin web1 (`snmp`, `snmpd`, samat kaksi muutosta `snmpd.conf`-tiedostoon, `service snmpd restart`).

## 3. Kerätyt tiedot

### Ensimmäinen kysely (snmpwalk)

```bash
snmpwalk -v2c -c public web1 system
```

Koko tuloste: [week02-web1-system.txt](week02-web1-system.txt)

`snmpwalk` käy läpi koko system-haaran (GETNEXT-pyynnöillä), kun taas `snmpget` hakee yhden objektin (GET). Ansible tunnisti nimen `web1` osoitteeksi `172.20.20.5`, eli kyselyt kulkevat clab-mgmt-hallintaverkon kautta eivätkä datatason verkon.

### Järjestelmätiedot (snmpget)

```text
SNMPv2-MIB::sysName.0 = STRING: web1
SNMPv2-MIB::sysDescr.0 = STRING: Linux web1 6.18.54.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Tue Oct  6 19:13:07 UTC 2026 x86_64
DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (43887) 0:07:18.87
```

Tuloste: [week02-web1-get.txt](week02-web1-get.txt)

- **Järjestelmän nimi:** web1
- **Käyttöjärjestelmä:** Linux, ydin `6.18.54.1-microsoft-standard-WSL2`. Kontilla ei ole omaa ydintä, vaan se jakaa Windows-koneen WSL2-ytimen. Siksi `sysDescr` ei näytä Ubuntun versiota.
- **Uptime:** `sysUpTime` kertoo ajan SNMP-agentin käynnistymisestä, ei laitteen käyttöaikaa.

`sysContact` ja `sysLocation` sisältävät pakettien oletusarvot (`Me <me@example.org>`, `Sitting on the Dock of the Bay`), koska niitä ei ole asetettu.

### Usean laitteen valvonta

Tuloste: [week02-multi.txt](week02-multi.txt)

| Laite | Nimi | Käyttöjärjestelmä | Uptime (sysUpTime, agentti) | Uptime (hrSystemUptime, järjestelmä) |
|---|---|---|---|---|
| web1 | web1 | Linux 6.18.54.1-microsoft-standard-WSL2 x86_64 | 0:09:49 | 0:21:49 |
| db1 | db1 | Linux 6.18.54.1-microsoft-standard-WSL2 x86_64 | 0:00:37 | 0:21:49 |
| branch-client | branch-client | Linux 6.18.54.1-microsoft-standard-WSL2 x86_64 | 0:00:32 | 0:21:49 |

`hrSystemUptime` on kaikilla sama, koska kontit jakavat saman WSL2-ytimen, jonka käyttöaika alkoi Windows-koneen uudelleenkäynnistyksestä. `sysUpTime` vaihtelee, koska snmpd käynnistettiin eri aikaan kullakin laitteella.

## 4. Verkkorajapinnat

```bash
snmpwalk -v2c -c public web1 ifDescr
snmpwalk -v2c -c public web1 ifOperStatus
```

Tuloste: [week02-web1-interfaces.txt](week02-web1-interfaces.txt)

| ifIndex | ifDescr | ifOperStatus | IP-osoite (`ip -br addr`) | Verkko |
|---|---|---|---|---|
| 1 | lo | up(1) | 127.0.0.1/8 | loopback |
| 15 | eth0 | up(1) | 172.20.20.5/24 | clab-mgmt (hallinta) |
| 32 | eth1 | up(1) | 10.10.20.101/24 | Server-verkko 10.10.20.0/24 (r2) |

- Rajapintoja löytyi **kolme**.
- **eth1** yhdistää web1:n varsinaiseen verkkoon (Server-verkko). **eth0** on hallintaverkko, jonka kautta SNMP-kyselyt kulkevat.
- ifIndex-numerot eivät ole peräkkäisiä, koska SNMP käyttää ytimen rajapintanumeroa.
- `ip` näyttää `lo`:n tilana `UNKNOWN`, mutta SNMP näyttää `up(1)`.

## 5. OID-analyysi

Tuloste: [week02-oid.txt](week02-oid.txt) (`snmptranslate -On` ja `snmptranslate -Td`)

| OID | Numeerinen | Tarkoitus |
|---|---|---|
| sysName.0 | .1.3.6.1.2.1.1.5.0 | Laitteen hallinnollisesti asetettu nimi (yleensä FQDN). |
| sysDescr.0 | .1.3.6.1.2.1.1.1.0 | Tekstikuvaus laitteesta: laitteisto, käyttöjärjestelmä ja versio. |
| sysUpTime.0 | .1.3.6.1.2.1.1.3.0 | Aika sadasosasekunteina siitä, kun agentti (network management portion) viimeksi käynnistyi. |
| ifDescr | .1.3.6.1.2.1.2.2.1.2 | Rajapinnan tekstikuvaus, Linuxissa rajapinnan nimi (lo, eth0, eth1). |
| ifOperStatus | .1.3.6.1.2.1.2.2.1.8 | Rajapinnan todellinen toimintatila: up(1), down(2), testing(3) jne. |

Havainnot rakenteesta:

- `.1.3.6.1.2.1` on mib-2, eli standardiobjektien juuri (`iso.org.dod.internet.mgmt.mib-2`).
- `.1.3.6.1.2.1.1` on system-haara. Skalaariobjektien perässä on `.0`, koska niillä on vain yksi arvo.
- `.1.3.6.1.2.1.2.2.1` on interfaces-haaran ifTable/ifEntry. Taulukko-objekteissa `.0`:n tilalla on ifIndex, esim. `ifDescr.32` = eth1.
- Samalla OID:lla voi olla useampi nimi: `sysUpTime.0` näkyy tulosteissa nimellä `DISMAN-EVENT-MIB::sysUpTimeInstance`.
- OID on varsinainen tunniste, ja MIB tekee siitä vain luettavan. Ilman MIBejä agentti vastasi silti, mutta tulos näkyi muodossa `iso.3.6.1.2.1.1.5.0`.

## 6. Pohdinta

**Mitä hyötyä SNMP:stä on verkonhallinnassa?**
SNMP on lähes kaikkien verkkolaitteiden tukema standardi, joten samalla managerilla voi valvoa eri valmistajien reitittimiä, kytkimiä ja palvelimia. Tiedot saadaan keskitetysti ja automaattisesti ilman kirjautumista jokaiseen laitteeseen.

**Mitä tietoa SNMP:n avulla voidaan kerätä?**
Esimerkiksi laitteen nimi, kuvaus ja käyttöaika, rajapintojen tilat ja liikennelaskurit, sekä HOST-RESOURCES-MIBin kautta prosessorin, muistin ja levyjen käyttö. Agentti voi myös itse lähettää ilmoituksia (trap/inform).

**Mitä ongelmia yhteisöpohjaisessa SNMPv2:ssa on?**
Yhteisönimi kulkee verkossa selväkielisenä, eikä liikennettä salata. Yhteisönimi toimii ainoana "salasanana", ja oletusarvo `public` on helppo arvata. Kun tässä tehtävässä poistettiin `-V systemonly` -rajaus, kuka tahansa yhteisönimen tietävä pystyy lukemaan koko MIB-puun. Käyttäjäkohtaista tunnistusta ei ole.

**Missä tilanteissa käyttäisit mieluummin SNMPv3:a?**
Tuotantoympäristössä, varsinkin jos hallintaliikenne kulkee jaetun tai epäluotettavan verkon yli, ja aina kun SNMP:llä on kirjoitusoikeus. SNMPv3 tarjoaa käyttäjäkohtaisen tunnistuksen ja salauksen (authPriv).

**Omat havainnot**
- Kontit jakavat isäntäkoneen ytimen, mikä näkyy suoraan SNMP-tiedoissa (`sysDescr`, `hrSystemUptime`). Kontin "käyttöjärjestelmä" ja "uptime" eivät ole samoja kuin fyysisellä palvelimella.
- `sysUpTime` mittaa agentin eikä laitteen käyttöaikaa, joten pelkän sen perusteella ei voi päätellä laitteen uudelleenkäynnistyksiä.
- Ubuntun oletuskonfiguraatio on tarkoituksella rajoittava (vain localhost, vain system-näkymä). Se on turvallinen lähtökohta, mutta se pitää avata hallitusti.
- SNMP-liikenne kulkee hallintaverkon (172.20.20.0/24) kautta, kuten viikon 1 havainto hallintaliikenteestä ennakoi.
