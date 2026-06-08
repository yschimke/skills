
# ===========================================================================
#  FOOTER — run preconditions once, then each registered module in order.
# ===========================================================================
main() {
  log "coo.ee/env ${COOEE_VERSION} — modules: ${MODULES[*]}"
  check_preconditions
  local m
  for m in "${MODULES[@]}"; do
    log "---- module: ${m} --------------------------------"
    "module_${m}"
  done
  echo
  ok "Environment ready: ${MODULES[*]}"
  log "Persisted env -> ${COOEE_PROFILE}"
  log "In a fresh shell:  source ${COOEE_PROFILE}"
}
main "$@"
