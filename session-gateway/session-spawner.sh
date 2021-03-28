#!/bin/bash

set -x

export rm=${rm:-false}
export template=${template:-session.yaml}
export image=${image:-'slaclab/login-centos7:latest'}
export session=${session:-""}

create_pod() {

  local getent=$(getent passwd $USER)
  local uid=$( echo "$getent" | cut -d : -f 3)
  local gid=$( echo "$getent" | cut -d : -f 4)
  local sup_gid=$(id -G $USER | sed "s/ /, /g" )
  local shell=$(echo "$getent" |  cut -d : -f 7)
  local home=$(echo "$getent" | cut -d : -f 6)
  local sssd_cm=$(kubectl get cm --sort-by=.metadata.creationTimestamp -o name | grep sssd | sed 's|configmap/||g' | head -n 1)
  echo "Starting container with image $image..."
  sed -e "s|__UID__|$uid|g" -e "s|__USER__|$USER|g" -e "s|__HOME__|$home|g" \
    -e "s|__GID__|$gid|g" -e "s|__SUP_GID__|$sup_gid|g" \
    -e "s|__IMAGE__|$image|g" -e "s|__SESSION__|$session|g" \
    -e "s|__SHELL__|$shell|g" \
    -e "s|__SSSD__|$sssd_cm|g" \
    "/templates/$template" \
  | kubectl create -f -

}

attach() {

  # search for existing pod for user
  local pods=$(kubectl get pods -l app=session-host,user="$USER" --no-headers 2>&1)
  pod_name=$(echo "$pods" | awk '{print $1}')
  pod_state=$(echo "$pods" | awk '{print $3}')

  # TODO: cleanup completed pods (where tmux was exited completed
  if [ "$pod_state" == "Completed" ]; then
    rm="true"
  fi

  # if we have a pod, then see if it should be purged
  if [ "$pod_name" != "" ]; then

    if [ "$rm" = "true" ]; then

      echo "Purging previous container.."
      kubectl delete pod -l "app=session-host,user=$USER" --force --grace-period 0
      while ! kubectl get pod -l "app=session-host,user=$USER" --no-headers=true 2>&1 \
            | grep -q "No resources found"; do
        #echo "Waiting for Pod to terminate..."
        sleep 1
      done

      create_pod

    fi

  else

    create_pod
    pod_name=$(kubectl get pods -l app=session-host,user="$USER" --output=jsonpath='{.items..metadata.name}')

  fi

  # use attach to connect to terminal of session
  # TODO implement timeout
  if [ "$pod_state" != "Running" ]; then
    while ! kubectl get pod -l "app=session-host,user=$USER" --no-headers=true 2>&1 \
      | grep -q Running; do
      echo "Waiting for container to spawn..."
      sleep 1
    done
  fi

}

tmux() {

  # if a session is not defined, then always create a new tmux session
  if [ "$session" == "" ]; then
    echo "Creating new tmux session..."
    kubectl exec "$pod_name" -it -c "tmux" -- /bin/tmux new-session -A
  else
    echo "Attaching to existing tmux session $session..."
    kubectl exec "$pod_name" -it -c "tmux" -- /bin/tmux new-session -A -s $session
  fi

}

commandline() {

  # TODO flags for interactive terminal? -it?
  kubectl exec "$pod_name" -c tmux -- $SSH_ORIGINAL_COMMAND
  exit=$?

}

main() {

  # ensure we have an active container
  attach

  # if a command is supplied with the ssh, then execute
  if [[ -n $SSH_ORIGINAL_COMMAND ]]; then

    commandline

  # otherwise create/attach to a tmux session
  else

    tmux

  fi

  # delete pod if its not doing anything
  if ! kubectl exec "$pod_name" -it -c tmux -- pidof tmux 2>&1 >/dev/null ; then
    echo "No active sessions left, terminating container..."
    kubectl delete pod "$pod_name" --force --grace-period 0  2>&1 >/dev/null
  fi

}

main "$@"
