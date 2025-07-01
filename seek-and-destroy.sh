#!/bin/bash

# Função para verificar se o diretório existe e tem permissão de leitura/escrita
verificar_permissao() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "❌ O caminho '$dir' não é um diretório válido."
    return 1
  fi
  if [ ! -r "$dir" ]; then
    echo "❌ Você não tem permissão de leitura no diretório '$dir'."
    return 1
  fi
  if [ ! -w "$dir" ]; then
    echo "⚠️ Aviso: Você não tem permissão de escrita no diretório '$dir'. Substituições podem falhar."
  fi
  return 0
}

# Função para perguntar uma opção (Voltar / Avançar)
opcoes_avancar_voltar() {
  while true; do
    echo ""
    echo "Opções:"
    echo "1) Avançar"
    echo "2) Voltar"
    read -p "Escolha uma opção (1 ou 2): " opcao
    case "$opcao" in
      1) return 0 ;;
      2) return 1 ;;
      *) echo "⚠️ Opção inválida. Digite 1 ou 2." ;;
    esac
  done
}

# Função para validar entrada não vazia
ler_entrada_valida() {
  local mensagem="$1"
  local variavel_saida="$2"
  local valor=""

  while true; do
    read -p "$mensagem" valor
    if [[ -z "$valor" ]]; then
      echo "⚠️ Campo obrigatório. Não pode ser vazio."
    else
      eval "$variavel_saida"='"$valor"'
      break
    fi
  done
}

# Início do fluxo interativo
echo "🔎 Script Interativo de Substituição de Texto em Arquivos PHP"
echo ""

# Passo 1: Caminho do diretório
while true; do
  ler_entrada_valida "Digite o caminho do diretório: " DIRETORIO

  # Expandindo ~ para home do usuário
  DIRETORIO=$(eval echo "$DIRETORIO")

  verificar_permissao "$DIRETORIO"
  perm_ok=$?

  echo ""
  if [ $perm_ok -ne 0 ]; then
    echo "Tente novamente ou selecione outro diretório."
    continue
  fi

  echo "O diretório '$DIRETORIO' foi verificado com sucesso."

  if opcoes_avancar_voltar; then
    break
  fi
done

# Passo 2: Texto a ser pesquisado
while true; do
  ler_entrada_valida "Texto a ser pesquisado: " BUSCA

  echo ""
  echo "Você digitou: '$BUSCA'"
  if opcoes_avancar_voltar; then
    break
  fi
done

# Passo 3: Texto de substituição
while true; do
  ler_entrada_valida "Substituir por: " SUBSTITUICAO

  echo ""
  echo "Você digitou: '$SUBSTITUICAO'"
  if opcoes_avancar_voltar; then
    break
  fi
done

# Passo 4: Modo teste ou execução real
TESTE=false
while true; do
  echo ""
  echo "Executar em modo teste? (mostra os arquivos que seriam alterados)"
  echo "1) Sim (modo teste)"
  echo "2) Não (executar substituição real)"
  read -p "Escolha uma opção (1 ou 2): " modo_teste
  case "$modo_teste" in
    1) TESTE=true ; break ;;
    2) TESTE=false ; break ;;
    *) echo "⚠️ Opção inválida. Digite 1 ou 2." ;;
  esac
done

# Passo 5: Criar backup?
CRIAR_BACKUP=false
if [ "$TESTE" = false ]; then
  while true; do
    echo ""
    echo "Deseja criar backup dos arquivos antes de modificá-los?"
    echo "1) Sim"
    echo "2) Não"
    read -p "Escolha uma opção (1 ou 2): " modo_backup
    case "$modo_backup" in
      1) CRIAR_BACKUP=true ; break ;;
      2) CRIAR_BACKUP=false ; break ;;
      *) echo "⚠️ Opção inválida. Digite 1 ou 2." ;;
    esac
  done
fi

# Busca os arquivos PHP com a string BUSCA
ARQUIVOS=$(find "$DIRETORIO" -type f -name "*.php" -exec grep -l "$BUSCA" {} + 2>/dev/null)

# Se não encontrou nenhum arquivo
if [ -z "$ARQUIVOS" ]; then
  echo ""
  echo "✅ Nenhum arquivo encontrado em '$DIRETORIO' contendo '$BUSCA'."
  exit 0
fi

# Exibe os arquivos encontrados
echo ""
echo "📄 Arquivos encontrados com '$BUSCA':"
echo "$ARQUIVOS"
echo ""

# Confirmação antes da substituição (se não for modo teste)
if [ "$TESTE" = false ]; then
  echo ""
  read -p "Deseja realmente substituir '$BUSCA' por '$SUBSTITUICAO' nesses arquivos? (s/n): " CONFIRMA
  if [[ "$CONFIRMA" != "s" && "$CONFIRMA" != "S" ]]; then
    echo "❌ Operação cancelada."
    exit 0
  fi
fi

# Realiza a substituição ou mostra o comando apenas no modo teste
echo ""
echo "🔄 Processando arquivos..."
echo "$ARQUIVOS" | while IFS= read -r ARQ; do
  if [ "$TESTE" = true ]; then
    echo "🧪 [Teste] Seria alterado: $ARQ"
  else
    if [ "$CRIAR_BACKUP" = true ]; then
      cp "$ARQ" "$ARQ.bak"
      if [ $? -eq 0 ]; then
        echo "💾 Backup criado: $ARQ.bak"
      else
        echo "❌ Falha ao criar backup de: $ARQ"
      fi
    fi
    sed -i "s/$BUSCA/$SUBSTITUICAO/g" "$ARQ"
    echo "✅ Alterado: $ARQ"
  fi
done

echo ""
echo "🎉 Concluído!"
