# Viikko 03: Infrastruktuurin monitorointi Prometheuksella ja Grafanalla

Oppimateriaali palvelin- ja verkkoinfrastruktuurin monitorointiin.

## Oppimistavoitteet

Tämän materiaalin opiskeltuasi osaat:

- Selittää Prometheus-ekosysteemin keskeiset komponentit.
- Kuvata datan kulun Node Exporterilta Prometheus-palvelimelle.
- Selittää, miten Grafana hyödyntää Prometheus-dataa.
- Tunnistaa keskeiset palvelin- ja verkkoinfrastruktuurin metriikat.
- Ymmärtää aikasarjadatan peruskäsitteet.
- Kirjoittaa yksinkertaisia PromQL-kyselyitä.
- Tulkita metriikoiden muutoksia infrastruktuurin näkökulmasta.
- Valmistautua rakentamaan dashboardeja ja analysoimaan dataa laboratoriossa.

---

## 1. Johdanto monitorointiin

Nykyaikaiset palvelut, pilviympäristöt ja verkot ovat monimutkaisia kokonaisuuksia, joiden toimintaa on seurattava jatkuvasti. Pelkkä palvelun tai laitteen toiminnassa oleminen ei riitä. Ylläpitäjän täytyy ymmärtää myös, **miten hyvin** palvelu toimii, kuinka kuormittunut se on ja millaisia muutoksia ympäristössä tapahtuu.

Huomio:

Monitoroinnin tarkoitus ei ole kerätä mahdollisimman paljon dataa. Tavoitteena on havaita ongelmat ennen kuin ne näkyvät käyttäjille.

### Miksi monitorointia tarvitaan?

- CPU-kuorma nousee epätavallisen korkeaksi.
- Muisti alkaa loppua palvelimelta.
- Levytila täyttyy.
- Verkkoliikenteessä tapahtuu poikkeava kasvu.
- Palvelu lakkaa vastaamasta verkossa.
- Suorituskyky heikkenee vähitellen ajan myötä.

### Esimerkki käytännöstä

Kuvitellaan yrityksen verkkopalvelin, joka toimii normaalisti noin 20 % CPU-kuormalla. Eräänä päivänä kuorma nousee äkillisesti 95 prosenttiin.

Ilman monitorointia ongelma huomataan vasta käyttäjien valittaessa hitaudesta. Monitoroinnin avulla ylläpitäjä voi havaita ongelman välittömästi ja ryhtyä selvittämään syytä.

---

## 2. Prometheus-ekosysteemin perusteet

### Mikä on Prometheus?

Prometheus on avoimen lähdekoodin monitorointijärjestelmä, joka on suunniteltu erityisesti palvelin-, pilvi- ja konttiympäristöjen valvontaan.

Prometheus kerää jatkuvasti metriikkadataa eri järjestelmistä ja tallentaa sen aikasarjatietokantaan.

### Exporterit

Prometheus ei yleensä kerää tietoa suoraan käyttöjärjestelmästä tai sovelluksesta, vaan käyttää exportereita.

Exporter on ohjelma, joka muuttaa järjestelmän tilatiedot Prometheuksen ymmärtämään muotoon.

### Node Exporter

Node Exporter on Linux-palvelimille tarkoitettu exporter.

Se tuottaa esimerkiksi:

- CPU-metriikoita
- Muistimetriikoita
- Levyjärjestelmän metriikoita
- Verkkoliikennemetriikoita
- Käyttöjärjestelmän tilatietoja

### Grafana

Grafana on visualisointityökalu.

Grafana ei kerää dataa itse, vaan hakee sen erilaisista datalähteistä, kuten Prometheuksesta, ja esittää tiedot helposti tulkittavina dashboardeina.

### Aikasarjatietokanta

Aikasarjatietokannassa jokainen mittaus sisältää:

- mitatun arvon
- ajanhetken

Esimerkiksi:

```
10:00 CPU = 12%
10:01 CPU = 15%
10:02 CPU = 18%
10:03 CPU = 14%
```

Tällaisesta datasta voidaan muodostaa kuvaajia ja trendejä.

### Pull-malli

Prometheus käyttää pull-mallia.

Tämä tarkoittaa sitä, että Prometheus hakee tiedot säännöllisin väliajoin exportereilta.

Vinkki:

Vastakohta on push-malli, jossa järjestelmät lähettävät tietonsa keskitetylle palvelulle.

---

## 3. Datan kulku laboratorioympäristössä

Kurssin laboratorioympäristössä monitorointidata kulkee seuraavasti:

```
+---------------------+
| Linux-palvelin      |
| Node Exporter       |
+----------+----------+
           |
           | HTTP /metrics
           v
+---------------------+
| Prometheus          |
| Time Series DB      |
+----------+----------+
           |
           | PromQL
           v
+---------------------+
| Grafana             |
| Dashboardit         |
+----------+----------+
           |
           v
        Käyttäjä
```

### Vaihe 1: Node Exporter tuottaa metriikat

Node Exporter kerää tietoja käyttöjärjestelmältä ja julkaisee ne HTTP-rajapinnan kautta.

### Vaihe 2: Prometheus hakee datan

Prometheus lukee metriikat säännöllisesti Node Exporterilta.

### Vaihe 3: Data tallennetaan

Prometheus tallentaa mittaukset omaan aikasarjatietokantaansa.

### Vaihe 4: Grafana hakee datan

Grafana käyttää Prometheus-palvelinta datalähteenään.

### Vaihe 5: Käyttäjä analysoi dataa

Grafana näyttää tiedot graafeina, mittareina ja taulukoina.

---

## 4. Metriikat ja aikasarjat

### Metric

Metric on yksittäinen mitattava suure.

Esimerkiksi:

```
node_cpu_seconds_total
```

### Label

Label on metriikan lisätieto.

```
node_cpu_seconds_total{cpu="0",mode="idle"}
```

### Sample

Sample on yksittäinen mittaus.

```
Aika: 10:30
Arvo: 12456
```

### Time Series

Time series eli aikasarja muodostuu useista samaan metriikkaan liittyvistä mittauksista ajan kuluessa.

### Tärkeitä metriikoita

#### CPU

```
node_cpu_seconds_total
```

Kertoo prosessorin kuormituksesta.

#### Muisti

```
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes
```

Kertovat kokonais- ja vapaan muistimäärän.

#### Levytila

```
node_filesystem_avail_bytes
node_filesystem_size_bytes
```

Kertovat levytilan käytöstä.

#### Verkko

```
node_network_receive_bytes_total
node_network_transmit_bytes_total
```

Kuvaavat verkkoliikenteen määrää.

---

## 5. PromQL-perusteet

PromQL on Prometheuksen kyselykieli, jolla dataa voidaan hakea ja analysoida.

### 1. Onko kohde tavoitettavissa?

```
up
```

Arvo 1 tarkoittaa, että kohde vastaa. Arvo 0 tarkoittaa, että kohde on tavoittamattomissa.

### 2. Kaikki CPU-metriikat

```
node_cpu_seconds_total
```

### 3. CPU-käyttöprosentti

```
100 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100
```

Kertoo kuinka suuri osa prosessorista on käytössä.

### 4. Vapaan muistin määrä

```
node_memory_MemAvailable_bytes
```

### 5. Muistin käyttöprosentti

```
100 - (
node_memory_MemAvailable_bytes
/
node_memory_MemTotal_bytes
* 100
)
```

### 6. Levyn vapaa tila

```
node_filesystem_avail_bytes
```

### 7. Levyn käyttöprosentti

```
100 - (
node_filesystem_avail_bytes
/
node_filesystem_size_bytes
* 100
)
```

### 8. Vastaanotettu verkkoliikenne

```
rate(node_network_receive_bytes_total[5m])
```

### 9. Lähetetty verkkoliikenne

```
rate(node_network_transmit_bytes_total[5m])
```

### 10. Keskimääräinen CPU-kuorma

```
avg(rate(node_cpu_seconds_total[5m]))
```

### PromQL:n hyöty laboratoriossa

Ennen dashboardin rakentamista on tärkeää ymmärtää, mitä dataa kysely palauttaa. Dashboard on lopulta vain visualisointi PromQL-kyselyjen tuloksista.

---

## 6. Grafana yleiskuvana

### Mikä on Grafana?

Grafana on visualisointityökalu, jolla Prometheuksen data voidaan muuttaa helposti tulkittaviksi näkymiksi.

### Mikä on dashboard?

Dashboard on kokoelma visualisointeja, jotka näyttävät esimerkiksi:

- CPU-kuorman
- Muistin käytön
- Verkkoliikenteen
- Levytilan käytön

### Tyypillisiä visualisointeja

- Line chart
- Bar chart
- Gauge
- Stat panel
- Table

Muista:

Tämän viikon laboratorioharjoituksessa rakennat ensimmäisen Grafana-dashboardisi itse.

---

## 7. Datan tulkinta ja analysointi

Monitoroinnin tärkein tehtävä ei ole datan katselu vaan ilmiöiden ymmärtäminen.

### Tilanne 1: CPU nousee 20 % → 95 %

- Mikä prosessi kuormittaa palvelinta?
- Onko kyse normaalista kuormasta?
- Onko järjestelmä edelleen käyttökelpoinen?

### Tilanne 2: Verkkoliikenne kasvaa voimakkaasti

- Onko käynnissä tiedostonsiirto?
- Onko reitityksessä tapahtunut muutos?
- Voiko kyseessä olla virhetilanne?

### Tilanne 3: Muistin käyttö kasvaa jatkuvasti

- Onko kyse välimuistista?
- Onko sovelluksessa muistivuoto?
- Kasvaako käyttö jatkuvasti ilman palautumista?

### Tilanne 4: Palvelin katoaa monitoroinnista

```
up == 0
```

Tällöin ylläpitäjän tulee selvittää:

- Onko palvelin käynnissä?
- Toimiiko verkko?
- Onko Node Exporter käynnissä?
- Toimiiko Prometheus-konfiguraatio?

---

## 8. Yhteenveto

Tässä materiaalissa opit:

- Miten Prometheus-ekosysteemi toimii.
- Miten Node Exporter tuottaa metriikoita.
- Miten Prometheus kerää ja tallentaa dataa.
- Mitä aikasarjadata tarkoittaa.
- Miten PromQL-kyselyjä käytetään.
- Miten metriikoita voidaan analysoida käytännön tilanteissa.
- Miten Grafana hyödyntää Prometheus-dataa.

---

## 9. Itsearviointi

### Monivalintakysymykset

1. Mikä komponentti kerää metriikat Linux-palvelimelta?
  - A) Grafana
  - B) Node Exporter
  - C) Docker
  - D) OSPF
2. Mikä on Prometheuksen tehtävä?
  - A) Reitittää liikennettä
  - B) Kerätä ja tallentaa metriikoita
  - C) Tarjota SSH-yhteyksiä
  - D) Hallita kontteja
3. Mitä arvo up=0 tarkoittaa?
  - A) Kohde ei vastaa
  - B) CPU on kuormittunut
  - C) Levytila on täynnä
  - D) Muisti on vähissä
4. Mikä on aikasarja?
5. Mikä on label?
6. Mikä on exporter?
7. Mitä pull-malli tarkoittaa?
8. Mikä on PromQL?
9. Mikä on dashboard?
10. Mikä on Grafanan rooli?

### Pohdintakysymykset

1. Mitä hyötyä monitoroinnista on verkkoylläpidolle?
2. Mitä ongelmia CPU-käytön pitkäaikainen nousu voi aiheuttaa?
3. Miten verkkoliikenteen visualisointi auttaa ylläpitäjää?
4. Miksi historiadata on tärkeää häiriötilanteiden selvittämisessä?
5. Miten monitorointia voitaisiin hyödyntää pilviympäristöissä?

---

## 10. Valmistautuminen viikkoharjoitukseen

Tämän viikon laboratoriossa rakennat monitorointiympäristön visualisointinäkymän ja analysoit järjestelmän käyttäytymistä kuormituksen aikana.

### Laboratorion päävaiheet

1. Varmista metriikoiden kerääntyminen Prometheukseen.
2. Tutki metriikoita PromQL-kyselyillä.
3. Rakenna Grafana-dashboard.
4. Käynnistä kuormageneraattori.
5. Seuraa ympäristön muutoksia reaaliaikaisesti.
6. Analysoi CPU-, muisti-, levy- ja verkkometriikoita.
7. Kirjaa havainnot ja johtopäätökset.

### Tarkistuslista

- ☐ Ymmärrän Prometheuksen tehtävän.
- ☐ Ymmärrän Node Exporterin tehtävän.
- ☐ Tiedän miten pull-malli toimii.
- ☐ Osaan lukea palvelimen metriikoita.
- ☐ Tunnistan tärkeimmät CPU-, muisti-, levy- ja verkkometriikat.
- ☐ Osaan kirjoittaa perus-PromQL-kyselyitä.
- ☐ Ymmärrän miten Grafana käyttää Prometheus-dataa.
- ☐ Osaan tulkita metriikoiden muutoksia.
- ☐ Olen valmis rakentamaan dashboardin ja analysoimaan mittaustuloksia.

---

## Lisämateriaalia ja suositeltavat lähteet

Seuraavat lähteet täydentävät viikon oppimateriaalia ja auttavat syventämään osaamista Prometheuksesta, PromQL:stä ja Grafanasta. Suosittelen erityisesti virallisia dokumentaatioita, sillä niitä käytetään laajasti myös työelämässä. Prometheus tarjoaa aikasarjadatan keruun ja käsittelyn, kun taas Grafana keskittyy datan visualisointiin. [prometheus.io](https://prometheus.io/docs/introduction/overview/) ja [grafana.com](https://grafana.com/docs/grafana/latest/introduction/).

### Viralliset dokumentaatiot

#### Prometheus Documentation

Prometheuksen virallinen dokumentaatio sisältää arkkitehtuurikuvaukset, käyttöönotto-ohjeet, PromQL-dokumentaation sekä exporter-ekosysteemin kuvaukset. Prometheus perustuu aikasarjamalliin, jossa metriikat tallennetaan aikaleiman ja tunnisteiden (label) kanssa.

[Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)

#### Prometheus Getting Started

Käytännön opas Prometheuksen asentamiseen, konfigurointiin sekä ensimmäisten metriikoiden keräämiseen. Materiaalissa käydään läpi myös scrape-konfiguraatioiden perusteet.

[Prometheus Getting Started](https://prometheus.io/docs/prometheus/latest/getting_started/)

#### PromQL Querying Basics

Virallinen PromQL-opas sisältää kyselykielen syntaksin, tietotyypit, suodattimet, aggregoinnit sekä yleiset funktiot. Tämä on tärkeä lähde laboratorioviikon PromQL-osuuden tueksi.

[PromQL Querying Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)

#### Grafana Documentation

Grafanan virallinen dokumentaatio sisältää dashboardien rakentamisen, visualisointityypit, muuttujat, datalähteet ja hälytykset. Grafana tukee useita datalähteitä, joista tässä opintojaksossa käytetään Prometheusta.

[Grafana Documentation](https://grafana.com/docs/)

#### Grafana + Prometheus Tutorial

Grafanan oma harjoitusopas Prometheus-datan visualisointiin. Sisältää käytännön dashboard-esimerkkejä palvelinmonitoroinnista.

[Get Started with Grafana and Prometheus](https://grafana.com/docs/grafana/latest/fundamentals/getting-started/first-dashboards/get-started-grafana-prometheus/)

### Node Exporter

#### Node Exporter

Node Exporter on Linux-palvelimien yleisimmin käytetty Prometheus-exporter. Dokumentaatiossa esitellään kerättävät metriikat sekä käyttöönoton perusteet. Exporter tuottaa esimerkiksi CPU-, muisti-, levy- ja verkkokäyttöön liittyviä mittauksia, joita Prometheus kerää.

[Node Exporter Documentation](https://github.com/prometheus/node_exporter)

### Harjoittele PromQL:ää

#### PromQL Cheat Sheet

Hyvä käytännön muistilista yleisimpiin PromQL-kyselyihin.

[PromLabs PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

#### PromLabs Interactive Training

Interaktiivinen selainpohjainen ympäristö PromQL:n harjoitteluun ilman omaa asennusta.

[PromLabs Training](https://training.promlabs.com/training/introduction-to-promql/)

### Dashboard-esimerkkejä

#### Grafana Dashboard Library

Grafana-yhteisön ylläpitämä kirjasto, josta löytyy tuhansia valmiita dashboardeja. Etsi esimerkiksi:

- Node Exporter Full
- Linux Hosts Metrics
- Prometheus Overview

Näitä voi käyttää inspiraationa laboratorion dashboardien suunnittelussa.

[Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)

### Videomateriaalit

#### Grafana Labs YouTube

Viralliset videot dashboardien rakentamisesta, PromQL-kyselyistä ja observability-ajattelusta.

[Grafana Labs YouTube](https://www.youtube.com/@grafana)

#### CNCF YouTube

Cloud Native Computing Foundationin kanava sisältää runsaasti Prometheus- ja monitorointiaiheisia konferenssiesityksiä.

[CNCF YouTube](https://www.youtube.com/@CloudNativeFdn)

### Syventävää luettavaa

#### Prometheus Architecture Overview

Syvällisempi kuvaus Prometheuksen komponenteista, tietomallista ja arkkitehtuurista. Dokumentaatio kuvaa esimerkiksi pull-mallin, exporterit, Alertmanagerin sekä visualisointikomponentit.

[Prometheus Architecture](https://prometheus.io/docs/introduction/overview/)

#### Grafana Fundamentals

Hyvä kokonaisuus Grafanan peruskäytöstä, dashboardien rakentamisesta sekä monitorointiratkaisujen suunnittelusta.

[Grafana Fundamentals](https://grafana.com/tutorials/grafana-fundamentals/)
