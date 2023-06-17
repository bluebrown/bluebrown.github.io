# Bash Magic

This post contains a loose collection of useful stuff when it comes to bash
scripting.

## Shebang

<table><thead><tr><th>Bad</th><th>Good</th></tr></thead><tbody><tr><td>

```shell
#!/bin/bash
```

</td><td>

```shell
#!/usr/bin/env bash
```

</td></tr></tbody></table>

## Script Path

```bash
script_abs="$(readlink -f "$0")"
script_name="$(basename "$script_abs")"
script_dir="$(dirname "$script_abs")"
```

## Getopts Example

Sometimes scripts become more complex and should accept parameters.
Below some boilerplate code showing how one could create a production
grade script.

```bash
#!/usr/bin/env bash
set -o nounset -o errexit -o errtrace -o pipefail

usage="$(basename "$0") [-h] [-v kube_version] [-n cluster_name]
"
description="Create a local development cluster using k3d.
The cluster is pre configured to faccilitate a pimcore stack deployment.
"
options="
  -v        kubernetes version (default: ${kube_version:=1.24.6})
  -n        cluster name (default: ${cluster_name:=devel})
  -h        print this help text
"

die() {
  echo -en "\n$1"
  exit 1
}

while getopts ':hn:v:' opt; do
  case "$opt" in
  v) kube_version="$OPTARG" ;;
  n) cluster_name="$OPTARG" ;;
  h) die "Usage: $usage\n$description\nOptions:$options" ;;
  ?) die "Usage: $usage" ;;
  esac
done
shift "$((OPTIND - 1))"

echo "kube version: $kube_version"
echo "cluster name: $cluster_name"

```

## Hostname Spoofing with Curl

<table><thead><tr><th>Bad</th><th>Good</th></tr></thead><tbody><tr><td>

```bash
curl \
  --header 'Host: example.com' \
  --url 127.0.0.1
```

</td><td>

```bash
curl \
  --resolve example.com:80:127.0.0.1 \
  --url example.com
```

</td></tr></tbody></table>

## References

- [Set Options](http://www.linuxcommand.org/lc3_man_pages/seth.html)
- [Parameter Expansion](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02)
- [Usage Texts](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_01)
- [Issues with set -e](https://mywiki.wooledge.org/BashFAQ/105)
