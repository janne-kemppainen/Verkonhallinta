### Verkkotelemetria, Prometheus ja Grafana

### Johdanto

Modernien tietoverkkojen ja palveluiden ylläpidossa ei enää riitä, että tiedetään palvelimen olevan käynnissä. Ylläpitäjän on pystyttävä vastaamaan kysymyksiin:

- Miksi palvelu hidastui?

- Milloin ongelma alkoi?

- Oliko CPU, muisti, levy vai verkko kuormittunut?

- Onko ongelma yksittäinen vai toistuva?

Näihin kysymyksiin vastataan telemetrian avulla.

#### 1. Mitä on telemetria?

Telemetria tarkoittaa järjestelmän automaattisesti tuottamaa mittausdataa.

Esimerkkejä:

| Mittari | Kuvaus |
| --- | --- |
| CPU-käyttö | Prosessorin kuormitus |
| Muistin käyttö | RAM-muistin käyttöaste |
| Levytila | Käytetty ja vapaa levytila |
| Verkkoliikenne | Lähetetty ja vastaanotettu data |
| Vasteaika | Palvelun suorituskyky |

Telemetrian avulla voidaan havaita:

- suorituskykyongelmia

- kapasiteetin loppumista

- poikkeavaa käyttäytymistä

- palvelukatkoja

#### 2. Monitoring ja Observability

Monitoring

Monitoring vastaa kysymykseen:

Onko järjestelmä kunnossa?

Esimerkkejä:

- Palvelin vastaa pingiin.

- CPU on alle 80 %.

- Levyllä on tilaa.

Observability

Observability vastaa kysymykseen:

Miksi järjestelmä ei ole kunnossa?

Observability hyödyntää useita tietolähteitä:

- Metrics

- Logs

- Traces

Tällä viikolla keskitymme erityisesti metrics-dataan.

#### 3. Telemetriasignaalit

Metrics

Numeerisia mittauksia ajan funktiona.

Esimerkiksi:

- CPU %

- Muistin käyttö %

- Verkkoliikenne

Logs

Tapahtumalokeja.

Esimerkiksi:

1 2025-09-01 12:30:00 ERROR Database connection failed

Traces

Kuvaavat yhden tapahtuman etenemistä järjestelmässä.

Esimerkiksi:

1 User Request

2 └─ Web Server

3 └─ API

4 └─ Database

#### 4. Prometheus-ekosysteemi

Harjoituksessa käytetään kolmea työkalua.

Node Exporter

Kerää käyttöjärjestelmän mittarit.

Esimerkiksi:

- CPU

- Muisti

- Levy

- Verkko

Node Exporter julkaisee mittarit osoitteessa:

1 http://localhost:9100/metrics

#### Prometheus

Prometheus:

1. Kerää mittarit

2. Tallentaa ne

3. Mahdollistaa kyselyt PromQL-kielellä

Prometheus käyttää pull-mallia:

1 Prometheus ---> Node Exporter

2 HTTP GET /metrics

#### Grafana

Grafana visualisoi mittarit.

Esimerkiksi:

1 CPU Usage %

2 Memory Usage %

3 Disk Usage %

4 Network Receive

5 Network Transmit

### 5. Miten data kulkee?

1 Linux-palvelin

2 │

3 ▼

4 Node Exporter

5 │

6 ▼

7 Prometheus

8 │

9 ▼

10 Grafana

11 │

12 ▼

13 Ylläpitäjä

### 6. Prometheus-metriikat

Esimerkki:

1 node_memory_MemTotal_bytes

Mittari kertoo palvelimen kokonaismuistin.

Esimerkki:

1 node_cpu_seconds_total

Mittari kertoo kuinka paljon aikaa CPU on viettänyt eri tiloissa.

### 7. PromQL-perusteet

PromQL on Prometheuksen kyselykieli.

Tarkista että kohde toimii

1 up

Tulos:

1 1 = toimii

2 0 = ei vastaa

#### CPU-käyttö

1 100 - (

2 avg by(instance)

3 (rate(node_cpu_seconds_total{mode="idle"}[5m]))

4 * 100

5 )

#### Ajatus:

1 CPU käyttö = 100 % - idle %

Jos CPU on joutokäynnillä 80 % ajasta:

1 100 - 80 = 20 %

CPU-käyttö on 20 %.

#### Muistin käyttö

1 (

2 node_memory_MemTotal_bytes -

3 node_memory_MemAvailable_bytes

4 )

5 /

6 node_memory_MemTotal_bytes

7 * 100

Laskee käytössä olevan muistin osuuden.

#### Levytilan käyttö

1 100 -

2 (

3 node_filesystem_avail_bytes

4 /

5 node_filesystem_size_bytes

6 * 100

7 )

Laskee käytössä olevan levytilan.

#### Verkkoliikenne

Saapuva liikenne:

1 rate(node_network_receive_bytes_total[5m])

Lähtevä liikenne:

1 rate(node_network_transmit_bytes_total[5m])

Näyttää liikennemäärän sekunnissa.

### 8. Grafana-dashboardin suunnittelu

Hyvä dashboard vastaa kysymykseen:

Onko palvelin kunnossa?

Suositeltu järjestys:

1 +----------------------+

2 | CPU Usage % |

3 +----------------------+

4

5 +----------------------+

6 | Memory Usage % |

7 +----------------------+

8

9 +----------------------+

10 | Disk Usage % |

11 +----------------------+

12

13 +----------------------+

14 | Network Receive |

15 +----------------------+

16

17 +----------------------+

18 | Network Transmit |

19 +----------------------+

### 9. Kuormitustestaus

Monitoroinnin hyöty näkyy vasta, kun järjestelmään aiheutetaan kuormaa.

CPU-kuormitus

1 stress-ng --cpu 4 --timeout 60s

Odota:

- CPU Usage nousee

- Kuormitus palautuu testin jälkeen

Levykuormitus

1 dd if=/dev/zero of=testfile.img bs=1M count=500

Odota:

- levytilan käyttö kasvaa

- levy-I/O lisääntyy

10. Mittareiden tulkinta

Tilanne 1

CPU 95 %

Muisti 20 %

Verkko normaali

Johtopäätös:

Prosessorikuormitteinen sovellus.

Tilanne 2

CPU normaali

Muisti 95 %

Johtopäätös:

Muistipula tai muistivuoto.

Tilanne 3

CPU normaali

Muisti normaali

Verkkoliikenne erittäin korkea

Johtopäätös:

Suuri liikennemäärä tai mahdollinen hyökkäys.

### 11. SNMP vs Prometheus

| Ominaisuus | SNMP | Prometheus |
| --- | --- | --- |
| Tiedonkeruu | Pollaus OID-arvoista | HTTP scrape |
| Käyttöönotto | Verkkolaitteet | Palvelimet ja sovellukset |
| Datamalli | MIB/OID | Aikasarjat |
| Visualisointi | Erillinen työkalu | Grafana |
| Pilviympäristöt | Rajallinen | Erinomainen |
| Kyselykieli | Ei varsinaista | PromQL |

### 12. Yleisimmät ongelmat

Node Exporter ei vastaa

Tarkista:

1 curl http://localhost:9100/metrics

Target on DOWN

Tarkista:

1 Prometheus → Status → Targets

Grafana ei löydä Prometheusta

Tarkista URL:

1 http://prometheus:9090

Dashboardissa ei näy dataa

Tarkista:

- metricin nimi

- aikaväli

- PromQL-kysely

### Yhteenveto

Tämän materiaalin jälkeen sinun pitäisi ymmärtää:

✅ mitä telemetria tarkoittaa

✅ mitä monitoring ja observability ovat

✅ miten Node Exporter toimii

✅ miten Prometheus kerää mittareita

✅ miten PromQL-kyselyitä käytetään

✅ miten Grafana-dashboard rakennetaan

✅ miten kuormitustestin vaikutuksia tulkitaan

✅ miten Prometheus eroaa SNMP-pohjaisesta monitoroinnista

Kun hallitset nämä asiat, pystyt suorittamaan viikon 3 harjoituksen itsenäisesti sekä ymmärtämään, mitä mittarit todella kertovat järjestelmän toiminnasta.
