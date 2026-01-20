#!/usr/bin/env bash
# oc.sh — picker de projetos OpenCode baseado em diretórios ".opencode"
# Requisitos: fd, fzf, opencode
#
# Uso (recomendado):
#   source /caminho/para/oc.sh
#   oc
#
# Uso (executável):
#   chmod +x oc.sh
#   ./oc.sh

# Defaults (sobrescreva via env se quiser)
: "${OC_ROOT:=$HOME}"
: "${OC_EXCLUDES:=.git node_modules .cache}"
: "${OC_FZF_OPTS:=--prompt=oc\>\ }"

oc_list_projects() {
  # Lista diretórios de projeto (pai do ".opencode"), deduplicados
  # NUL-safe para caminhos com espaços
  local root="$OC_ROOT"
  local -a excludes
  # shellcheck disable=SC2206
  excludes=($OC_EXCLUDES)

  if ! command -v fd >/dev/null 2>&1; then
    echo "Erro: 'fd' não encontrado no PATH." >&2
    return 127
  fi

  if ! command -v dirname >/dev/null 2>&1; then
    echo "Erro: 'dirname' não encontrado." >&2
    return 127
  fi

  # Monta args de exclude
  local -a fd_ex
  fd_ex=()
  local ex
  for ex in "${excludes[@]}"; do
    fd_ex+=(--exclude "$ex")
  done

  fd -HI -t d '^\.opencode$' "$root" "${fd_ex[@]}" -0 \
    | xargs -0 -n 1 dirname \
    | sort -u
}

oc_pick_project() {
  # Seleciona um diretório via fzf
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Erro: 'fzf' não encontrado no PATH." >&2
    return 127
  fi

  oc_list_projects | fzf $OC_FZF_OPTS
}

oc() {
  # Abre o projeto selecionado no OpenCode
  local dir
  dir="$(oc_pick_project)" || return $?
  [[ -n "$dir" ]] || return 1

  if ! command -v opencode >/dev/null 2>&1; then
    echo "Erro: 'opencode' não encontrado no PATH." >&2
    return 127
  fi

  (cd -- "$dir" && opencode .)
}


ocz() {
  # Abre o projeto selecionado no Zed
  local dir
  dir="$(oc_pick_project)" || return $?
  [[ -n "$dir" ]] || return 1

  if ! command -v zed >/dev/null 2>&1; then
    echo "Erro: 'zed' não encontrado no PATH." >&2
    return 127
  fi

  zed "$dir"
}

oczc() {
  # Abre a pasta .opencode do projeto selecionado no Zed (fallback: abre o projeto)
  local dir
  dir="$(oc_pick_project)" || return $?
  [[ -n "$dir" ]] || return 1

  if ! command -v zed >/dev/null 2>&1; then
    echo "Erro: 'zed' não encontrado no PATH." >&2
    return 127
  fi

  if [[ -d "$dir/.opencode" ]]; then
    zed "$dir/.opencode"
  else
    echo "Aviso: não encontrei .opencode em: $dir" >&2
    zed "$dir"
  fi
}

oc_main() {
  case "${1:-}" in
    -h|--help)
      cat <<'EOF'
oc.sh — picker de projetos OpenCode baseado em diretórios ".opencode"

Requisitos: fd, fzf, opencode

Comandos:
  oc              abre um projeto escolhido no OpenCode
  ocz             abre um projeto escolhido no Zed
  oczc            abre a pasta .opencode do projeto escolhido no Zed
  oc_main --list  lista os diretórios de projetos encontrados
  oc_main --print imprime o diretório escolhido (não abre)
  oc_main --zed   escolhe e abre no Zed (projeto)
  oc_main --zed-config escolhe e abre no Zed (pasta .opencode)
  oc_main --help  esta ajuda

Variáveis de ambiente:
  OC_ROOT        raiz do scan (default: $HOME)
  OC_EXCLUDES    nomes a excluir (default: ".git node_modules .cache")
  OC_FZF_OPTS    opções extras para o fzf (default: "--prompt=oc> ")

Exemplos:
  OC_ROOT="$HOME/hetosoft" oc
  OC_FZF_OPTS="--height=80% --layout=reverse --border" oc
  OC_ROOT="$HOME/hetosoft" ocz
  OC_ROOT="$HOME/hetosoft" oczc
EOF
      ;;
    --list)
      oc_list_projects
      ;;
    --print)
      oc_pick_project
      ;;
    --zed)
      ocz
      ;;
    --zed-config)
      oczc
      ;;
    "")
      oc
      ;;
    *)
      echo "Arg desconhecido: $1 (use --help)" >&2
      return 2
      ;;
  esac
}

# Se for executado diretamente, roda oc_main.
# Se for "source", apenas define as funções.
if (return 0 2>/dev/null); then
  : # sourced
else
  oc_main "$@"
fi
