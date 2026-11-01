# Viikko 4: Ansible ja Infrastructure as Code

## 1. Johdanto

**Mikä on Infrastructure as Code?**
Infrastructure as Code (IaC) tarkoittaa, että palvelinten ja verkkolaitteiden haluttu tila kuvataan tiedostoina (koodina) sen sijaan, että asetukset tehtäisiin käsin komentoriviltä. Kuvaus tallennetaan versionhallintaan ja automaatiotyökalu toteuttaa sen kohdelaitteille.

IaC:n keskeiset hyödyt:

- **Toistettavuus:** sama kuvaus tuottaa saman lopputuloksen jokaisella ajokerralla ja jokaisella koneella.
- **Dokumentaatio:** koodi kertoo, miten ympäristö on rakennettu.
- **Versionhallinta:** muutokset näkyvät Git-historiassa, ja niihin voi palata.
- **Idempotenssi:** ajon voi toistaa turvallisesti. Jos tila on jo oikea, mitään ei muuteta.

**Ansible** on agentiton automaatiotyökalu. Ohjausnode (tässä `ansible`-kontti) ottaa yhteyden kohteisiin SSH:lla, eikä kohteisiin tarvitse asentaa mitään ylimääräistä ohjelmistoa (Python riittää). Ansiblen keskeiset osat ovat:

- **inventory:** mitä laitteita hallitaan ja miten niihin otetaan yhteys
- **playbook:** YAML-tiedosto, joka kuvaa halutun tilan tehtävinä (tasks)
- **moduulit:** valmiit toiminnot, esim. `apt`, `copy` ja `uri`
- **handlerit:** tehtävät, jotka ajetaan vain, kun jokin muutos niitä vaatii

Ympäristössä hakemisto `configs/ansible` on liitetty ansible-konttiin polkuun `/ansible`, joten repoon tallennetut playbookit ovat suoraan ohjausnoden käytössä.

## 2. Inventory

Tulosteet: [week04-inventory.txt](week04-inventory.txt)

### Rakenne

Inventory (`configs/ansible/inventory.ini`) sisältää 13 laitetta. Laitteet on jaettu ryhmiin kolmella tavalla, ja sama laite voi kuulua useaan ryhmään:

| Ryhmittelyperuste | Ryhmät | Esimerkki |
|---|---|---|
| Laitetyyppi (sisäkkäiset ryhmät, `:children`) | `network_devices` → `routers`; `linux_hosts` → `clients`, `servers`, `monitoring`, `management` | `routers`: r1, r2, r3 |
| Verkkosegmentti | `user_network`, `server_network`, `branch_office` | `server_network`: web1, db1 |
| Käyttötarkoitus | `ubuntu_hosts`, `node_exporter` | `ubuntu_hosts`: client1, web1, db1, branch-client |

Laitteet osoitetaan konttien nimillä (`ansible_host=clab-hamk-verkonhallinta-golden-web1`), jotka ratkeavat Dockerin DNS:llä hallintaverkon (172.20.20.0/24) osoitteiksi. Yhteysasetukset on määritelty ryhmäkohtaisesti (`[servers:vars]` jne.): Linux-koneet käyttävät `ssh`-yhteyttä root-käyttäjänä ja reitittimet `network_cli`-yhteyttä.

### Mitä hyötyä ryhmistä on?

Playbook kohdistetaan ryhmään eikä yksittäisiin koneisiin. Esimerkiksi `hosts: ubuntu_hosts` osuu kaikkiin neljään Ubuntu-koneeseen ja uusi kone tulee mukaan automaattisesti, kun se lisätään ryhmään. Yhteysasetukset määritellään kerran ryhmälle eikä jokaiselle koneelle erikseen. Verkkosegmenttiryhmien avulla muutoksen voi kohdistaa esim. vain toimipisteeseen (`branch_office`).

### Yhteystesti

`ansible all -m ping` -tulos:

| Tulos | Laitteet | Syy |
|---|---|---|
| SUCCESS | web1, db1, client1, attacker, branch-client | SSH-yhteys toimii |
| SUCCESS (harhaanjohtava) | r1, r2, r3 | ks. alla |
| UNREACHABLE | prometheus, grafana, zabbix, cadvisor | `port 22: Connection refused`, valmiissa konttikuvissa ei ole SSH-palvelinta |
| UNREACHABLE | ansible | `Permission denied`, ohjausnode yrittää SSH-yhteyttä itseensä väärällä salasanalla |

### Reitittimien yhteysvian selvitys

Reitittimet näyttivät ping-testissä toimivan, mutta `ping.yml`-playbookin `show version` -komento epäonnistui. Selvitin vikaa kerros kerrallaan ([week04-ping-playbook.txt](week04-ping-playbook.txt), [week04-ping-routers-fix.txt](week04-ping-routers-fix.txt)):

1. `ping` antoi SUCCESS, mutta `network_cli`-yhteydellä ping-moduuli ajetaan ohjausnodella eikä se avaa yhteyttä reitittimeen. Tulos ei siis todistanut mitään.
2. `cli_command` epäonnistui: `paramiko is not installed`. Asensin ansible-konttiin paketin `python3-paramiko`.
3. Uusi virhe: `Unable to connect to port 22`. Topologiatiedoston mukaan reitittimille (`frrouting/frr`) ei asenneta SSH-palvelinta lainkaan.

Inventoryn `routers`-ryhmä on siis määritelty, mutta sitä ei voi hallita Ansiblella ympäristössä sellaisenaan.

### Kriittiset havainnot

- `linux_hosts` sisältää viisi konetta, joihin ei saa SSH-yhteyttä. Siihen kohdistettu playbook epäonnistuu niillä. Siksi esimerkkiplaybookit käyttävät ryhmää `ubuntu_hosts`.
- `node_exporter`-ryhmä sisältää reitittimet, vaikka niissä ei ollut exporteria (viikko 3). Ryhmän nimi ei kerro laitteen todellista tilaa.
- Salasanat (`ansible_ssh_pass`) ovat selväkielisinä inventoryssa ja siten myös Gitissä. Tuotannossa käytettäisiin Ansible Vaultia tai SSH-avaimia.

## 3. Esimerkkiplaybookit

Ajoin kummankin esimerkkiplaybookin kahdesti, jotta näkyisi, miten ne käyttäytyvät, kun tila on jo valmiiksi oikea. Tulosteet: [week04-example-playbooks.txt](week04-example-playbooks.txt), tarkistus [week04-example-verify.txt](week04-example-verify.txt).

### Moduulit

| Moduuli | install-snmp.yml | install-node-exporter.yml | Tarkoitus |
|---|---|---|---|
| `apt` | x | x | pakettilista ja pakettien asennus |
| `copy` | x | x | tiedoston sisällön kirjoitus / binäärin kopiointi |
| `service` | x | | palvelun käynnistys ja käyttöönotto |
| `file` | | x | hakemiston luonti |
| `get_url` | | x | tiedoston lataus verkosta |
| `unarchive` | | x | arkiston purku |
| `shell` | | x | prosessin käynnistys (`pkill`, `nohup`) |
| `uri` | | x | HTTP-tarkistus `/metrics`-osoitteeseen |
| `debug` | x | x | viestien tulostus |

### Muuttujat (`vars`)

- `snmp_community: public` upotetaan `snmpd.conf`-tiedoston sisältöön (`rocommunity {{ snmp_community }}`).
- `node_exporter_version: "1.9.1"` upotetaan latausosoitteeseen ja tiedostopolkuihin.

Muuttujien ansiosta arvo vaihdetaan yhdestä kohdasta, eikä sitä tarvitse etsiä koodista.

### Handlers SNMP-playbookissa

`Configure SNMP community` -tehtävällä on `notify: restart snmpd`. Handler ajetaan vain, jos tiedosto todella muuttui, ja vasta playn lopussa. Näin palvelu käynnistetään uudelleen vain tarvittaessa ja vain kerran, vaikka useampi tehtävä vaatisi sitä.

### Miksi Node Exporter -playbook ei tarvitse handleria?

Exporterilla ei ole konfiguraatiotiedostoa, jonka muutos vaatisi uudelleenkäynnistyksen. Lisäksi `Start node_exporter` on `shell`-tehtävä, joka pysäyttää ja käynnistää prosessin aina, kun playbook ajetaan.

### Ajotulokset

**install-snmp.yml**

| Ajo | Tulos |
|---|---|
| 1 | Paketit `ok` web1:llä, db1:llä ja branch-clientillä (asennettu käsin viikolla 2), `changed` client1:llä. `snmpd.conf` `changed` kaikilla. **`Enable SNMP service` epäonnistui kaikilla:** `Service is in unknown state` |
| 2 | `snmpd.conf` `ok` (`changed=0`), eli tiedosto oli jo oikea. Sama `service`-virhe |

`service`-moduuli ei pysty päättelemään palvelun tilaa kontissa, jossa ei ole systemd:tä. Koska play keskeytyi, **handler `restart snmpd` ei koskaan ajautunut**. Tarkistus näytti, että `snmpd is not running` kaikilla neljällä koneella. Paketit ja konfiguraatio olivat siis paikallaan, mutta palvelu ei toiminut. Playbook ei tarkista lopputulosta, joten se ei itse havaitse tätä.

**install-node-exporter.yml**

| Ajo | Tulos |
|---|---|
| 1 | Lataus, purku ja asennus `changed`. branch-clientille luotiin myös hakemisto (sillä ei ollut exporteria). `uri`-tarkistus onnistui kaikilla |
| 2 | Kaikki `ok` paitsi **`Start node_exporter` aina `changed`** |

`shell`-tehtävä ei ole idempotentti: Ansible ei tiedä, mitä komento tekee, joten se merkitsee sen aina muutokseksi. Lopputulos oli kuitenkin oikea: kaikilla neljällä on versio 1.9.1 ja **branch-client nousi Prometheuksessa ensimmäistä kertaa UP-tilaan** (viikolla 3 se oli DOWN). web1:lle viikolla 3 käsin asentamani versio 1.12.1 korvautui playbookin versiolla 1.9.1: kun tila määritellään koodissa, käsin tehty muutos ei säily.

## 4. Oma playbook: web-palvelin (vaihtoehto A)

Playbook: [configs/ansible/playbooks/install-webserver.yml](../configs/ansible/playbooks/install-webserver.yml)

### Suunnittelu

Playbook täyttää tehtävän vaatimukset (pakettilista, nginx, `index.html`, palvelun käynnistys `enabled: true`, tarkistus) ja käyttää samaa rakennetta kuin esimerkit (`vars`, `tasks`, `handlers`). Lisäksi se korjaa esimerkeistä havaitut ongelmat:

| Havaittu ongelma | Ratkaisu omassa playbookissa |
|---|---|
| `service`-moduuli ei toimi kontissa | `ansible.builtin.sysvinit`, joka käyttää suoraan `/etc/init.d/nginx`-skriptiä |
| SNMP-playbook ei huomannut, että palvelu ei käynnistynyt | Kaksi `uri`-tarkistusta, joissa `failed_when` vaatii, että sivulla näkyy palvelimen nimi |
| Handler ajetaan vasta lopussa, jolloin tarkistus testaisi vanhaa konfiguraatiota | `meta: flush_handlers` ennen tarkistuksia |
| `shell`-tehtävä ei ole idempotentti | Vain idempotentteja moduuleja |

Lisäksi playbook piilottaa nginxin versionumeron HTTP-vastauksista (`server_tokens off`). Tämä on pieni tietoturvaparannus, joka samalla demonstroi handlerin käyttöä.

### Koodi

```yaml
---
- name: Install and configure nginx web server
  hosts: web1
  become: true

  vars:
    web_package: nginx
    web_service: nginx
    web_root: /var/www/html
    web_port: 80

  tasks:
    - name: Update package cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Install web server package
      ansible.builtin.apt:
        name: "{{ web_package }}"
        state: present

    - name: Hide nginx version in responses
      ansible.builtin.copy:
        dest: /etc/nginx/conf.d/security.conf
        content: |
          server_tokens off;
        mode: "0644"
      notify: reload nginx

    - name: Create index page
      ansible.builtin.copy:
        dest: "{{ web_root }}/index.html"
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>{{ inventory_hostname }}</title></head>
          <body>
          <h1>{{ inventory_hostname }}</h1>
          <p>Hostname: {{ ansible_hostname }}</p>
          <p>Datatason IP: {{ data_ip }}</p>
          <p>Rooli: {{ role }}</p>
          <p>Hallinnoitu Ansiblella</p>
          </body>
          </html>
        mode: "0644"

    - name: Start and enable web server
      ansible.builtin.sysvinit:
        name: "{{ web_service }}"
        state: started
        enabled: true

    - name: Run pending handlers before verification
      ansible.builtin.meta: flush_handlers

    - name: Verify web server responds locally
      ansible.builtin.uri:
        url: "http://localhost:{{ web_port }}/"
        return_content: true
      register: local_check
      failed_when: inventory_hostname not in local_check.content

    - name: Verify web server responds from control node
      ansible.builtin.uri:
        url: "http://{{ ansible_host }}:{{ web_port }}/"
        return_content: true
      delegate_to: localhost
      register: remote_check
      failed_when: inventory_hostname not in remote_check.content

    - name: Show result
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }}: HTTP {{ remote_check.status }}, Server-header: {{ remote_check.server | default('n/a') }}"

  handlers:
    - name: reload nginx
      ansible.builtin.sysvinit:
        name: "{{ web_service }}"
        state: reloaded
```

`index.html` rakennetaan inventoryn muuttujista (`data_ip`, `role`) ja kerätyistä faktoista (`ansible_hostname`), joten sama playbook tuottaisi jokaiselle palvelimelle oman sivun ilman muutoksia koodiin.

### Suoritus 1

[week04-webserver-run1.txt](week04-webserver-run1.txt)

```text
TASK [Install web server package] ... changed: [web1]
TASK [Hide nginx version in responses] ... changed: [web1]
TASK [Create index page] ... changed: [web1]
TASK [Start and enable web server] ... changed: [web1]
RUNNING HANDLER [reload nginx] ... changed: [web1]
TASK [Verify web server responds locally] ... ok: [web1]
TASK [Verify web server responds from control node] ... ok: [web1 -> localhost]
"msg": "web1: HTTP 200, Server-header: nginx"

PLAY RECAP
web1 : ok=9 changed=5 unreachable=0 failed=0
```

- `sysvinit` käynnisti nginxin kontissa, eli SNMP-playbookin ongelmaa ei tullut.
- Handler ajettiin, koska `security.conf` muuttui, ja `flush_handlers` ajoi sen ennen tarkistuksia.
- `Server-header: nginx` ilman versionumeroa vahvistaa, että `server_tokens off` on käytössä.
- `web1 -> localhost`: jälkimmäinen tarkistus ajettiin ohjausnodelta, joten palvelu vastaa myös verkon yli.

### Suoritus 2: idempotenssi

[week04-webserver-run2.txt](week04-webserver-run2.txt)

```text
PLAY RECAP
web1 : ok=8 changed=0 unreachable=0 failed=0
```

Mitään ei muutettu, eikä handleria ajettu, koska konfiguraatio oli jo oikea. Playbook on täysin idempotentti, toisin kuin Node Exporter -esimerkki. Myös HTTP-vastauksen `Last-Modified`-aika on ensimmäisen ajon ajalta, eli toinen ajo ei kirjoittanut tiedostoa uudelleen.

### Lopputulos

[week04-webserver-page.txt](week04-webserver-page.txt)

```text
HTTP/1.1 200 OK
Server: nginx

<h1>web1</h1>
<p>Hostname: web1</p>
<p>Datatason IP: 10.10.20.101</p>
<p>Rooli: webserver</p>
<p>Hallinnoitu Ansiblella</p>
```

## 5. Järjestelmätiedot

Komento `ansible all -m setup` ([week04-setup-all.txt](week04-setup-all.txt)) ja tiivistelmä ([week04-setup-summary.txt](week04-setup-summary.txt)):

| Kone | Käyttöjärjestelmä | IP-osoite (oletusreitin rajapinta) | vCPU | Muisti |
|---|---|---|---|---|
| web1 | Ubuntu 24.04 | 10.10.20.101 (eth1) | 8 | 15 951 MB |
| db1 | Ubuntu 24.04 | 10.10.20.102 (eth1) | 8 | 15 951 MB |
| client1 | Ubuntu 24.04 | 10.10.10.101 (eth1) | 8 | 15 951 MB |
| branch-client | Ubuntu 24.04 | 10.10.30.101 (eth1) | 8 | 15 951 MB |
| attacker | Kali 2026.3 | 10.10.10.200 (eth1) | 8 | 15 951 MB |
| prometheus, grafana, zabbix, cadvisor, ansible | ei saatu (UNREACHABLE) | | | |

Havainnot:

- **Käyttöjärjestelmä tunnistuu oikein** (Ubuntu ja Kali), toisin kuin viikolla 2, jolloin SNMP:n `sysDescr` näytti vain WSL2-ytimen. Ansible lukee kontin oman käyttäjätilan tiedot, SNMP luki ytimen.
- **CPU ja muisti ovat kaikilla identtiset:** 8 vCPU ja noin 16 GB ovat WSL2-isännän resurssit, kuten viikolla 3 Node Exporterin tiedoissa.
- **IP-osoite on kaikilla eth1** (datatason verkko), koska oletusreitti kulkee reitittimen kautta. Ansible itse ottaa yhteyden hallintaverkon (eth0) kautta.
- **attacker on Kali**, mikä perustelee, miksi se puuttuu `ubuntu_hosts`-ryhmästä.
- Yksi komento keräsi tiedot viideltä koneelta muutamassa sekunnissa.

## 6. Vertailu: käsin vs. automaatio

Viikoilla 2 ja 3 asensin SNMP:n ja Node Exporterin käsin. Tällä viikolla samat asiat tehtiin Ansiblella, joten vertailu perustuu omaan kokemukseen:

| | Käsin (viikot 2–3) | Ansible (viikko 4) |
|---|---|---|
| SNMP neljälle koneelle | Kirjautuminen jokaiseen konttiin, `apt install`, `sed`-muutokset, uudelleenkäynnistys. web1 erikseen, db1 ja branch-client silmukalla | Yksi komento kaikille neljälle |
| Node Exporter | Versio selvitettiin, ladattiin, purettiin ja käynnistettiin käsin vain web1:lle. `cd node_exporter-*` -virhe vaati korjausta | Yksi playbook neljälle koneelle. branch-client sai exporterin ensimmäistä kertaa |
| Dokumentaatio | Komennot piti kirjata raporttiin erikseen | Playbook on itsessään dokumentaatio |
| Toistettavuus | Riippuu siitä, muistetaanko kaikki vaiheet | Sama lopputulos joka kerta |
| Tilan tarkistus | Erilliset `service status`- ja `curl`-komennot | Voidaan rakentaa playbookiin (`uri`, `failed_when`) |
| Pysyvyys | Käsin asennettu exporter korvautui playbookilla | Koodi määrää tilan |
| Virheiden näkyvyys | Virhe näkyy heti, kun tekee itse | Automaatio voi "onnistua" puoliksi huomaamatta, kuten SNMP-playbook, ellei lopputulosta tarkisteta |

**Hyödyt:** nopeus useilla koneilla, toistettavuus, idempotenssi, versionhallittava dokumentaatio ja yhtenäinen lopputulos. Käsin tehdyt asennukset olivat viikoilla 2–3 hieman erilaisia eri koneilla, mutta Ansible teki saman joka koneelle.

**Rajoitukset:** automaatio ei ole automaattisesti oikein. SNMP-esimerkki osoitti, että huonosti kirjoitettu playbook voi jättää palvelun pois päältä ilmoittamatta siitä selvästi, ja `shell`-tehtävät rikkovat idempotenssin. Automaatio myös toistaa virheet kaikille koneille kerralla. Lisäksi ympäristön pitää tukea hallintaa: reitittimiä ei voinut hallita, koska niissä ei ollut SSH:ta.

**Milloin automaatio on välttämätöntä?**
- kun hallittavia laitteita on kymmeniä tai satoja
- kun ympäristö pitää pystyä rakentamaan uudelleen nopeasti (esim. vikatilanteen jälkeen)
- kun muutosten pitää olla jäljitettäviä ja tarkastettavia (auditointi, muutoshallinta)
- kun sama muutos tehdään säännöllisesti, esim. päivitykset ja tietoturva-asetukset
- kun usean ylläpitäjän pitää tehdä muutoksia yhtenäisesti

## 7. Yhteenveto

Opin tehtävän aikana:

- Inventoryn ryhmärakenne ratkaisee, mihin playbook osuu. Ryhmien pitää vastata todellisuutta, muuten playbookit epäonnistuvat.
- `ping`-moduulin SUCCESS ei aina tarkoita, että yhteys toimii. Reitittimien vika löytyi vasta selvittämällä se kerros kerrallaan.
- Idempotenssin merkityksen käytännössä: oma playbook antoi toisella ajolla `changed=0`, mutta esimerkin `shell`-tehtävä raportoi muutoksen joka kerta.
- Handlerit ajetaan vain muutoksen yhteydessä ja oletuksena vasta playn lopussa. `flush_handlers` tarvitaan, jos muutoksen pitää olla voimassa ennen tarkistuksia.
- Playbookin pitää tarkistaa oma lopputuloksensa. SNMP-esimerkki näytti, mitä tapahtuu, jos niin ei tehdä.
- Konttiympäristö vaikuttaa automaatioon: systemd:n puute vaati eri moduulin (`sysvinit`), ja resurssitiedot kuvaavat isäntää.
- Git-historiasta näkee työn etenemisen vaihe vaiheelta, ja playbookin ensimmäinen versio on tallessa erillisenä committina.