# Korvaava laboratorio: Verkon automaatio Ansiblella

> Tämä harjoitus korvaa kampuksella tehtävän Cisco-verkon automaatiolaboratorion.

**Arvioitu työmäärä:** 3–5 tuntia

## Tavoite

Harjoituksen tavoitteena on soveltaa Ansiblea kurssin virtuaalisen verkkoympäristön hallintaan.

Harjoituksen jälkeen osaat:

- hallita verkkolaitteita SSH:n avulla
- rakentaa Ansible-inventaarion
- kerätä tietoja verkkolaitteista automaattisesti
- ottaa verkkokonfiguraatioista varmistuksia
- tehdä hallittuja konfiguraatiomuutoksia Ansiblella
- käyttää Git-versionhallintaa verkon muutosten seuraamiseen
- tarkistaa ja palauttaa verkon tunnettuun tilaan
- ymmärtää idempotenssin ja Infrastructure as Code -ajattelun perusteet

---

## 1. Ympäristön tarkistaminen

Käynnistä kurssin virtuaaliympäristö normaalisti.

Tarkista ympäristön tila:

```bash
sudo containerlab inspect
docker ps
```

Tutustu ympäristön topologiaan ja paikanna vähintään:

- `r1-edge`
- `r2-core`
- `r3-branch`
- Ansible-hallintapalvelin

Selvitä reitittimien hallintaan käytettävät IP-osoitteet.

### Dokumentoi

Lisää raporttiisi lyhyt kuvaus siitä, miten Ansible-palvelin pystyy kommunikoimaan reitittimien kanssa.

---

## 2. SSH-yhteydet ja Ansible-inventaario

Testaa SSH-yhteys vähintään kahteen reitittimeen.

```bash
ssh <user>@<router-ip>
```

Luo harjoitukselle oma hakemisto:

```text
automation-lab/
├── inventory/
│   └── hosts.yml
├── playbooks/
├── backups/
└── README.md
```

Luo Ansible-inventaario, jossa ovat:

- `r1-edge`
- `r2-core`
- `r3-branch`

Testaa inventaario:

```bash
ansible-inventory -i inventory/hosts.yml --graph
```

Testaa tämän jälkeen Ansible-yhteydet kaikkiin reitittimiin.

### Dokumentoi

- käyttämäsi IP-osoitteet
- `ansible-inventory --graph` -tulos
- Ansible-yhteystestin tulos

---

## 3. Verkon automaattinen inventointi

Luo playbook:

```text
playbooks/facts.yml
```

Playbookin tulee kerätä kaikista reitittimistä vähintään:

- hostname
- IP-osoitteet
- verkkointerfacet
- käyttöjärjestelmän tiedot
- uptime

Playbook pitää pystyä suorittamaan yhdellä komennolla kaikille inventaarion reitittimille.

### Dokumentoi

Vertaa kolmen reitittimen tietoja.

**Kysymys:** Mitä eroja havaitset reitittimien interface- ja IP-konfiguraatioissa?

---

## 4. Konfiguraatioiden varmistaminen

Luo playbook:

```text
playbooks/backup.yml
```

Sen tehtävänä on hakea jokaisen reitittimen verkkokonfiguraatio ja tallentaa se Ansible-palvelimelle.

FRRouting-konfiguraatiota voit tarkastella esimerkiksi:

```bash
vtysh -c "show running-config"
```

Tavoiteltu lopputulos:

```text
backups/
├── r1-edge.conf
├── r2-core.conf
└── r3-branch.conf
```

Backup pitää pystyä suorittamaan yhdellä komennolla kaikille reitittimille.

---

## 5. Verkon tila Git-versionhallintaan

Alusta harjoitushakemisto Git-repositoryksi.

```bash
git init
git add .
git commit -m "Initial network state"
```

Tarkista:

```bash
git status
git log --oneline
```

**Kysymys:** Miksi verkkolaitteiden konfiguraatioita kannattaa säilyttää versionhallinnassa?

---

## 6. Hallittu konfiguraatiomuutos

Tee seuraavaksi verkkokonfiguraation muutos Ansiblella.

Lisää `r3-branch`-reitittimelle loopback-interface:

```text
lo10
192.0.2.3/32
```

Luo muutosta varten:

```text
playbooks/loopback.yml
```

Älä tee varsinaista muutosta käsin reitittimellä.

Aja playbook ensimmäisen kerran ja tarkista, että muutos toteutui.

Aja tämän jälkeen sama playbook uudelleen.

### Dokumentoi

Vertaa ensimmäisen ja toisen suorituksen `changed`-tietoja.

**Kysymys:** Mitä tulos kertoo Ansiblen idempotenssista?

---

## 7. Muutoksen tarkistaminen

Luo:

```text
playbooks/verify.yml
```

Playbookin pitää automaattisesti tarkistaa, että:

- `lo10` on olemassa
- sillä on osoite `192.0.2.3/32`
- reitittimet ovat edelleen saavutettavissa

Pelkkä muutoksen suorittaminen ilman sen onnistumisen tarkistamista ei riitä.

**Kysymys:** Miksi muutoksen tekeminen ja sen onnistumisen tarkistaminen ovat automaatiossa eri asioita?

---

## 8. Muutoksen tallentaminen

Ota uudet backupit ja tarkastele muutosta Gitillä:

```bash
git diff
```

Tallenna uusi tila:

```bash
git add .
git commit -m "Add branch loopback interface"
```

Tarkista historia:

```bash
git log --oneline
```

Git-historiassa pitäisi nyt näkyä vähintään kaksi verkon tilaa:

```text
Add branch loopback interface
Initial network state
```

---

## 9. Virhetilanne ja palautuminen

Simuloi lopuksi konfiguraatiovirhe muuttamalla `r3-branch`-reitittimen harjoituksessa lisäämääsi loopback-konfiguraatiota.

Ota uusi backup ja käytä Gitiä selvittääksesi:

1. mikä muuttui
2. mikä oikea konfiguraatio oli
3. miltä tunnettu toimiva tila näyttää

Palauta oikea konfiguraatio **Ansiblen avulla**.

Suorita lopuksi `verify.yml`.

Lopputilanteessa kaikkien reitittimien pitää olla saavutettavissa ja:

```text
r3-branch
└── lo10 = 192.0.2.3/32
```

---

# Palautus

Palauta harjoituksen Git-repository.

Repositoryssa tulee olla vähintään:

```text
automation-lab/
├── inventory/
│   └── hosts.yml
├── playbooks/
│   ├── facts.yml
│   ├── backup.yml
│   ├── loopback.yml
│   └── verify.yml
├── backups/
│   ├── r1-edge.conf
│   ├── r2-core.conf
│   └── r3-branch.conf
└── README.md
```

Git-historiassa tulee näkyä vähintään:

```text
Initial network state
Add branch loopback interface
```

## README.md

Kirjoita README-tiedostoon lyhyt raportti harjoituksen suorittamisesta.

Vastaa raportissa ainakin seuraaviin kysymyksiin:

1. Mitä hyötyä Ansible tarjoaa verrattuna reitittimien käsin konfigurointiin?
2. Mitä Ansiblen idempotenssi tarkoittaa käytännössä?
3. Mitä hyötyä Git-versionhallinnasta on verkkolaitteiden hallinnassa?
4. Miten virtuaalisten FRRouting-reitittimien hallinta eroaa oikeiden verkkolaitteiden hallinnasta?
5. Mitä tapahtui simuloidussa virhetilanteessa ja miten palautit oikean konfiguraation?

Liitä mukaan tarvittavat komentojen tulosteet tai kuvakaappaukset, joilla osoitat tehtävien onnistumisen.

---

## Hyväksytty suoritus

Harjoitus on hyväksytty, kun:

- Ansible-inventaario sisältää kolme reititintä
- Ansible saa yhteyden verkkolaitteisiin
- `facts.yml` kerää vaaditut tiedot
- `backup.yml` tallentaa konfiguraatiot
- `loopback.yml` toteuttaa vaaditun muutoksen
- playbookin uudelleen ajaminen osoittaa idempotenssin
- `verify.yml` tarkistaa muutoksen
- Gitistä näkyvät verkon eri konfiguraatiotilat
- virheellinen konfiguraatio pystytään tunnistamaan ja palauttamaan
- README sisältää lyhyen raportin ja vastaukset kysymyksiin
