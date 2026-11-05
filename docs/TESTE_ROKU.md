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
Side-load build, abra Ao vivo em uma aba e valide:
1. Abra Ao vivo: o vídeo inicia no primeiro canal; drawer de canais aparece com seções em chips e lista; canal focado mostra programa atual e % de progresso quando há EPG.
2. Troque o canal com cima/baixo: ZapHUD exibe número, nome, logotipo e barra do programa, e a função "Sem sinal" tenta proxy/fontes seguintes quando o canal não abre.
3. Abra as fontes (direita): PainelLateral lista as fontes por qualidade e o guia; escolha outra fonte e confirme que o vídeo reabre com a fonte selecionada.
4. Abra o menu contextual (options ou segure OK): favoritar/desfavoritar o canal via replay exibe o toast e persiste em Favoritos; timer de sono e áudio/legenda funcionam.
5. Abra o guia a partir da fonte/modal; guia mostra lista rolável (50 + 40 canais), programa atual/seguinte e %; selecione um canal e confirme que sintoniza esse canal ao fechar o guia.
6. Quando EPG não existir para um canal, exiba "Sem programação para este canal" sem queda do app; canais de 2.000+ itens mantêm rolagem responsiva.
7. Verifique que o guia não aparece nas 8 abas e que, ao sair da guia, a aba "Ao vivo" fica selecionada no menu superior.
8. Canal adulto/protegido bloqueia a reprodução até o PIN "1010" (implementação final em E7).

### §7 E7 - ZapHUD + PIN
1. Sintonize 3 canais diferentes com cima/baixo: ZapHUD mostra número, nome, logotipo, título/progresso do programa e se auto-oculta após ~4 s; OK curto alterna a barra.
2. Sintonize canal adulto/protegido: reprodução bloqueia, PinModal abre com 4 pontos; dígitos preenchem os pontos, PIN errado exibe "PIN incorreto!" e limpa, PIN correto (padrão 1010) libera e reproduz o canal.
3. Pressione back no PinModal: fecha sem liberar; canal permanece bloqueado. PIN correto mantém liberação na sessão (troca de canal/aba).
4. Falha total de fontes: ZapHUD exibe "(Sem sinal)" no nome do canal.

### §8 E8 - Rádios
- Tocar 2 estações distintas e verificar o áudio reproduzindo em cada uma.
- Troca rápida (cima/baixo) não deixa duas rádios tocando ao mesmo tempo (wrap-around estável).
- Botão voltar para a grade para o áudio e o timer das barras; grade volta a focar.
- Tela cheia esconde a TopNavBar e a restaura ao fechar.
- Entrega tardia (radios.txt) atualiza a grade sem travar; logo ausente não quebra o Poster.
- Gêneros agrupados com "Outras" por último.
- Teclas de volume do controle ajustam o áudio da rádio sem interromper a reprodução.

### §9 E9 - Eventos + Minhas listas
1. Abra Eventos: jogos ao vivo aparecem em "Ao vivo agora" e os futuros em "Começa em breve"; foco atualiza o hero; estado "Nenhum jogo agora." quando vazio.
2. Selecione um jogo: o app deve sintonizar o canal resolvido pelo jogo.
3. Minhas listas: adicione uma lista .m3u válida; ela aparece com total de canais e tempo; Ativar/Desativar e Atualizar funcionam; Remover apaga a lista e seus canais.
4. Após adicionar, as abas Ao vivo/Busca/Guia/Home (início) exibem os canais da lista com categoria "Minhas listas" e números seguintes aos do catálogo.
5. Edição pelo Saimo Connect: texto recebido preenche o campo de link.
6. Canais mistos reproduzem no ao vivo; a seleção de um canal minhas reproduz.

### §10 E10 - Player
OSD, seek, auto-next, erro e foco de saída.

### §11 E11 - Ficha + Settings + versão
Parte A (Ficha): abrir ficha de filme e verificar capa, metadados e botão Assistir; abrir série com 3+ temporadas, validar seletor de temporadas dinâmico, grade de episódios, badges de assistido, botão Continuar apenas com progresso parcial, erro/retry quando episódios não carregam; confirmar ausência de tela A–Z.
Parte B (Settings): editar playlistUrl, vodUrl e userAgent; executar Testar URLs; usar Limpar cache e verificar recarga; abrir Sobre e conferir versão 2.6.0; revisar preferências de áudio e minhas listas.
Regressão completa §1–§10 em dispositivo/sideload.


### §12 E12 - Saimo Connect
1. Discovery: com o app aberto e o telefone na mesma Wi-Fi, acesse `http://IP-ROKU:8999/info`; confirme `app`, `id`, `name`, `version` = 2.6.0, `port` = 8999 e `multi: false`. Nenhum outro campo. Conferir origem CORS `*` apenas nesse documento.
2. WebSocket: abra o cliente Saimo Connect e pareie; confirme contagem de clientes em Settings/estado e decremento após fechar o cliente.
3. Navegação/estado: troque de aba no app e confirme que o telefone recebe `state` com `screen` atualizado e `playing` true apenas em Ao vivo/Player. Verifique ausência de URLs/User-Agent no payload.
4. Tune: envie comando para sintonizar canal conhecido; app sintoniza. Envie nome inexistente; nenhum efeito/queda.
5. VOD: envie `playVod` com título+URL válidos; Player abre. Envie com título ou URL vazios; ignorado. Sem headers/UA do telefone.
6. Play/pause/seek: comandos não derrubam o app e não alteram candidatos; placeholders apenas.
7. Teclas: testar os 8 códigos mapeados (`UP/DOWN/LEFT/RIGHT/OK/BACK/HOME/MENU`); códigos fora do mapa não agem; verificar ECP em `127.0.0.1:8060/keypress/`.
8. Texto: envie `text` estando em Minhas listas; campo de link preenche. Em outras telas, nenhum efeito.
9. Fonte/sync: envie `fonte`/`sync`; app reenvia estado (sem confiar no cliente).
10. Segmentação de rede: testar aparelho em sub-rede/VPN/firewall diferente; esperado falha de conexão/sem controle. Com firewall bloqueando 8999, discovery falha.
11. Regressão completa §1-§11 e gates `npm run build`, `npm run check`, `npm run test`, `npm run package`.
12. Observação: trusted-LAN, sem TLS/pairing; qualquer dispositivo da rede pode enviar `hello`; documentado como recurso doméstico.

### §13 E13 - Acervo (catálogo completo)
1. Abra a aba Catálogo/VOD: o hero e as três fileiras editoriais continuam aparecendo; o índice do Acervo carrega em segundo plano.
2. As fileiras de páginas aparecem abaixo dos destaques, uma por página (50 títulos), com títulos como `A · 1 de 71`.
3. Desça pelas fileiras: as páginas próximas ao foco carregam sozinhas e as distantes voltam para "Carregando…" (janela de memória).
4. Selecione um título de página: a Ficha abre com capa, ano, gênero e sinopse; filmes e séries seguem o fluxo normal de episódios.
5. Títulos restritos continuam ausentes do acervo e dos destaques.
6. Com `vodUrl` inválido ou vazio, o Acervo usa o host canônico `https://filmes-saimo.pages.dev/`; com a rede caída, as fileiras já carregadas permanecem e a página falha mostra "Falha ao carregar · OK tenta de novo".
7. Pressione OK na linha de falha: apenas aquela página é rebaixada e recarregada.
8. Troque rapidamente de categoria (Filmes → Séries → Animes → Doramas): nenhuma página de outra categoria aparece na grade.

### §14 E14 - Árvore de canais (drawer) + grade
1. Abra Ao vivo: o drawer abre com as seções por categoria, contagem por seção e total de canais.
2. A prévia mostra canal, programa atual, horário e "A seguir" (a grade agora é buscada no boot; se `guia.txt` falhar, o drawer abre sem programa, sem travar).
3. Navegue com cima/baixo, esquerda/direita (seções) e OK: o canal selecionado toca (correção F-1 — antes tocava sempre o primeiro).
4. Favoritar com replay ou pelo menu: a seção "Favoritos" aparece/desaparece sem sair do lugar e sem perder o foco.
5. Troque de canal por zapping e dígitos com o drawer fechado: o comportamento é o mesmo de antes.
6. Abra fontes (direita) e menu (opções): continuam lendo o canal em foco, agora a partir da árvore.
7. PIN parental, timer de sono, HUD e prévia continuam funcionando.
8. Com a grade chegando depois dos canais, o drawer atualiza programa/progresso sem fechar nem reposicionar o foco.
9. Atualize Minhas listas: a árvore é reconstruída e os canais novos aparecem nas seções certas.
10. Regressão completa §1-§13 e gates `npm run build`, `npm run check`, `npm run test`, `npm run package`.
