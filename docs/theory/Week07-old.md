Tietoverkon resurssien valvominen on tärkeää, jotta voidaan varmistaa, että verkko toimii tehokkaasti ja luotettavasti. Resurssien valvontaa voidaan tehdä useilla eri tavoilla, ja valittu menetelmä riippuu verkon koosta ja monimutkaisuudesta.

Yksi tapa valvoa tietoverkon resursseja on käyttää verkonhallintajärjestelmää (NMS). NMS on ohjelmisto, joka kerää ja tallentaa tietoja verkon laitteista ja resursseista. NMS:ää voidaan käyttää seuraamaan resurssien käyttöä, havaitsemaan häiriöitä ja tekemään muutoksia verkon konfiguraatioon.

Toinen tapa valvoa tietoverkon resursseja on käyttää verkon valvontatyökaluja. Verkkovalvontatyökalut ovat ohjelmia, jotka keräävät tietoja verkon liikkeestä ja laitteista. Verkkovalvontatyökaluja voidaan käyttää seuraamaan verkon suorituskykyä, havaitsemaan tietoturvauhkia ja tutkimaan verkon häiriöitä.

Tietoverkon resursseja voidaan valvoa myös manuaalisesti. Tämä tarkoittaa, että verkon ylläpitäjät keräävät ja tulkitsevat tietoja verkon laitteista ja resursseista käsin. Manuaalinen valvonta voi olla työlästä ja aikaa vievää, mutta se voi olla tarpeen pienissä tai yksinkertaisissa verkoissa.

Seuraavat ovat joitakin yleisiä tietoverkon resursseja, joita voidaan valvoa:

- Laitteiden käyttö
- Verkon liikenne
- Suorituskyky
- Tietojen käytettävyys
- Turvallisuus

Laitteiden käytön valvominen auttaa varmistamaan, että laitteet käytetään tehokkaasti. Verkkoliikenteen valvominen auttaa havaitsemaan mahdolliset häiriöt ja tietoturvauhkat. Suorituskyvyn valvominen auttaa varmistamaan, että verkko toimii odotetulla tavalla. Tietojen käytettävyyden valvominen auttaa varmistamaan, että käyttäjät voivat käyttää tietoja, joita he tarvitsevat. Turvallisuuden valvominen auttaa varmistamaan, että verkko on suojattu hyökkäyksiltä.

Alla on kuvaus erään NMS järjestelmän toiminnasta ja arkkitehtuurista

[Zabbix](https://www.zabbix.com) on avoimen lähdekoodin verkonvalvontajärjestelmä (NMS), joka voidaan asentaa ja käyttää ilmaiseksi. Se on monipuolinen työkalu, jota voidaan käyttää monien erilaisten verkkojen valvomiseen.

**Zabbix-arkkitehtuuri**

Zabbix on avoimen lähdekoodin verkonvalvontajärjestelmä, joka koostuu seuraavista osista:

- Zabbix-palvelin: Zabbix-palvelin on Zabbix-järjestelmän keskipiste. Se kerää ja tallentaa tietoja valvottavista laitteista ja resursseista.
- Zabbix-agentit: Zabbix-agentit ovat ohjelmia, jotka asennetaan valvottaviin laitteisiin. Ne keräävät tietoja laitteista ja lähettävät ne Zabbix-palvelimelle.
- Zabbix-Web-käyttöliittymä: Zabbix-Web-käyttöliittymä on verkossa toimiva käyttöliittymä, jota käytetään Zabbix-järjestelmän hallintaan ja valvontaan.

**Zabbix-palvelin**

Zabbix-palvelin on Zabbix-järjestelmän keskipiste. Se kerää ja tallentaa tietoja valvottavista laitteista ja resursseista. Zabbix-palvelin voidaan asentaa usealle eri käyttöjärjestelmälle, kuten Linuxille, Windowsille ja macOS:lle. Palvelin osalle ei ole graafista käyttöliittymää, vaan palvelinta käytetään erillisen web-käyttöliittymän kautta.

**Zabbix-agentit**

Zabbix-agentit ovat ohjelmia, jotka asennetaan valvottaviin laitteisiin. Ne keräävät tietoja laitteista ja lähettävät ne Zabbix-palvelimelle. Zabbix-agentit ovat saatavilla useille eri laitteille, kuten Linuxille, Windowsille, macOS:lle, verkkolaitteille ja palvelimille. Zabbix osaa kerätä dataa eri tavoin, näistä tavoista Zabbix-agentti on kuitenkin monipuolisin. Muita tapoja ovat mm. SNMP, Prometheus ja suora logien lukeminen (parserointi)

**Zabbix-Web-käyttöliittymä**

Zabbix-Web-käyttöliittymä on verkossa toimiva käyttöliittymä, jota käytetään Zabbix-järjestelmän hallintaan ja valvontaan. Zabbix-Web-käyttöliittymä tarjoaa mahdollisuuden tarkastella valvottavien laitteiden tietoja, luoda hälytyksiä ja visualisointeja. Zabbix on julkaistu usealle erilaiselle web alustalle, joista yleisimmät ovat Apache ja Nginx.

**Zabbix-arkkitehtuurin kuva**

![File:Zabbix architecture.svg - Wikipedia](https://upload.wikimedia.org/wikipedia/commons/2/2e/Zabbix_architecture.svg)

**Zabbix-arkkitehtuurin selitys**

Zabbix-arkkitehtuuri on seuraava:

- Zabbix-palvelin kerää ja tallentaa tietoja valvottavista laitteista ja resursseista. Zabbix-palvelin käyttää Zabbix-agentteja kerätäkseen tietoja. Zabbix-palvelin tallentaa tiedot tietokantaan.
- Zabbix-agentit keräävät tietoja valvottavista laitteista ja lähettävät ne Zabbix-palvelimelle. Zabbix-agentit käyttävät erilaisia menetelmiä kerätäkseen tietoja, kuten SNMP:tä, TCP-portteja ja komentoja.
- Zabbix-Web-käyttöliittymä tarjoaa mahdollisuuden tarkastella valvottavien laitteiden tietoja, luoda hälytyksiä ja visualisointeja. Zabbix-Web-käyttöliittymä käyttää tietoja, jotka on tallennettu Zabbix-palvelimelle.
- Zabbix-proxy kerää tietoa etäpisteellä sijaitsevista kohteista. Proxyn tarkoitus on laajentaa Zabbix järjestelmää esim. pilven palveluiden valvontaan.

Yksinkertaisessa verkkorakenteessa Zabbix voidaan ottaa käyttöön seuraavasti:

1. Asenna Zabbix-palvelin. Zabbix-palvelin on Zabbix-järjestelmän keskipiste. Se kerää ja tallentaa tietoja verkon laitteista ja resursseista. Zabbix-palvelimen voi asentaa usealle eri käyttöjärjestelmälle, kuten Linuxille, Windowsille ja macOS:lle.
2. Asenna Zabbix-agentit. Zabbix-agentit ovat ohjelmia, jotka asennetaan valvottaviin laitteisiin. Ne keräävät tietoja laitteista ja lähettävät ne Zabbix-palvelimelle. Zabbix-agentit ovat saatavilla useille eri laitteille, kuten Linuxille, Windowsille, macOS:lle, verkkolaitteille ja palvelimille.
3. Luo Zabbix-tunnukset. Zabbix-tunnuksia tarvitaan Zabbix-järjestelmän käyttöön. Tunnuksia tarvitaan Zabbix-palvelimen, agenttien ja käyttäjien luomiseen.
4. Luo Zabbix-valvontaobjektit. Zabbix-valvontaobjektit ovat Zabbix-järjestelmän tapa määritellä, mitä tietoja halutaan kerätä. Valvontaobjektit määritellään Zabbix-hallintakonsolissa.
5. Käynnistä Zabbix-valvonta. Kun Zabbix-valvontaobjektit on luotu, Zabbix-järjestelmä alkaa kerätä tietoja valvottavista laitteista.

Zabbix on helppokäyttöinen ja tehokas verkonvalvontajärjestelmä. Se voidaan ottaa käyttöön nopeasti ja helposti yksinkertaisessa verkkorakenteessa.

Käyttöönotosta voit lukea [täältä](https://www.zabbix.com/documentation/current/en/manual/installation/getting_zabbix) lisää.
