# Pilviverkkojen valvonta, tietoturva ja SIEM-ajattelu

Tässä materiaalissa tarkastellaan pilviverkkojen valvontaa ja tietoturvaa verkonhallinnan näkökulmasta. Pilviympäristöjen kasvaessa verkonvalvojan rooli ei enää keskity pelkästään reititykseen tai laitteiden ylläpitoon, vaan jatkuvaan näkyvyyteen, uhkien tunnistamiseen, tapahtumien analysointiin sekä tietoturvapoikkeamien käsittelyyn.

Materiaalin pääpaino on SOC- (Security Operations Center) ja SIEM-ajattelussa sekä siinä, kuinka pilviverkkojen lokeja, mittareita ja tapahtumia hyödynnetään organisaation tietoturvan ylläpitämisessä.

---

## 1. Miksi pilviverkkojen valvonta on tärkeää?

Perinteisissä ympäristöissä verkkovalvoja hallitsi fyysisiä laitteita, kaapelointeja, palvelimia ja verkkolaitteita. Pilvipalveluissa suuri osa infrastruktuurista on piilotettu palveluntarjoajan hallintaan.

Tämän vuoksi näkyvyys toteutetaan:

- lokien avulla
- suorituskykymetriikoiden avulla
- Flow Logeilla
- turvallisuushälytyksillä
- SIEM-järjestelmien avulla

Verkkovalvojan keskeiset kysymykset:

- Onko palvelu käytettävissä?
- Toimiiko VPN-yhteys?
- Kuka käyttää palvelua?
- Onko liikenne normaalia?
- Onko havaittavissa tietomurron merkkejä?

---

## 2. Pilviverkkojen monitorointi

### Azure

- Azure Monitor
- Log Analytics
- Network Watcher
- NSG Flow Logs
- Azure VPN Gateway Diagnostics

Microsoft Learn:

- [Azure Monitor Overview](https://learn.microsoft.com/azure/azure-monitor/overview)
- [Azure Network Watcher](https://learn.microsoft.com/azure/network-watcher/network-watcher-overview)
- [NSG Flow Logs](https://learn.microsoft.com/azure/network-watcher/nsg-flow-logs-overview)

### AWS

- Amazon CloudWatch
- VPC Flow Logs
- CloudTrail
- GuardDuty
- Security Hub

AWS Documentation:

- [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html)
- [Amazon GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html)

---

## 3. Zero Trust -ajattelu

Zero Trust perustuu ajatukseen:

> Never trust, always verify.

Mikään käyttäjä, laite tai sovellus ei ole automaattisesti luotettu. Jokainen yhteys on arvioitava erikseen.

### Zero Trust -periaatteet

- Verify Explicitly
- Use Least Privilege Access
- Assume Breach

### Miksi tämä on tärkeää?

Pilviympäristöissä perinteinen sisäverkko–ulkoverkko-ajattelu ei enää toimi. Käyttäjät, sovellukset ja palvelut voivat sijaita useissa pilvissä tai organisaation ulkopuolella.

Lisätietoa:

- [Microsoft Zero Trust](https://www.microsoft.com/en-us/security/business/zero-trust)
- [NIST SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final)

---

## 4. NAC ja 802.1X

### NAC (Network Access Control)

NAC-järjestelmien tarkoituksena on päättää, saako laite liittyä verkkoon.

Tyypillisiä tarkastuksia:

- käyttäjän identiteetti
- laitteen omistajuus
- päivitysten taso
- virustorjunnan tila

### 802.1X

802.1X mahdollistaa käyttäjä- tai laitekohtaisen todennuksen ennen kuin verkkoyhteys sallitaan.

```
Client
  |
802.1X
  |
Switch
  |
RADIUS
```

Lisätietoa:

- [Cisco Identity Services Engine](https://www.cisco.com/site/us/en/products/security/identity-services-engine/index.html)
- [Network Policy Server](https://learn.microsoft.com/windows-server/networking/technologies/nps/nps-top)

---

## 5. Segmentointi ja mikrosegmentointi

Segmentoinnin tarkoituksena on estää hyökkääjän eteneminen verkossa.

### Perinteinen segmentointi

- VLAN-alueet
- Palomuurisäännöt
- DMZ-verkot

### Pilviverkkojen segmentointi

- Azure VNet ja Subnet
- Network Security Groups (NSG)
- AWS VPC ja Subnet
- Security Groups

### Mikrosegmentointi

Zero Trust -ympäristöissä myös palvelinten välinen liikenne rajataan.

```
WEB → APP → DATABASE
```

Jokainen yhteys sallitaan erikseen.

---

## 6. SIEM-ajattelu

SIEM (Security Information and Event Management) on tietoturvan keskeisimpiä teknologioita.

Sen tehtävänä on:

- kerätä lokeja
- yhdistää tapahtumia
- havaita poikkeamia
- tuottaa hälytyksiä

### Vaihe 1: Lokien kerääminen

Tyypillisiä lähteitä:

- Azure Monitor
- CloudWatch
- CloudTrail
- VPC Flow Logs
- NSG Flow Logs
- VPN-lokit
- Windows Event Logs
- Syslog

### Vaihe 2: Lokien analysointi

Yksittäinen epäonnistunut kirjautuminen ei välttämättä tarkoita mitään. Satojen epäonnistuneiden kirjautumisten havaitseminen voi viitata salasanahyökkäykseen.

### Vaihe 3: Korrelaatio

SIEM ei tarkastele yksittäisiä tapahtumia vaan niiden yhteyksiä.

```
VPN Login Success

+
NSG Flow Log Reject

+
Large Data Transfer

=
Potential Incident
```

Tämä on nykyaikaisen SOC-toiminnan ydin.

---

## 7. SOC (Security Operations Center)

SOC vastaa organisaation tietoturvan jatkuvasta valvonnasta.

### SOC:n tärkeimmät tehtävät

- valvonta
- uhkien tunnistaminen
- hälytyksiin reagointi
- tapauksien tutkinta
- raportointi

### Tyypillinen SOC-työnkulku

```
Logs
  ↓

SIEM
  ↓

Alert
  ↓

Investigation
  ↓

Response
```

---

## 8. Keskeiset SIEM-ratkaisut

- Microsoft Sentinel
- Splunk Enterprise Security
- IBM QRadar
- Elastic Security
- Wazuh
- Google SecOps

Tutustu:

- [Microsoft Sentinel](https://learn.microsoft.com/azure/sentinel/overview)
- [Elastic Security](https://www.elastic.co/security)
- [Wazuh](https://wazuh.com/platform/)
- [Splunk Enterprise Security](https://www.splunk.com/en_us/products/enterprise-security.html)

---

## 9. Itsenäinen syventävä opiskelu

### Pakollinen

- Lue [NIST SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final)
- Tutustu Microsoft Sentineliin
- Tutustu AWS GuardDutyyn
- Selvitä mitä tietoa VPC Flow Log sisältää

### Suositeltava syventävä materiaali

- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [CISA Zero Trust Maturity Model](https://www.cisa.gov/resources-tools/resources/zero-trust-maturity-model)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Hack The Box Academy](https://academy.hackthebox.com/)
- [SANS White Papers](https://www.sans.org/white-papers/)

---

## Yhteenveto

Nykyaikainen verkkovalvoja ei enää valvo ainoastaan verkkolaitteita, vaan pilviympäristöjä, palveluita, käyttäjiä ja tietoturvatapahtumia. Zero Trust, SIEM-järjestelmät, pilvilokit sekä SOC-ajattelu muodostavat nykyaikaisen verkonhallinnan perustan. Organisaatiot tarvitsevat osaajia, jotka kykenevät yhdistämään verkkoteknologian, monitoroinnin, tietoturvan ja tietoturvatapahtumien analysoinnin yhdeksi kokonaisuudeksi.
