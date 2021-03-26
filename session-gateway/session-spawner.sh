#!/bin/bash

set -xe

export rm=${rm:-false}
export template=${template:-session.yaml}
export image=${image:-'ubuntu:latest'}

create_session() {

  uid=$(id -u $USER)
  gid=$(id -g $USER)
  sup_gid=$(id -G $USER | sed "s/ /, /g" )
  shell=$(getent passwd $USER |  cut -d : -f 7)

  echo "[$(date)][INFO] Starting session instance with image $image, rm: $rm"
  sed -e "s/__UID__/$uid/g" -e "s/__USER__/$USER/g" \
    -e "s/__GID__/$gid/g" -e "s/__SUP_GID__/$sup_gid/g" \
    -e "s/__IMAGE__/$image/g" \
    -e "s|__SHELL__|$shell|g" \
    "/templates/$template" \
  | kubectl create -f -

}


main() {

  # search for existing pod for user
  pod_name=$(kubectl get pods -l app=session-host,user="$USER" --output=jsonpath='{.items..metadata.name}')

  # if we have a pod, then see if it should be purged
  if [ "$pod_name" != "" ]; then

    if [ "$rm" = "true" ]; then

      echo "[$(date)][INFO] Deleting previous instance.."
      kubectl delete deployment "$USER"
      while ! kubectl get pod -l "app=session-host,user=$USER" --no-headers=true 2>&1 \
            | grep -q "No resources found"; do
        echo "[$(date)][INFO] Waiting for Pod to terminate..."
        sleep 5
      done

      create_session

    fi

  else

    create_session

  fi

  # use attach to connect to terminal of session
  echo "[$(date)][INFO] Attaching to existing session instance $pod_name"
  # TODO implement timeout
  while ! kubectl get pod -l "app=session-host,user=$USER" --no-headers=true 2>&1 \
    | grep -q Running; do
    echo "waiting..."
    sleep 1
  done
  pod_name=$(kubectl get pods -l app=session-host,user="$USER" --output=jsonpath='{.items..metadata.name}')
  exec kubectl attach "$pod_name" -it -c "session"

}

main "$@"
