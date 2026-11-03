# Teste Roku - Saimo TV

## Objetivo
Checklist manual por epic para validar a migração da arquitetura.

## Gates (cada epic)
- npm run build
- npm run check
- npm run test
- npm run package

### §1 E1 - Router shell + Storage base
Parte A: o app sideloada e os settings/favoritos existentes sobrevivem.
Parte B: cada aba roteia para seu placeholder; relógio, foco e back funcionam no aparelho.

### §2 E2 - Data dispatcher
Canais carregam; ops de guia, rádios e eventos retornam dados ou vazio gracioso.

### §3 E3 - Tela de favoritos
Pré-popule favorites/vodFavorites; abra Favoritos; verifique contagem "N títulos", linhas Canais e Filmes e séries; selecione canal (roteia ao Ao Vivo) e VOD (roteia à Ficha); estado vazio quando sem favoritos; hop de foco para cima.

### §4 E4 - Tela de busca
Rotina manual:
1. Abra a busca do menu; confirme o teclado à esquerda e campo vazio com dica "Digite o nome...".
2. Digite algumas letras de um filme conhecido; resultados aparecem enquanto digita nos canais e em "Filmes e séries".
3. Teste acentos: buscar "cidade" deve encontrar "Cidade de Deus".
4. Abra antes do cache existir (limpar cachefs) e repita: deve disparar a busca remota uma vez após 0,3 s de pausa, sem travar.
5. Selecione canal -> roteia ao Ao Vivo; selecione VOD -> roteia à Ficha.
6. Teclas up foco para o menu superior; left/back retorna ao teclado.
7. Sem índice, o lado VOD mostra "Nada encontrado." sem queda do app.

### §5 E5 - Home + VOD + ficha mínima
Quatro fileiras visíveis; troca de categoria em On Demand; VOD -> ficha -> Assistir.

### §6 E6 - Live + Guide
Drawer, reprodução ao vivo, troca de fonte, guia abre de Ao vivo.

### §7 E7 - ZapHUD + PIN
Zap HUD em 3 canais; canal restrito bloqueia e desbloqueia; PIN persiste.

### §8 E8 - Rádios
Tocar 2 estações, troca rápida, back para áudio.

### §9 E9 - Eventos + Minhas listas
Eventos renderizam; CRUD de lista ponta a ponta; canais mesclados reproduzem.

### §10 E10 - Player
OSD, seek, auto-next, erro e foco de saída.

### §11 E11 - Ficha + Settings + versão
Ficha de filme e série com 3+ temporadas; resume de episódio parcial; settings e versão 2.6.0.

### §12 E12 - Saimo Connect
Parear telefone, navegar por cada aba, sincronia de estado.