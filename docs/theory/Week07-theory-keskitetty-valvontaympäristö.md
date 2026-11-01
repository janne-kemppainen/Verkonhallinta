# Enterprise Monitoring, dashboardit, SLA ja Capacity Planning

Yrityksen valvonta ei ole vain yksittäisten palvelinten ping-tarkistuksia. Enterprise Monitoring tarkoittaa organisaation palveluiden, verkkolaitteiden, sovellusten ja niiden riippuvuuksien suunnitelmallista seurantaa. Tavoitteena on havaita palveluhäiriöt ajoissa, ymmärtää niiden vaikutus käyttäjiin ja tehdä päätöksiä luotettavan historiatiedon perusteella.

Tässä materiaalissa käytämme esimerkkinä kurssin Zabbix-ympäristöä. Sen hosteihin kuuluvat esimerkiksi `web1`, `db1` ja `branch-client`. Zabbixiin kerätyt mittarit, triggerit, palvelut ja dashboardit muodostavat yhdessä valvonnan kokonaisuuden.

## Oppimistavoitteet

Materiaalin jälkeen osaat:

- kuvata yritystason valvonnan tavoitteet ja Zabbixin roolin siinä
- selittää Zabbixin palvelimen, tietokannan, frontendin, agentin ja proxyn roolit
- erottaa hostin, itemin, triggerin, eventin, actionin ja templaten toisistaan
- suunnitella eri käyttäjille hyödyllisen dashboardin
- selittää SLA:n, saatavuuden ja palvelukatkon vaikutuksen
- hyödyntää mittaushistoriaa kapasiteettitarpeiden ennakointiin
- erottaa yksittäisen hälytyksen palvelun tilasta ja liiketoimintavaikutuksesta

---

## 1. Enterprise Monitoring

### Mitä yritystason valvonta tarkoittaa?

Yritysympäristössä valvonta suunnitellaan palveluiden näkökulmasta. Yksittäinen palvelin voi olla käynnissä, vaikka käyttäjä ei silti pysty käyttämään palvelua. Esimerkiksi verkkosovellus tarvitsee toimivan web-palvelimen, tietokannan, DNS:n ja verkkoyhteyden. Valvonnan on siksi seurattava sekä komponentteja että niiden välisiä riippuvuuksia.

| Valvonnan taso | Zabbix-esimerkki | Kysymys, johon se vastaa |
| --- | --- | --- |
| Laite | Host `web1` ja Zabbix agent | Onko palvelin tavoitettavissa? |
| Resurssi | CPU-, muisti-, levy- ja verkkoliikenne-itemit | Onko jokin resurssi loppumassa tai kuormittumassa? |
| Palvelu | HTTP-tarkistus ja palvelun tila | Toimiiko käyttäjälle näkyvä verkkopalvelu? |
| Liiketoiminta | Palvelun SLA ja häiriöaika | Täyttyykö palvelulle luvattu palvelutaso? |

### Zabbixin keskeiset osat

- Zabbix server käsittelee kerättyjä arvoja, arvioi triggereitä, tallentaa tapahtumia ja tuottaa hälytyksiä.
- Zabbix agent kerää hostin käyttöjärjestelmä- ja sovelluskohtaisia tietoja. Agentti voi olla aktiivinen tai passiivinen tiedonkeruun asetuksista riippuen.
- SNMP mahdollistaa esimerkiksi kytkinten, reitittimien ja tulostimien valvonnan ilman Zabbix-agenttia.
- Zabbix proxy kerää tietoa etäverkossa ja välittää sen keskitetylle palvelimelle. Proxy sopii suuriin tai yhteyksiltään rajattuihin ympäristöihin.
- Template kokoaa uudelleenkäytettäviä itemeitä, trigger-ehtoja ja grafiikoita, jolloin hostien asetukset pysyvät yhdenmukaisina.

Zabbix-palvelin käyttää tietokantaa historiatietojen, tapahtumien, asetusten ja käyttäjien tietojen säilyttämiseen. Web-käyttöliittymä on erillinen frontend, jonka kautta ylläpitäjä määrittelee hostit ja valvonnan, tarkastelee mittareita, ongelmia ja dashboardeja sekä hallitsee käyttäjiä. Palvelimen ja frontendin ei tarvitse sijaita samalla koneella, vaikka pienessä laboratorioympäristössä se on tavallista.

### Miten Zabbix kerää tietoa?

Agentti on hyödyllinen palvelimissa, joissa tarvitaan käyttöjärjestelmän sisäisiä mittareita. Verkkolaitteissa käytetään usein SNMP:tä, koska laitteessa ei yleensä voida ajaa Zabbix-agenttia. Lisäksi Zabbix voi käyttää esimerkiksi HTTP-tarkistuksia, TCP-porttitestejä, lokien valvontaa, komentojen palauttamia arvoja ja muita integraatioita. Menetelmä valitaan sen mukaan, mitä halutaan todistaa: ping kertoo saavutettavuudesta, mutta HTTP-tarkistus kertoo paremmin käyttäjän näkemän verkkopalvelun toiminnasta.

| Menetelmä | Tyypillinen käyttökohde | Huomio |
| --- | --- | --- |
| Zabbix agent | Linux- ja Windows-palvelimen CPU, muisti, levyt ja prosessit | Voi olla aktiivinen tai passiivinen |
| SNMP | Kytkimet, reitittimet, tulostimet ja UPS-laitteet | Rajoita yhteisömerkkijonot ja suosi SNMPv3:a, kun laite tukee sitä |
| HTTP- ja TCP-tarkistus | Web-palvelun vastaus ja portin saavutettavuus | Testaa palvelua käyttäjän näkökulmasta |
| Lokit ja integraatiot | Sovellusvirheet, pilvipalvelut ja ulkoiset järjestelmät | Tarkista, että lähdedata on luotettavaa ja riittävän yksilöivää |

### Arkkitehtuuri käytännössä

```
Valvottavat kohteet
	|-- Zabbix agent (palvelimet ja työasemat)
	|-- SNMP (kytkimet, reitittimet ja muut verkkolaitteet)
	|-- HTTP, TCP, lokit ja integraatiot
	           |
	           v
Zabbix proxy (valinnainen etäverkossa)
           |
           v
Zabbix server + tietokanta
           |
           v
Web-käyttöliittymä, dashboardit, raportit ja hälytykset
```

Proxy ei ole pakollinen eikä se korvaa Zabbix-palvelinta. Se kerää valvontatietoa lähellä etäkohteita ja välittää sen palvelimelle, mikä vähentää etäyhteyden herkkyyttä ja voi pienentää liikennettä. Proxy on hyödyllinen esimerkiksi haarakonttorissa, pilviympäristössä tai verkossa, josta keskitetty palvelin ei saa suoria yhteyksiä kaikkiin laitteisiin.

### Zabbixin peruskäsitteet

Zabbixin asetukset kannattaa ymmärtää tiedon kulkuna:

1. Host on valvottava laite, palvelin tai muu kohde. Hostilla on nimi, osoite ja yhteysmenetelmä.
2. Item määrittelee yhden kerättävän arvon, kuten vapaan levytilan, HTTP-vastausajan tai verkkoliitännän liikenteen.
3. Trigger arvioi itemin arvoja ja kuvaa poikkeaman, esimerkiksi vapaan levytilan alittumisen.
4. Event syntyy, kun triggerin ehto muuttuu ongelmaksi tai palautuu normaaliksi.
5. Action määrittelee, mitä tapahtumalle tehdään, kuten ilmoitus sähköpostilla tai tiketöintijärjestelmään.
6. Template kokoaa uudelleenkäytettäviä itemeitä, triggereitä, discovery-sääntöjä ja visualisointeja.

```
Host -> item -> trigger -> event -> action
                       |
                       +--> dashboard, historia ja raportit
```

Esimerkiksi item voi kerätä `db1`-palvelimen vapaan levytilan prosenttiosuuden. Trigger muuttaa tilanteen ongelmaksi, jos arvo jää liian pieneksi. Action ilmoittaa ylläpitäjälle ja dashboard näyttää ongelman. Kun arvo palautuu normaaliksi, Zabbix muodostaa palautumistapahtuman. Kynnysarvoa ei pidä valita irrallaan palvelusta: tietokannan levytilalle tarvitaan usein enemmän ennakkoaikaa kuin väliaikaisesti käytetylle työasemalevylle.

### Turvallisuus ja luotettavuus

- Käytä Zabbix-agentin ja palvelimen väliseen liikenteeseen salattua yhteyttä, kun ympäristö ja versio sen mahdollistavat.
- Anna agentille ja SNMP-valvonnalle vain tarvittavat oikeudet. Älä käytä oletustunnuksia tai jaa samaa ylläpitotunnusta kaikille.
- Valvo myös Zabbixin omaa toimintaa: palvelimen, tietokannan, proxyn ja agenttien saatavuutta sekä tiedonkeruun viivettä.
- Suunnittele tietokannan varmistukset ja säilytysajat. Pitkä historia on hyödyllinen kapasiteettisuunnittelussa, mutta se kasvattaa tallennustilan tarvetta.

### Yksinkertainen käyttöönoton polku

1. Asenna Zabbix server, tietokanta ja web-frontend tuetun käyttöjärjestelmän sekä Zabbixin version dokumentaation mukaisesti. Zabbix-palvelin ei ole sama asia kuin selainkäyttöliittymä.
2. Varmista palvelimen, tietokannan ja frontendin toiminta sekä vaihda oletustunnukset.
3. Lisää yksi host ja valitse sille sopiva interface sekä template. Aloita yhdestä palvelimesta tai verkkolaitteesta, jotta tiedon kulku on helppo todentaa.
4. Tarkista, että itemit saavat arvoja. Tutki ongelman sattuessa ensin hostin yhteys, agentin tai SNMP:n asetukset ja viimeisenä triggerin kynnys.
5. Lisää vasta sen jälkeen tarkoituksenmukaiset triggerit, actionit, dashboardit ja käyttäjäoikeudet.

Asennusohjeet vaihtelevat Zabbixin version, käyttöjärjestelmän, tietokannan ja web-palvelimen mukaan. Ajantasainen lähtökohta on [Zabbixin virallinen asennusohje](https://www.zabbix.com/documentation/current/en/manual/installation/getting_zabbix). Laboratoriossa kannattaa dokumentoida vähintään käytetty versio, hostien nimet, yhteysmenetelmät, templaatit ja tehdyt kynnysarvot.

### Mittaustiedosta toiminnaksi

Valvonnan ketju alkaa mittarista eli itemistä. Zabbix kerää esimerkiksi `web1`-hostin vapaan levytilan minuutin välein. Trigger arvioi, onko arvo huolestuttava. Kun ehto täyttyy, syntyy ongelmatapahtuma, joka voidaan näyttää dashboardilla tai välittää vastuuhenkilölle.

> Hyvä hälytys kertoo, mikä palvelu on vaarassa, kuinka vakava tilanne on ja kenen tulee toimia. Pelkkä suuri määrä hälytyksiä ei tarkoita hyvää valvontaa.

**Lähteet ja lisämateriaali:**

- [Zabbixin keskeiset prosessit ja komponentit](https://www.zabbix.com/documentation/current/en/manual/concepts)
- [Zabbix-agentti sekä aktiiviset ja passiiviset tarkistukset](https://www.zabbix.com/documentation/current/en/manual/concepts/agent)
- [SNMP-valvonnan määrittely Zabbixissa](https://www.zabbix.com/documentation/current/en/manual/config/items/itemtypes/snmp)
- [Zabbix proxyn toimintaperiaate](https://www.zabbix.com/documentation/current/en/manual/concepts/proxy)
- [Templatet ja niiden käyttäminen hosteilla](https://www.zabbix.com/documentation/current/en/manual/config/templates)
- [Triggerien logiikka ja tilat](https://www.zabbix.com/documentation/current/en/manual/config/triggers) sekä [action-toiminnot ja ilmoitukset](https://www.zabbix.com/documentation/current/en/manual/config/notifications/action)

## 2. Dashboardit

### Dashboard on päätöksenteon näkymä

Dashboard kokoaa tärkeimmät tilatiedot samaan näkymään. Sen tehtävä ei ole näyttää kaikkia Zabbixin keräämiä arvoja, vaan auttaa tiettyä käyttäjää vastaamaan olennaisiin kysymyksiin nopeasti. Ylläpitäjä tarvitsee usein tarkat hosti- ja mittaritiedot, kun taas palveluvastaava tarvitsee yleiskuvan palveluiden tilasta ja SLA:n toteutumisesta.

| Näkymän käyttäjä | Esimerkkejä sisällöstä | Tavoite |
| --- | --- | --- |
| Verkon ylläpitäjä | Hostien saavutettavuus, SNMP-liikenne, porttien tila ja ongelmat | Rajata verkkohäiriö nopeasti |
| Palvelimen ylläpitäjä | CPU, muisti, levytila, kuorma ja käynnissä olevat triggerit | Löytää resurssiongelman syy |
| Palveluvastaava | Palveluiden tila, saatavuustrendi, avoimet vakavat ongelmat ja SLA | Arvioida käyttäjävaikutusta ja palvelutasoa |

### Kurssin Zabbix-dashboard

Kurssin harjoituksessa dashboardin nimi on `Golden Topology Status`. Siinä voidaan näyttää esimerkiksi:

- hostien web1 , db1 ja branch-client saavutettavuus
- CPU-kuorma ja muistinkäyttö aikajanalla
- levytilan käyttö sekä levytilaan liittyvät aktiiviset ongelmat
- verkkoliikenne ja valittujen verkkoliitäntöjen tila
- vakavuusluokan mukainen ongelmalista

Dashboardin aikaväli on tärkeä: viimeiset 15 minuuttia auttaa tuoreessa vianrajauksessa, kun taas 7 tai 30 päivän näkymä paljastaa toistuvia kuormituspiikkejä ja kehityssuuntia. Aikaväli, yksiköt ja hostien nimet kannattaa pitää näkyvissä, jotta näkymän lukija pystyy tulkitsemaan arvoja oikein.

### Dashboardin suunnitteluperiaatteet

- Näytä ensin palvelun tila ja tärkeimmät ongelmat, vasta sitten yksityiskohtaiset mittarit.
- Ryhmittele mittarit palvelun tai hostiryhmän mukaan, älä satunnaiseen järjestykseen.
- Käytä selkeitä yksiköitä ja aikavälejä. Esimerkiksi prosentit, tavut sekunnissa ja sekunnit eivät ole keskenään vertailukelpoisia.
- Vältä tarpeettomia paneeleita. Jos näkymästä ei voi tehdä päätöstä tai aloittaa selvitystä, sen paikkaa kannattaa harkita.
- Linkitä yleiskuva yksityiskohtaisiin hosti- tai ongelmanäkymiin, jotta poikkeamaa voi tutkia seuraavaksi.

**Lähteet ja lisämateriaali:** [Zabbixin dashboardien, sivujen ja widgetien käyttöohje](https://www.zabbix.com/documentation/current/en/manual/web_interface/frontend_sections/dashboards) sekä [dashboard-widgetit](https://www.zabbix.com/documentation/current/en/manual/web_interface/frontend_sections/dashboards/widgets).

## 3. SLA ja palvelun saatavuus

### Mikä on SLA?

SLA (Service Level Agreement) on palvelutasosopimus. Se määrittää, millaista palvelutasoa palveluntarjoaja lupaa asiakkaalle tai organisaation sisäiselle käyttäjälle. SLA:ssa voidaan sopia esimerkiksi palvelun saatavuustavoitteesta, palveluajoista, mittaustavasta, huoltoikkunoista ja häiriötilanteiden vasteajoista.

SLA ei ole sama asia kuin yksittäisen palvelimen käyttöaste. Palvelu voi koostua useasta komponentista, ja sopimus koskee yleensä käyttäjälle näkyvää palvelua. Zabbixissa tätä voidaan mallintaa palveluilla ja niihin liittyvillä SLA-tavoitteilla. Tarkat valikot ja raportit riippuvat käytössä olevasta Zabbix-versiosta ja asetuksista.

### Saatavuuden laskeminen

Yksinkertainen saatavuusprosentti voidaan laskea näin:

```
Saatavuus (%) = (sovitun palveluajan kokonaiskesto - palvelukatkot) / sovitun palveluajan kokonaiskesto x 100
```

Jos palvelu on sovittu käytettäväksi koko 30 päivän ajan, jakson pituus on 43 200 minuuttia. Jos palvelukatkoja kertyy yhteensä 60 minuuttia:

```
(43 200 - 60) / 43 200 x 100 = noin 99,86 %
```

Laskenta on mielekäs vain, kun tiedetään, mitä palvelukatkoksi kutsutaan. Sopimus voi esimerkiksi rajata suunnitellut huoltotyöt laskennan ulkopuolelle tai määritellä, että katko alkaa vasta tietyn mittauskynnyksen jälkeen.

### SLA Zabbix-ympäristössä

1. Määritä ensin palvelu, jonka käyttäjä kokee kokonaisuutena, esimerkiksi web-palvelun HTTP-vastaus.
2. Valitse sitä kuvaavat mittarit ja triggerit. Pelkkä hostin ping-vastaus ei riitä todistamaan verkkosovelluksen toimivuutta.
3. Liitä palveluun sen toimintaa kuvaavat ongelmat ja määritä niiden vaikutus palvelun tilaan.
4. Määritä tavoite ja tarkastelujakso, kuten kuukauden saatavuustavoite.
5. Tarkastele SLA-raporttia yhdessä ongelmahistorian kanssa. Selvitä, milloin katko tapahtui ja mikä sen aiheutti.

Esimerkiksi `web1`-hostin agentti voi raportoida käyttöjärjestelmän tilaa, mutta erillinen HTTP-tarkistus kertoo, vastaako verkkopalvelu käyttäjälle. Jos `db1` ei ole käytettävissä, web-palvelu voi edelleen vastata mutta olla toiminnallisesti rikki. Palvelumallin tulee kuvata tämä riippuvuus.

> SLA-prosentti kertoo toteutuneesta palvelutasosta, mutta ei yksin selitä häiriön syytä, käyttäjämäärää tai liiketoimintavaikutusta. Nämä tiedot täydentävät raporttia.

**Lähteet ja lisämateriaali:** [Google SRE: SLI-, SLO- ja SLA-käsitteet](https://sre.google/sre-book/service-level-objectives/) sekä [Zabbixin virallinen käyttöohje](https://www.zabbix.com/documentation/current/en/manual), jonka palveluvalvonnan ja SLA-toimintojen tarkat valikot kannattaa tarkistaa käytössä olevan version mukaan.

## 4. Capacity Planning eli kapasiteetin suunnittelu

### Miksi kapasiteettia suunnitellaan?

Capacity Planning tarkoittaa tulevan resurssitarpeen arviointia nykyisten mittausten, kasvuoletusten ja palveluvaatimusten perusteella. Tarkoituksena on ehkäistä tilanteet, joissa CPU, muisti, levytila, verkkoyhteys tai jokin palvelun muu rajoite loppuu kesken.

Kapasiteettisuunnittelu ei ole sama kuin reagointi hälytykseen. Hälytys kertoo yleensä tämänhetkisestä tai lähiajan ongelmasta; kapasiteettisuunnittelu etsii pidemmän aikavälin kehitystä ja auttaa päättämään, milloin resursseja pitää kasvattaa tai käyttöä tehostaa.

### Mitä Zabbixista seurataan?

| Resurssi | Esimerkkimittari | Mahdollinen kasvun merkki |
| --- | --- | --- |
| CPU | Käyttöaste ja kuorma | Kuorma kasvaa viikko viikolta tai ruuhka-aikojen huiput pitenevät |
| Muisti | Käytetty ja vapaa muisti | Vapaa muisti vähenee jatkuvasti tai swap-käyttö lisääntyy |
| Levytila | Vapaa tila tavuina tai prosentteina | Lokit tai tietokanta kasvavat nopeammin kuin levytilaa vapautuu |
| Verkko | Liikenteen määrä ja liitännän nopeus | Liikenne lähestyy toistuvasti linkin käytettävissä olevaa kapasiteettia |
| Sovellus | Vastausaika, jonon koko tai pyyntömäärä | Vastausaika kasvaa kuorman mukana tai jonot eivät tyhjene |

### Trendin arviointi käytännössä

1. Varmista, että mittari kerätään riittävän pitkään ja mittauksen kattavuus on hyvä.
2. Tarkastele päivä-, viikko- ja kuukausitasoa. Erota tavallinen vuorokausivaihtelu pysyvästä kasvusta.
3. Vertaa keskiarvon lisäksi huippuarvoja ja niiden kestoa. Lyhyt piikki ja tuntikausia jatkuva korkea käyttö ovat eri riskejä.
4. Arvioi kasvunopeus ja suhteuta se ennustettuun palvelun käyttöön.
5. Määritä toimenpideraja ennen kuin kapasiteetti loppuu. Jätä tilaa huippukuormalle, kasvulle ja muutoksille.

Yksinkertainen lineaarinen arvio voidaan tehdä vertaamalla vapaan levytilan muutosta ajan kuluessa. Jos `db1`-palvelimen tietokanta kasvaa keskimäärin 12 GB kuukaudessa ja vapaata tilaa on 60 GB, nykyinen vapaa tila riittäisi karkeasti viideksi kuukaudeksi samalla kasvuvauhdilla. Arvio ei huomioi kasvun kiihtymistä, varmuuskopioita eikä turvallisuusvaraa, joten se on suunnittelun lähtökohta, ei lupaus.

### Raja-arvot ja ennusteet

Kiinteä trigger, kuten levyn vapaan tilan alittuminen 20 prosenttiin, on helppo ymmärtää ja toimii suojarajana. Se ei kuitenkaan kerro, kuinka nopeasti levy täyttyy. Trendin perusteella muodostettu ennuste voi varoittaa aiemmin, mutta ennuste riippuu mittaushistoriasta ja oletuksesta, että aiempi kehitys jatkuu. Käytä siksi kiinteitä rajoja ja ennusteita toisiaan täydentävinä, älä toistensa korvikkeina.

### Capacity Planning -esimerkki: db1

Oletetaan, että Zabbix-historia näyttää `db1`-palvelimen levytilan vähenevän tasaisesti ja CPU-huippujen toistuvan arkipäivisin. Ylläpitäjä tarkistaa ensin, johtuuko levyn kasvu tietokannasta, lokituksesta vai väliaikaisista tiedostoista. Sen jälkeen hän arvioi kasvun jatkumista, asettaa ennakkovaroituksen ja sopii kapasiteetin lisäyksestä ennen kuin vapaa tila alittaa kriittisen rajan.

CPU:n kohdalla keskiarvo voi näyttää terveeltä, vaikka palvelu hidastuu päivittäisen ruuhkatunnin aikana. Dashboardin pidempi aikaväli auttaa näkemään toistuvat huiput. Päätös voi olla resurssien lisääminen, sovelluksen optimointi tai kuorman siirtäminen. Mittari näyttää oireen; syyn selvittäminen vaatii usein myös sovellus- ja tapahtumatietoja.

**Lähteet ja lisämateriaali:**

- [Historian ja trendien säilyttäminen Zabbixissa](https://www.zabbix.com/documentation/current/en/manual/config/items/history_and_trends)
- [Trendifunktiot ja pitkäaikainen analyysi](https://www.zabbix.com/documentation/current/en/manual/appendix/functions/trends)
- [Zabbix-tietokannan koon ja säilytystarpeen arviointi](https://www.zabbix.com/documentation/current/en/manual/installation/requirements#database-size)

## 5. Yhteys valvonnan, SLA:n ja kapasiteetin välillä

Nämä kolme näkökulmaa täydentävät toisiaan:

- Enterprise Monitoring kerää ja yhdistää tiedot infrastruktuurista sekä palveluista.
- Dashboard esittää valitun tiedon niin, että käyttäjä pystyy arvioimaan tilanteen ja toimimaan.
- SLA vertaa palvelun toteutunutta tasoa sovittuun tavoitteeseen.
- Capacity Planning käyttää historiatietoa tulevien resurssitarpeiden ennakointiin.

```
Mittarit ja tapahtumat
				|
				+--> Dashboard: mitä tapahtuu nyt?
				+--> SLA: täyttyikö sovittu palvelutaso?
				+--> Kapasiteettitrendi: mihin suuntaan olemme menossa?
				|
				v
Toimenpide, selvitys tai kapasiteettipäätös
```

## 6. Käytännön harjoitus Zabbixissa

1. Avaa kurssin Zabbix käyttöliittymä osoitteessa http://localhost:8080 .
2. Tarkista, että hostit web1 , db1 ja branch-client lähettävät mittareita.
3. Avaa tai rakenna Golden Topology Status -dashboard ja lisää siihen hostien tila, CPU, muisti, levytila, verkkoliikenne sekä aktiiviset ongelmat.
4. Valitse yksi palvelu ja määrittele, mikä tarkistus kertoo sen olevan käyttäjälle käytettävissä. Vertaa palvelun tilaa yksittäisen hostin tilaan.
5. Tarkastele db1 -palvelimen levytilan historiatietoa eri aikaväleillä. Kirjaa nykyinen arvo, havaittu trendi ja epävarmuustekijä.
6. Kirjoita lyhyt ehdotus: mitä pitäisi hälyttää heti, mitä seurata SLA:ssa ja mitä kapasiteettimuutosta kannattaa suunnitella.

**Lähteet ja lisämateriaali:** [Zabbixin asennus ja ensimmäiset käyttöönottoaskeleet](https://www.zabbix.com/documentation/current/en/manual/installation), [järjestelmävaatimukset ja oletusportit](https://www.zabbix.com/documentation/current/en/manual/installation/requirements) sekä [Linux-palvelimen valvonnan pikaopas](https://www.zabbix.com/documentation/current/en/manual/guides/monitor_linux).

## Yhteenveto

Yritystason valvonta yhdistää laitteiden ja palveluiden mittarit, hälytykset, historiatiedon ja vastuut. Zabbix tarjoaa tähän keräyksen, triggerit, dashboardit ja palvelutason seurantaan liittyviä toimintoja. Dashboardin tulee auttaa päätöksenteossa, SLA:n perustua selkeästi määriteltyyn palveluun ja mittaustapaan, ja kapasiteettisuunnittelun nojata riittävän pitkään sekä edustavaan historiaan.

Kurssilabrassa sama mittausdata palvelee eri kysymyksiä: dashboard kertoo nykytilan, SLA kertoo toteutuneesta palvelutasosta ja kapasiteettianalyysi auttaa arvioimaan tulevaa. Näiden yhdistelmä tekee valvonnasta ennakoivaa ja palvelulähtöistä.
