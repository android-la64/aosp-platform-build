function _source_env_setup_script() {
  local -r ENV_SETUP_SCRIPT="build/make/envsetup.sh"
  local -r TOP_DIR=$(
    while [[ ! -f "${ENV_SETUP_SCRIPT}" ]] && [[ "${PWD}" != "/" ]]; do
      \cd ..
    done
    if [[ -f "${ENV_SETUP_SCRIPT}" ]]; then
      echo "$(PWD= /bin/pwd -P)"
    fi
  )

  local -r FULL_PATH_ENV_SETUP_SCRIPT="${TOP_DIR}/${ENV_SETUP_SCRIPT}"
  if [[ ! -f "${FULL_PATH_ENV_SETUP_SCRIPT}" ]]; then
    echo "ERROR: Unable to source ${ENV_SETUP_SCRIPT}"
    return 1
  fi

  # Need to change directory to the repo root so vendor scripts can be sourced
  # as well.
  local -r CUR_DIR=$PWD
  \cd "${TOP_DIR}"
  source "${FULL_PATH_ENV_SETUP_SCRIPT}"
  \cd "${CUR_DIR}"
}

# This function needs to run first as the remaining defining functions may be
# using the envsetup.sh defined functions. Skip this part if this script is already
# being invoked from envsetup.sh.
if [[ "$1" != "--skip-envsetup" ]]; then
  _source_env_setup_script || return
fi

# This function prefixes the given command with appropriate variables needed
# for the build to be executed with RBE.
function use_rbe() {
  local RBE_BINARIES_DIR="prebuilts/remoteexecution-client/latest"
  local DOCKER_IMAGE="gcr.io/androidbuild-re-dockerimage/android-build-remoteexec-image@sha256:953fed4a6b2501256a0d17f055dc17884ff71b024e50ade773e0b348a6c303e6"

  # Do not set an invocation-ID and let reproxy auto-generate one.
  USE_RBE="true" \
  FLAG_exec_root="$(gettop)" \
  FLAG_platform="container-image=docker://${DOCKER_IMAGE}" \
  RBE_use_application_default_credentials="true" \
  RBE_reproxy_wait_seconds="20" \
  RBE_CXX_EXEC_STRATEGY="remote_local_fallback" \
  RBE_cpp_dependency_scanner_plugin="${RBE_BINARIES_DIR}/dependency_scanner_go_plugin.so" \
  RBE_DIR=${RBE_BINARIES_DIR} \
  RBE_re_proxy="${RBE_BINARIES_DIR}/reproxy" \
  $@
}

# This function detects if the uploader is available and sets the path of it to
# ANDROID_ENABLE_METRICS_UPLOAD.
function _export_metrics_uploader() {
  local uploader_path="$(gettop)/vendor/google/misc/metrics_uploader_prebuilt/metrics_uploader.sh"
  if [[ -x "${uploader_path}" ]]; then
    export ANDROID_ENABLE_METRICS_UPLOAD="${uploader_path}"
  fi
}

# This function sets RBE specific environment variables needed for the build to
# executed by RBE. This file should be sourced once per checkout of Android code.
function _set_rbe_vars() {
  unset USE_GOMA
  export USE_RBE="true"
  export RBE_CXX_EXEC_STRATEGY="racing"
  export RBE_JAVAC_EXEC_STRATEGY="racing"
  export RBE_R8_EXEC_STRATEGY="racing"
  export RBE_D8_EXEC_STRATEGY="racing"
  export RBE_use_unified_cas_ops="true"
  export RBE_JAVAC=1
  export RBE_R8=1
  export RBE_D8=1
}

_export_metrics_uploader
_set_rbe_vars
