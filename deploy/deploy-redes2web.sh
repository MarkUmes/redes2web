#!/usr/bin/env bash
set -Eeuo pipefail
exec 9>/var/lock/redes2web-deploy.lock
flock -w 120 9

if [[ $# != 1 || ! "$1" =~ ^(sha256:[a-f0-9]{64})\ ([a-f0-9]{40})$ ]]; then
  echo 'Se requiere digest SHA256 y commit de GitHub.' >&2
  exit 2
fi
DIGEST="${BASH_REMATCH[1]}"
REVISION="${BASH_REMATCH[2]}"
IMAGE="monomark/redes2web@$DIGEST"
NAME=redes2web-aws

echo "Descargando imagen: $IMAGE"
docker pull "$IMAGE"
IMAGE_REVISION=$(docker image inspect "$IMAGE" --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^BUILD_SHA=//p')
[[ "$IMAGE_REVISION" == "$REVISION" ]] || { echo 'El commit de la imagen no coincide.' >&2; exit 1; }

if docker container inspect "$NAME-previous" >/dev/null 2>&1; then
  docker rm "$NAME-previous"
fi
if docker container inspect "$NAME" >/dev/null 2>&1; then
  docker stop "$NAME"
  docker rename "$NAME" "$NAME-previous"
fi

rollback() {
  docker logs "$NAME" || true
  docker rm -f "$NAME" || true
  if docker container inspect "$NAME-previous" >/dev/null 2>&1; then
    docker rename "$NAME-previous" "$NAME"
    docker start "$NAME"
  fi
  echo 'Fallo en verificacion. Restaurada la version anterior.' >&2
}
trap rollback ERR

docker run -d --name "$NAME" --restart unless-stopped \
  --read-only --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --cap-drop ALL --security-opt no-new-privileges \
  --memory 256m --cpus 1 --pids-limit 100 \
  --log-opt max-size=5m --log-opt max-file=2 \
  -p 3300:5000 "$IMAGE"
for attempt in $(seq 1 30); do
  STATUS=$(docker inspect "$NAME" --format '{{.State.Health.Status}}')
  [[ "$STATUS" == healthy ]] && break
  sleep 2
done
[[ "$STATUS" == healthy ]]
curl --fail --silent http://127.0.0.1:3300/health
echo
docker ps --filter "name=^/$NAME$" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
echo "Despliegue verificado en Amazon EC2. Commit: $REVISION"
trap - ERR
