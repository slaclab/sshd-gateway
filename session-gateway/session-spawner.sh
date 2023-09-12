#!/bin/bash

# set -x

export rm=${rm:-false}
export template=${template:-"default"}
export image=${image:-"slaclab/login-rocky8:latest"}
export session=${session:-""}
export control_mode=${control_mode:-""}

export SEARCH_STRING="app=session-host,user=$USER,template=$template"
export ALLOWLIST="/config/allowlist.txt"

export WAIT_TIME=30


create_pod() {

  local getent=$(getent passwd $USER)
  local first_user=${USER:0:1}
  local uid=$( echo "$getent" | cut -d : -f 3)
  local gid=$( echo "$getent" | cut -d : -f 4)
  local sup_gid=$(id -G $USER | sed "s/ /, /g" )
  local shell=$(echo "$getent" |  cut -d : -f 7)
  local home=$(echo "$getent" | cut -d : -f 6)
  local sssd_cm=$(kubectl get cm --sort-by=.metadata.creationTimestamp -o name | grep sssd | sed 's|configmap/||g' | head -n 1)

  # if template is not 'default' then check the allowlist.txt
  if [ "$template" != "default" ]; then
    local allowed=$(grep $USER $ALLOWLIST | grep $template | wc -l)
    if [ "$allowed" -eq "0" ]; then
      echo "ERROR: user $USER is not permitted to use template $template. Exiting."
      exit 128
    fi
  fi

  if [ ! -f "/templates/$template.yaml" ]; then
    echo "ERROR: template $template not found! Exiting."
    exit 64
  fi

  echo "Starting container with image $image using template $template..."
  sed -e "s|__UID__|$uid|g" -e "s|__FIRST_USER__|$first_user|g" -e "s|__USER__|$USER|g" -e "s|__HOME__|$home|g" \
    -e "s|__GID__|$gid|g" -e "s|__SUP_GID__|$sup_gid|g" \
    -e "s|__IMAGE__|$image|g" -e "s|__SESSION__|$session|g" \
    -e "s|__SHELL__|$shell|g" \
    -e "s|__SSSD__|$sssd_cm|g" \
    -e "s|__TEMPLATE__|$template|g" \
    "/templates/$template.yaml" \
  | kubectl create -f -
  local status=$?
  if [ "$status" -ne "0" ]; then
    echo "ERROR: starting container with image $image using template $template..."
    exit 255
  fi
}

attach() {

  # search for existing pod for user
  local pods=$(kubectl get pods -l $SEARCH_STRING --no-headers 2>/dev/null)
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
      kubectl delete pod -l $SEARCH_STRING --force --grace-period 0
      while ! kubectl get pod -l $SEARCH_STRING --no-headers=true 2>&1 \
            | grep -q "No resources found"; do
        #echo "Waiting for Pod to terminate..."
        sleep 1
      done

      create_pod

    fi

  else

    create_pod
    pod_name=$(kubectl get pods -l $SEARCH_STRING --output=jsonpath='{.items..metadata.name}')

  fi

  # use attach to connect to terminal of session
  if [ "$pod_state" != "Running" ]; then
    while ! kubectl get pod -l $SEARCH_STRING --no-headers=true 2>&1 \
      | grep -q Running; do
      #echo "Waiting for container to spawn..."
      if [ $WAIT_TIME -le 0 ]; then
        break
      fi
      WAIT_TIME=$((WAIT_TIME-1))
      sleep 1
    done
  fi

}

tmux() {

  if [ "$control_mode" != "" ]; then
    control_mode="-CC -u"
  fi

  # if a session is not defined, then always create a new tmux session
  if [ "$session" == "" ]; then
    echo "Attempting to reattach to existing session..."
    local session=$(kubectl exec "$pod_name" -it -c tmux -- tmux list-sessions | grep ':' | awk '{print $1}' | sed -e 's/://')
  fi

  if [ ! -z "$session" ]; then
    echo "Attaching to existing tmux session $session..."
    #kubectl exec "$pod_name" -it -c "tmux" -- tmux $control_mode new-session -A -s $session
    kubectl exec "$pod_name" -it -c "tmux" -- tmux $control_mode attach-session -t $session
  else
    echo "Creating new tmux session..."
    kubectl exec "$pod_name" -it -c "tmux" -- tmux $control_mode new-session 
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
  if ! kubectl exec "$pod_name" -c tmux -- bash -c "ps axw | grep [t]mux | grep -v defunct"  2>&1 >/dev/null ; then
    echo "No active sessions left, terminating container..."
    kubectl delete pod "$pod_name" --force --grace-period 0 1>&2 2>&1 >/dev/null
  fi

}

main "$@"
