mkdir -p /var/lib/nix
mkdir -p /nix

declare -A paths=(
['/nix/store/[^/]+/etc(/.*)?']=etc_t
['/nix/store/[^/]+/lib(/.*)?']=lib_t
['/nix/store/[^/]+/lib/systemd/system(/.*)?']=systemd_unit_file_t
['/nix/store/[^/]+/man(/.*)?']=man_t
['/nix/store/[^/]+/s?bin(/.*)?']=bin_t
['/nix/store/[^/]+/share(/.*)?']=usr_t
['/nix/var/nix/daemon-socket(/.*)?']=var_run_t
['/nix/var/nix/profiles(/per-user/[^/]+)?/[^/]+']=usr_t
)

for prefix in '' '/var/lib'; do
  for path in "${!paths[@]}"; do
    semanage fcontext -a -t "${paths[$path]}" "$prefix$path"
  done
done

systemctl enable nix.mount
restorecon -RF /nix
