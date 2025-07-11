#!/bin/bash
# Copyright 2024 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. version
echo "kuadrant/must-gather" > /must-gather/version
version >> /must-gather/version

BASE_COLLECTION_PATH="/must-gather"

# make sure we honor --since and --since-time args passed to oc must-gather
# since OCP 4.16
get_log_collection_args() {
  # validation of MUST_GATHER_SINCE and MUST_GATHER_SINCE_TIME is done by the
  # caller (oc adm must-gather) so it's safe to use the values as they are.
  log_collection_args=""

  if [ -n "${MUST_GATHER_SINCE:-}" ]; then
    log_collection_args=--since="${MUST_GATHER_SINCE}"
  fi
  if [ -n "${MUST_GATHER_SINCE_TIME:-}" ]; then
    log_collection_args=--since-time="${MUST_GATHER_SINCE_TIME}"
  fi
}

# Get the CRDs that belong to Kuadrant
function getCRDs() {
  local result=()
  local output
  output=$(oc get crds -o custom-columns=NAME:metadata.name --no-headers | grep '\.kuadrant\.io')
  for crd in ${output}; do
    result+=("${crd}")
  done

  echo "${result[@]}"
}

function getKuadrantNamespaces() {
  local result=()

  for crd in ${crds}; do
    local namespaces=$(oc get ${crd} --all-namespaces -o jsonpath='{.items[*].metadata.namespace}')
    for namespace in ${namespaces}; do
      result+=" ${namespace} "
    done
  done

  echo "$(unique ${result})"
}

# Inspect given resource in given namespace (optional)
# It's using 'oc adm inspect' which will get debug information for given and
# related resources. Including pod logs.
# Since OCP 4.16 it honors '--since' and '--since-time' args
function inspect() {
  local resource ns
  resource=$1
  ns=$2

  echo
  if [ -n "$ns" ]; then
    echo "Inspecting resource ${resource} in namespace ${ns}"
    # it's here just to make the linter happy (we have to use double quotes arround the variable)
    if [ -n "${log_collection_args}" ]
    then
      oc adm inspect "${log_collection_args}" "--dest-dir=${BASE_COLLECTION_PATH}" "${resource}" -n "${ns}"
    else
      oc adm inspect "--dest-dir=${BASE_COLLECTION_PATH}" "${resource}" -n "${ns}"
    fi
  else
    echo "Inspecting resource ${resource}"
    # it's here just to make the linter happy
    if [ -n "${log_collection_args}" ]
    then
      oc adm inspect "${log_collection_args}" "--dest-dir=${BASE_COLLECTION_PATH}" "${resource}"
    else
      oc adm inspect "--dest-dir=${BASE_COLLECTION_PATH}" "${resource}"
    fi
  fi
}

function inspectNamespace() {
  local ns
  ns=$1

  inspect "ns/$ns"
  for crd in $crds; do
    inspect "$crd" "$ns"
  done
  inspect net-attach-def,roles,rolebindings "$ns"
}

function unique() {
  local list="${@}"
  echo "${list[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

function main() {
  local crds
  echo
  echo "Executing Kuadrant gather script"
  echo

  versionFile="${BASE_COLLECTION_PATH}/version"
  echo "Kuadrant/must-gather"> "$versionFile"
  version >> "$versionFile"

  # set global variable which is used when calling 'oc adm inspect'
  get_log_collection_args

  operatorNamespace=$(oc get pods --all-namespaces -l app=kuadrant -o jsonpath="{.items[0].metadata.namespace}")
  # this gets also logs for all pods in that namespace
  inspect "ns/$operatorNamespace"
  inspect clusterserviceversion "${operatorNamespace}"

  inspect nodes

  for r in $(oc get clusterroles,clusterrolebindings -l operators.coreos.com/kuadrant-operator.kuadrant-system -oname); do
    inspect "$r"
  done

  # inspect all kuadrant.io CRDs
  crds="$(getCRDs)"
  for crd in ${crds}; do
    inspect "crd/${crd}"
  done

  kuardantNamespaces="$(getKuadrantNamespaces)"
  for namespace in ${kuardantNamespaces}; do
    inspectNamespace ${namespace}
  done;

echo
echo
echo "Done"
echo
}

main "$@"
