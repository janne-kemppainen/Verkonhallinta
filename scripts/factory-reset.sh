#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOPOLOGY_FILE="${ROOT_DIR}/topology/golden.clab.yml"
NETBOX_COMPOSE_FILE="${ROOT_DIR}/configs/netbox/docker-compose.yml"
NETBOX_ENV_FILE="${ROOT_DIR}/configs/netbox/.env"
NETBOX_ENV_TEMPLATE="${ROOT_DIR}/configs/netbox/example.environment"
CONFIRMED=0
LAB_NAME="hamk-verkonhallinta-golden"

usage() {
  cat <<'EOF'
Usage: scripts/factory-reset.sh [--yes]

Stops and removes the lab and its saved runtime state:
  - Containerlab topology and management network
  - NetBox Compose containers, networks, and named volumes
  - All student-state and snapshot backups
  - Per-student persisted Docker images
  - Monitoring data and generated Ansible facts
  - Generated per-student topology files

This operation is irreversible. Source configuration, documentation,
NetBox .env credentials, and tracked files are preserved.
Use --yes to skip the interactive confirmation.
EOF
}

while (($#)); do
  case "$1" in
    --yes)
      CONFIRMED=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Tuntematon argumentti: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

echo "VAROITUS: Factory reset poistaa labran tallennetun tilan pysyvästi."
echo "Poistettavia ovat kaikkien opiskelijoiden tallennukset, Docker-kuvat,"
echo "monitorointidata, NetBox-tietokanta ja snapshot-varmuuskopiot."
echo "Lähdekoodia ja NetBoxin .env-tiedostoa ei poisteta."

if ((CONFIRMED == 0)); then
  if [[ ! -t 0 ]]; then
    echo "[ERROR] Ei-interaktiivinen ajo vaatii argumentin --yes." >&2
    exit 2
  fi
  read -r -p "Vahvista kirjoittamalla FACTORY-RESET: " answer
  if [[ "${answer}" != "FACTORY-RESET" ]]; then
    echo "[INFO] Peruutettu; mitään ei poistettu."
    exit 0
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker-komentoa ei löydy; resetiä ei voida suorittaa." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker-daemoniin ei saada yhteyttä; resetiä ei aloitettu." >&2
  exit 1
fi

LAB_CONTAINERS="$(docker ps -aq --filter "name=clab-${LAB_NAME}")"
if [[ -n "${LAB_CONTAINERS}" ]] && ! command -v containerlab >/dev/null 2>&1; then
  echo "[ERROR] Containerlab-komentoa ei löydy; resetiä ei aloitettu." >&2
  exit 1
fi

if [[ -n "${LAB_CONTAINERS}" ]]; then
  if ! command -v sudo >/dev/null 2>&1 || ! sudo -v; then
    echo "[ERROR] Sudo-oikeuksia ei saatu; resetiä ei aloitettu." >&2
    exit 1
  fi
fi

if [[ -f "${NETBOX_COMPOSE_FILE}" ]] \
  && ! docker compose version >/dev/null 2>&1 \
  && ! command -v docker-compose >/dev/null 2>&1; then
  echo "[ERROR] Docker Composea ei löydy; resetiä ei aloitettu." >&2
  exit 1
fi

echo "[INFO] Pysäytetään ja poistetaan NetBox sekä sen tietovolyymejä..."
if [[ -f "${NETBOX_COMPOSE_FILE}" ]]; then
  compose_args=(-f "${NETBOX_COMPOSE_FILE}")
  if [[ -f "${NETBOX_ENV_FILE}" ]]; then
    compose_args+=(--env-file "${NETBOX_ENV_FILE}")
  elif [[ -f "${NETBOX_ENV_TEMPLATE}" ]]; then
    compose_args+=(--env-file "${NETBOX_ENV_TEMPLATE}")
  fi
  if docker compose version >/dev/null 2>&1; then
    docker compose "${compose_args[@]}" down --volumes --remove-orphans
  else
    docker-compose "${compose_args[@]}" down --volumes --remove-orphans
  fi
fi

echo "[INFO] Poistetaan Containerlab-ympäristö..."
if [[ -n "${LAB_CONTAINERS}" ]]; then
  sudo containerlab destroy -t "${TOPOLOGY_FILE}" --cleanup
else
  echo "[INFO] Labran kontteja ei löytynyt."
fi

echo "[INFO] Poistetaan opiskelijoiden tallennukset ja snapshotit..."
if [[ -d "${ROOT_DIR}/student-state" ]]; then
  find "${ROOT_DIR}/student-state" -mindepth 1 -maxdepth 1 \
    ! -name README.md -exec rm -rf -- {} +
fi
rm -rf -- "${ROOT_DIR}/.snapshots"

echo "[INFO] Poistetaan monitorointidata..."
rm -rf -- \
  "${ROOT_DIR}/state/management/prometheus-data" \
  "${ROOT_DIR}/state/management/grafana-data" \
  "${ROOT_DIR}/state/management/zabbix-data" \
  "${ROOT_DIR}/state/management/zabbix-mysql"

if [[ -d "${ROOT_DIR}/state/client1" ]]; then
  find "${ROOT_DIR}/state/client1" -mindepth 1 -maxdepth 1 \
    ! -name README.txt -exec rm -rf -- {} +
fi

if [[ -d "${ROOT_DIR}/configs/ansible/facts" ]]; then
  find "${ROOT_DIR}/configs/ansible/facts" -mindepth 1 -exec rm -rf -- {} +
fi

while IFS= read -r -d '' generated_topology; do
  rm -f -- "${generated_topology}"
done < <(find "${ROOT_DIR}/topology" -maxdepth 1 -type f \
  -name 'golden.*.clab.yml' -print0)

echo "[INFO] Poistetaan opiskelijakohtaiset tallennetut Docker-kuvat..."
while IFS= read -r image; do
  [[ -n "${image}" ]] || continue
  if [[ "${image}" =~ ^clab-persist-[[:alnum:]_.-]+-(client1|attacker|branch-client|web1|db1):[^[:space:]]+$ ]]; then
    docker image rm "${image}"
  fi
done < <(docker image ls --format '{{.Repository}}:{{.Tag}}')

echo "[OK] Factory reset valmis."
echo "[INFO] NetBoxin .env sekä lähdekoodit ja dokumentaatio säilytettiin."
