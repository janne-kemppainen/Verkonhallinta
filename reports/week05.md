# Viikko 5: Protokolla-analyysi Wiresharkilla

## Johdanto

Tehtävässä harjoiteltiin protokolla-analyysiä Wiresharkilla Chris Greerin videosarjan pohjalta. Kaappaukset tehtiin kotona Windows 11 -työasemalla (Wireshark ja Npcap, liitäntä **Ethernet**) ja WSL2-Ubuntussa Dockerilla. GeoIP-tiedot tulevat MaxMindin GeoLite2-tietokannoista (ASN, City, Country), jotka liitettiin Wiresharkiin kohdasta **Edit → Preferences → Name Resolution → MaxMind database directories**.

Osien 1 ja 2 kaappaustiedostoja ei julkaista repossa, koska ne sisältävät omaa selaus- ja kirjautumisliikennettäni. Analyysi perustuu niihin ja tulokset on dokumentoitu tähän. Osan 3 kaappaus on mukana: [week05-basic-auth.pcap](week05-basic-auth.pcap).

---

## Osa 1: yle.fi ja palvelimen GeoIP-sijainti

Tein kaksi kaappausta: ensimmäisen capture filterillä ja toisen ilman sitä, display filtereillä. Ennen kumpaakin tyhjensin DNS-välimuistin (`ipconfig /flushdns`), ja sivu avattiin uudessa yksityisessä selainikkunassa, jotta DNS-kyselyt ja TLS-kättelyt näkyisivät kaappauksessa.

### Käytetyt suodattimet ja komennot

| Tekniikka | Suodatin / komento | Tarkoitus |
|---|---|---|
| Capture filter | `port 53 or port 443` | tallennetaan vain DNS ja HTTPS (TCP ja UDP/QUIC) |
| Display filter | `dns.qry.name contains "yle.fi"` | yle.fi-nimien DNS-kyselyt ja vastaukset |
| Display filter | `dns.qry.name == "www.yle.fi" && dns.flags.response == 1` | vain vastaukset |
| Display filter | `tls.handshake.extensions_server_name == "www.yle.fi"` | TLS Client Hello, jonka SNI on www.yle.fi |
| Display filter | `tls.handshake.extensions_server_name contains "yle"` | kaikki yle-palvelimet, joihin selain otti yhteyden |
| Display filter | `ip.addr == 52.85.154.0/24` | kaikki liikenne CloudFrontin osoitealueelle |
| Display filter | `ip.addr == 52.85.154.18 && tcp.analysis.initial_rtt` | yhteyden kiertoviive (iRTT) |
| Display filter | `!(udp.port == 53 \|\| tcp.port == 443 \|\| udp.port == 443)` | mitä capture filter olisi jättänyt pois |
| Display filter | `ip.geoip.dst_org contains "Amazon"` | GeoIP-kenttään perustuva suodatus |
| GeoIP | IPv4 → Destination GeoIP | maa, AS-numero, koordinaatit |
| PowerShell | `nslookup 52.85.154.18`, `nslookup 18.165.122.23` | käänteis-DNS |

### Kaappaus 1 (capture filter)

**DNS:**

| Nimi | Vastaus |
|---|---|
| `www.yle.fi` (A) | 52.85.154.18, 52.85.154.29, 52.85.154.27, 52.85.154.9 |
| `yle.fi` (A) | 18.165.122.23, 18.165.122.109, 18.165.122.126, 18.165.122.16 |
| `www.yle.fi` (AAAA) | 2600:9000:2045:... |
| SOA | `ns-76.awsdns-09.com` |
| `img.img-cdn.yle.fi` | CNAME → `ylemain.imgkit.net` → `d1i3d8xuw2xu32.cloudfront.net` |

- Kone (192.168.100.18) lähetti kyselyt kotireitittimelle (192.168.100.1).
- Selain kysyi jokaiselle nimelle tietueet A (IPv4), AAAA (IPv6) ja HTTPS (tyyppi 65, kertoo mm. HTTP/3-tuesta).
- yle.fi:n nimipalvelut ovat AWS Route 53:ssa ja kuvat tulevat Amazon CloudFront -CDN:stä.
- www.yle.fi:lle palautui neljä osoitetta, joiden järjestys vaihtui kyselyittäin. Kyse on CDN:n kuormanjaosta ja siksi tulos voi vaihdella eri kerroilla.

**Yhteys ja GeoIP:** selain otti yhteyden osoitteeseen **52.85.154.18** sekä TLS 1.3:lla TCP:n yli (paketti 158) että QUIC:lla (paketti 179). GeoIP antoi:

| Kenttä | Arvo |
|---|---|
| Maa | United States |
| AS | 16509, Amazon.com, Inc. |
| Koordinaatit | 37.751, -97.822 |
| Kaupunki | ei tietoa |

![GeoIP](images/week05-osa1-geoip.png)

### GeoIP-tuloksen kriittinen arviointi

Koordinaatit 37.751, -97.822 ovat Kansasissa, lähellä Yhdysvaltojen maantieteellistä keskipistettä, eikä kaupunkia ole. Tällainen tulos syntyy, kun tietokanta tietää vain maan. Tarkistin sijainnin kahdella muulla tavalla:

1. **Viive:** `tcp.analysis.initial_rtt` = **45,2 ms**. Valo kulkee kuidussa noin 200 km/ms, joten 45 ms:n edestakaisessa viiveessä palvelin voi olla enintään noin 4 500 km:n päässä. Suomesta Kansasiin on noin 8 000 km (vähimmäisviive noin 80 ms), joten **palvelin ei voi olla Yhdysvalloissa**. Viive kertoo kuitenkin vain ylärajan, koska suuri osa siitä syntyy omasta liittymästä.
2. **Käänteis-DNS:** `nslookup 52.85.154.18` → `server-52-85-154-18.`**`hel51`**`.r.cloudfront.net`. CloudFrontin palvelinnimissä on sijaintia kuvaava lentokenttäkoodi: **HEL = Helsinki**.

| Lähde | Tulos | Mitä se kertoo |
|---|---|---|
| GeoIP (MaxMind) | US, Amazon AS16509 | osoitealueen rekisteröity omistaja |
| Viive (iRTT 45 ms) | enintään noin 4 500 km | ei Yhdysvalloissa |
| Käänteis-DNS | `hel51.r.cloudfront.net` | **CloudFrontin Helsingin reunapalvelin** |

**Johtopäätös:** yle.fi:tä palveltiin Amazon CloudFrontin Helsingin reunapalvelimelta. GeoIP ei kerro luotettavasti pilvi- ja CDN-palveluiden fyysistä sijaintia, koska osoitealueet on rekisteröity yhtiön kotimaahan, vaikka palvelimia on ympäri maailmaa.

### Kaappaus 2 (display filterit)

**Mitä capture filter olisi jättänyt pois** (`!(udp.port == 53 || tcp.port == 443 || udp.port == 443)`):

- **TLS-liikenne portissa 27020** osoitteeseen 155.133.229.4. GeoIP: Frankfurt, Valve Corporation, eli todennäköisesti taustalla käynnissä oleva Steam. Salattua liikennettä, joka ei käytä porttia 443, joten **porttiin perustuva capture filter ohittaisi sen kokonaan**.
- **mDNS-, LLMNR- ja NBNS-kyselyt** nimelle `BRWDCE99452D115`: kone etsii lähiverkosta laitetta kolmella eri nimenselvitystavalla.

Tämä havainnollistaa videon 5 varoitusta: liian tiukka capture filter voi jättää olennaisen pois, eikä poisjätettyä liikennettä voi enää jälkikäteen tutkia.

**DNS:** sama osoitejoukko kuin kaappauksessa 1, mutta eri järjestyksessä.

**Yhteys:** suodatin `tls.handshake.extensions_server_name == "www.yle.fi"` ei löytänyt mitään. Laajemmalla suodattimella (`contains "yle"`) selvisi, että tällä kertaa pääsivu haettiin nimellä **`yle.fi`** osoitteesta **18.165.122.23** (QUIC, paketti 229). `nslookup 18.165.122.23` → `server-18-165-122-23.`**`hel51`**`.r.cloudfront.net`, eli sama Helsingin reunasijainti eri osoitteella.

Yksi sivulataus johti yhteyksiin useisiin palveluihin:

| SNI | Osoite | Palveluntarjoaja |
|---|---|---|
| yle.fi | 18.165.122.23 | Amazon CloudFront |
| locations.api.yle.fi | 18.165.140.44 | Amazon CloudFront |
| login.api.yle.fi | 52.85.154.124 | Amazon CloudFront |
| player-v2.yle.fi, player.api.yle.fi | 13.33.235.96, 13.33.235.17 | Amazon CloudFront |
| haavi.yle.fi | 52.213.113.155 | Amazon |
| yleawsmpondemand-03.akamaized.net | 193.229.109.48 | Akamai |

Selain avasi samaan palvelimeen (`login.api.yle.fi`) yhtä aikaa sekä QUIC- että TCP/TLS-yhteyksiä (kolme rinnakkaista SYN-pakettia) ja käytti nopeinta.

### Capture filter vs. display filter

| | Capture filter | Display filter |
|---|---|---|
| Milloin | ennen kaappausta | kaappauksen aikana tai jälkeen |
| Vaikutus | rajaa, mitä tallennetaan | rajaa, mitä näytetään |
| Syntaksi | BPF, esim. `port 53 or port 443` | Wiresharkin kentät, esim. `dns.qry.name contains "yle.fi"` |
| Etu | pienempi tiedosto, kevyempi kaappaus | joustava, ei menetä mitään |
| Riski | poisrajattua liikennettä ei saa takaisin (esim. Steamin TLS portissa 27020) | iso tiedosto vilkkaassa verkossa |

Kaappausten pakettimääriä (2 633 ja 792) ei voi verrata suoraan, koska ensimmäinen kaappaus oli käynnissä pidempään.

---

## Osa 2: learn.hamk.fi

Kaappasin liikenteen learn.hamk.fi:hin kirjautumisen ajan (6 630 pakettia). Kaappauksen aikana ajoin lisäksi `nslookup -type=NS hamk.fi`, jotta autoritatiivisten nimipalvelimien kysely näkyisi kaappauksessa.

### 1) DNS

Suodatin: `dns.qry.name contains "hamk.fi"`

| Kysymys | Vastaus | Paketti |
|---|---|---|
| learn.hamk.fi:n IP-osoite | **195.148.239.84** | 617 |
| TTL (kotireitittimen vastaus) | **1770 s** (29 min 30 s) | 617 |
| Autoritatiiviset nimipalvelimet (hamk.fi) | **ns1.hamk.fi, ns2.hamk.fi, ns3.hamk.fi, ns-secondary.funet.fi** (TTL 53 s) | 213 |
| learn.hamk.fi:n SOA | ns1.hamk.fi | 618 |

- `nslookup` lisäsi ensin nimen perään kotireitittimen jakaman DNS-hakuliitteen ja kysyi `hamk.fi.elisakoti` (vastaus `No such name`, paketit 210–211). Vasta sen jälkeen se kysyi pelkkää nimeä.
- Kirjautumisessa haettiin myös `shibbo.hamk.fi` (195.148.239.10), eli Shibboleth-kertakirjautuminen (Haka).
- Toisin kuin Yle, HAMK ei käytä CDN:ää: learn.hamk.fi ratkesi yhteen osoitteeseen. Yksi nimipalvelimista on Funetin, eli korkeakoulujen yhteisen verkon.

**TTL:n tarkistus autoritatiiviselta palvelimelta:**

```text
nslookup -debug learn.hamk.fi ns1.hamk.fi

header flags:  response, auth. answer, want recursion
learn.hamk.fi  internet address = 195.148.239.84  ttl = 3600 (1 hour)
```

| | Kotireitittimen vastaus | Autoritatiivinen (ns1.hamk.fi) |
|---|---|---|
| learn.hamk.fi, A | 195.148.239.84, TTL 1770 s | 195.148.239.84, TTL **3600 s** |

- **Alkuperäinen TTL on 3600 s (1 h).** Kotireitittimen vastaus tuli välimuistista, ja tietue oli ollut siellä noin 30 minuuttia (3600 − 1770 = 1830 s). TTL:n arvo vaihtelee siis sen mukaan, keneltä kysytään.
- `auth. answer` -lippu näkyy vain ns1.hamk.fi:n vastauksissa.
- ns1.hamk.fi vastasi `REFUSED`, kun siltä kysyttiin muuta nimeä (`learn.hamk.fi.elisakoti`). Se ei tee rekursiivisia kyselyjä ulkopuolisille. Tämä on hyvä tietoturvakäytäntö, koska avoimia rekursiivisia nimipalvelimia käytetään DNS-vahvistushyökkäyksissä.
- SOA: `primary name server = ns1.hamk.fi`, `serial = 2026102001`, `refresh = 3600`, `retry = 7200`, `expire = 604800`, `default TTL = 86400`.
- learn.hamk.fi:llä ei ole IPv6-osoitetta (AAAA-kyselyyn vastattiin pelkällä SOA:lla).

### 2) TLS-kättely

Tehtävänannon vihjeen suodatin `ssl.handshake.ciphersuite` on Wiresharkin uusissa versioissa nimellä `tls.handshake.ciphersuite`. Käytin kättelyviestityyppiin perustuvia suodattimia:

- Client Hello: `tls.handshake.type == 1 && tls.handshake.extensions_server_name == "learn.hamk.fi"`
- Server Hello: `tls.handshake.type == 2 && ip.src == 195.148.239.84`

Client Helloja oli 10, eli selain avasi useita rinnakkaisia yhteyksiä samaan palvelimeen.

**Client Hello (paketti 622): selaimen ehdotukset**

- Record/Handshake Version: TLS 1.2 (0x0303). Tämä on vain yhteensopivuuskenttä.
- `supported_versions`: **TLS 1.3, TLS 1.2**
- `key_share`: **X25519MLKEM768**, x25519, secp256r1
- ALPN: h2, http/1.1
- 15 salausalgoritmia:

| TLS 1.3 | TLS 1.2 (ECDHE) | TLS 1.2 (RSA-avaintenvaihto) |
|---|---|---|
| TLS_AES_128_GCM_SHA256 | TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 | TLS_RSA_WITH_AES_128_GCM_SHA256 |
| TLS_CHACHA20_POLY1305_SHA256 | TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 | TLS_RSA_WITH_AES_256_GCM_SHA384 |
| TLS_AES_256_GCM_SHA384 | TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 | TLS_RSA_WITH_AES_128_CBC_SHA |
| | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 | TLS_RSA_WITH_AES_256_CBC_SHA |
| | TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | |
| | TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | |
| | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA | |
| | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA | |

![Client Hello](images/week05-osa2-client-hello.png)

**Server Hello (paketti 624): palvelimen valinta**

| | Selain ehdotti | Palvelin valitsi |
|---|---|---|
| TLS-versio | TLS 1.3, TLS 1.2 | **TLS 1.3** (`supported_versions` = 0x0304) |
| Salausalgoritmi | 15 vaihtoehtoa | **TLS_AES_128_GCM_SHA256** (0x1301) |
| Avaintenvaihto | X25519MLKEM768, x25519, secp256r1 | **x25519** |

![Server Hello](images/week05-osa2-server-hello.png)

**Tulkinta:**

- **Yhteys käyttää TLS 1.3:a.** Version-kenttä näyttää molemmissa viesteissä TLS 1.2:ta, koska TLS 1.3 jättää sen tarkoituksella vanhaan arvoon yhteensopivuuden vuoksi. Todellinen versio luetaan `supported_versions`-laajennuksesta.
- **TLS_AES_128_GCM_SHA256** tarkoittaa AES-salausta 128-bittisellä avaimella GCM-tilassa (salaus ja eheyden tarkistus samalla) ja SHA-256-tiivistettä. Palvelin valitsi selaimen listan ensimmäisen vaihtoehdon.
- **Palvelin ei tukenut kvanttiturvallista avaintenvaihtoa.** Selain tarjosi ensisijaisena hybridiä X25519MLKEM768:aa, mutta palvelin valitsi perinteisen x25519:n. Yhteys on silti nykyisillä kriteereillä turvallinen.
- **Server Hellon jälkeen kaikki on salattua.** TLS 1.3:ssa palvelimen varmenne ja ALPN-valinta kulkevat jo salattuina (`Application Data`), joten Wiresharkista ei näe, kumman HTTP-version palvelin valitsi.

---

## Osa 3: HTTP Basic Auth -tunnusten löytäminen liikenteestä

### Ympäristö ja kaappaus

Käytin tehtävänannon tcpdump-versiota, koska Docker Engine toimii WSL2:ssa ilman Docker Desktopia, eikä liikenne välttämättä näy Windowsin loopback-adapterissa. Tunnukset ovat keksittyjä testitunnuksia.

```bash
mkdir -p ~/site
echo '<h1>Basic Auth -testisivu</h1>' > ~/site/index.html

docker run -d --name basic-auth \
  --env AUTH_USER=tllabra \
  --env 'AUTH_PASS=Qwerty1!' \
  -v ~/site:/var/www \
  -p 8080:80 \
  tjarvenpaa/basic_auth:alpine-0.1-latest
```

Kaappaus kontin sisällä, capture filterinä `port 80`:

```bash
docker exec -it basic-auth tcpdump -i eth0 -w /var/www/dump.pcap port 80
```

Tiedosto tallentui kontin verkkosivuhakemistoon, joka on liitetty WSL:n kansioon `~/site`, joten se oli suoraan käytettävissä. Kaappauksen aikana avasin selaimessa (Firefox, yksityinen ikkuna) osoitteen `http://localhost:8080` ja kirjauduin. Tulos: `23 packets captured, 0 packets dropped by kernel`. Kaappaus: [week05-basic-auth.pcap](week05-basic-auth.pcap)

Palvelin näkee pyyntöjen lähteenä **172.17.0.1** eli Dockerin sisäverkon yhdyskäytävän, ei Windowsin selainta, koska WSL ohjaa `localhost:8080`:n Dockerin sisäverkkoon. Kaappaus näyttää siis liikenteen palvelimen näkökulmasta (video 4: kaappauspisteen valinta).

### Suodattimet ja hakutermit

| Suodatin | Tulos | Kuvaus |
|---|---|---|
| `http` | 6 pakettia | kaikki HTTP-pyynnöt ja -vastaukset |
| `http.authorization` | 2 pakettia (14, 18) | pyynnöt, joissa on `Authorization`-otsake |
| `frame contains "Authorization"` | 2 pakettia (14, 18) | merkkijonohaku koko kehyksestä ilman kentän nimeä |
| `http.response.code == 401` | 1 paketti (6) | palvelimen kirjautumisvaatimus |

Hakutermi on HTTP-otsake **`Authorization`**, jossa Basic-tunnistautumisessa on sana `Basic` ja Base64-koodattu merkkijono `käyttäjä:salasana`. `contains` erottaa isot ja pienet kirjaimet, joten kirjainkoosta riippumattomaan hakuun käytettäisiin `matches`-operaattoria.

### Kirjautumisen kulku

| Paketti | Suunta | Sisältö | Merkitys |
|---|---|---|---|
| 4 | selain → palvelin | `GET /` | ensimmäinen pyyntö ilman tunnuksia |
| 6 | palvelin → selain | `401 Unauthorized` | palvelin vaatii kirjautumista |
| 14 | selain → palvelin | `GET /` + `Authorization` | pyyntö tunnusten kanssa |
| 16 | palvelin → selain | `200 OK` | kirjautuminen onnistui |
| 18 | selain → palvelin | `GET /favicon.ico` + `Authorization` | tunnukset lähetetään uudelleen |
| 19 | palvelin → selain | `404 Not Found` | kuvaketta ei ole |

### Löydetyt tunnukset

Paketti 14 (`http.authorization`):

```text
Authorization: Basic dGxsYWJyYTpRd2VydHkxIQ==
    Credentials: tllabra:Qwerty1!
```

![Tunnukset](images/week05-osa3-credentials.png)

`dGxsYWJyYTpRd2VydHkxIQ==` on merkkijono `tllabra:Qwerty1!` Base64-koodattuna. **Base64 on koodaus, ei salaus**: sen voi purkaa ilman avainta, ja Wireshark tekee sen automaattisesti (`Credentials`-rivi ja **Basic Credentials** -välilehti). Tunnukset näkyvät myös Packet Bytes -paneelissa luettavana tekstinä.

### Palvelimen kirjautumisvaatimus

Paketti 6 (`http.response.code == 401`):

```text
HTTP/1.1 401 Unauthorized
Server: Apache/2.4.52 (Unix)
WWW-Authenticate: Basic realm="Restricted Content"
[Time since request: 168.000 microseconds]
```

![401](images/week05-osa3-401.png)

- `WWW-Authenticate: Basic` kertoo, että palvelin vaatii Basic-tunnistautumista, ja `realm` on suojatun alueen nimi.
- **`Server: Apache/2.4.52 (Unix)`**: palvelin paljastaa ohjelmistonsa ja tarkan versionsa jokaisessa vastauksessa, mikä helpottaa tunnettujen haavoittuvuuksien etsimistä.

### Tietoturvahavainnot

- **Selväkielinen HTTP + Basic Auth = tunnukset näkyvät kaikille**, jotka näkevät liikenteen (sama verkko, Wi-Fi, välityspalvelin, verkkolaite). Osan 2 TLS-yhteydessä vastaava sisältö oli salattua.
- **Tunnukset kulkevat jokaisessa pyynnössä** (myös `/favicon.ico`), koska Basic Authissa ei ole istuntoa. Jokainen pyyntö on uusi mahdollisuus siepata ne.
- **Korjaus:** HTTPS (TLS) aina, kun liikenteessä on tunnuksia, sekä mieluummin istunto- tai tokenpohjainen kirjautuminen. Lisäksi palvelinversion piilottaminen (`ServerTokens Prod`).

---

## Pohdinta

- **Salaus ratkaisee, mitä liikenteestä voi nähdä.** Osassa 3 näin tunnukset suoraan. Osassa 2 näin vain kättelyn metatiedot (palvelimen nimi SNI:ssä, versiot, algoritmit), mutta en sisältöä. Salattukaan liikenne ei ole näkymätöntä: DNS ja SNI paljastavat, mihin palveluihin kone ottaa yhteyttä.
- **Analyysin tulokset pitää varmistaa useasta lähteestä.** GeoIP antoi yle.fi:n palvelimelle sijainnin Yhdysvalloissa, mutta viive ja käänteis-DNS osoittivat Helsingin. Samoin TTL-arvo oli eri kotireitittimeltä ja autoritatiiviselta palvelimelta kysyttäessä.
- **Capture filter on hyödyllinen mutta riskialtis.** Display filterillä löytyi liikennettä (Steamin TLS portissa 27020), jonka porttipohjainen capture filter olisi jättänyt kokonaan pois.
- **Kytkentä viikon teemaan (Zero Trust, SIEM):** Zero Trust -ajattelussa verkon sisäistäkään liikennettä ei pidetä luotettavana, joten myös sisäverkon palvelut salataan, eikä Basic Authia selväkielisenä hyväksytä. Pakettikaappaus ja sen metatiedot (DNS-kyselyt, yhteyskohteet, poikkeavat portit) ovat SIEM-järjestelmän tärkeää aineistoa: niistä voi korreloida esimerkiksi epätavalliset yhteydet tai salaamattomat kirjautumiset.
- **Kaappaustiedostot ovat itsessään arkaluonteisia.** Ne sisältävät osoitteita, nimiä ja mahdollisesti salaamatonta sisältöä, joten julkaisin vain osan 3 kaappauksen, jossa on keksityt testitunnukset.