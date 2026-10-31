# Saimo TV para Roku — versão 2.5.15

[![Download build compilado](https://img.shields.io/badge/Download-build%20compilado-7c3aed?style=for-the-badge&logo=github)](https://github.com/Ediglebison/saimoTV-Roku/releases/latest/download/SaimoTV-roku.zip)

Cliente pessoal não oficial em BrightScript/SceneGraph para Roku. A versão **2.5.13** reforça os controles do player de VOD: pause/retomada preservando a posição, resposta aos botões Play/Pause e busca acelerada ao manter o avanço pressionado.

Build compilado pronto para sideload: [SaimoTV-roku.zip](https://github.com/Ediglebison/saimoTV-Roku/releases/latest/download/SaimoTV-roku.zip) (checksum SHA-256 em [SaimoTV-roku.zip.sha256](https://github.com/Ediglebison/saimoTV-Roku/releases/latest/download/SaimoTV-roku.zip.sha256)).

Use somente listas e fontes de mídia que você tenha autorização para acessar. O cliente não inclui conteúdo audiovisual nem fornece um catálogo próprio de filmes/séries. Itens com marcadores adultos conhecidos em título ou categoria são excluídos.

## Novidades da versão 2.5.13

- Reprodução de VOD responde aos botões Play, Pause e Play/Pause do controle.
- Pausa e retomada preservam o ponto atual do vídeo.
- Busca por setas mantém -10s/+30s no toque curto e acelera quando o botão é mantido pressionado.

## Novidades da versão 2.5.12

- Usa o comando de retomada do player, mantendo o ponto atual do VOD após a pausa.
- Ao sair da reprodução de um episódio, retorna à mesma grade de episódios para continuar navegando e escolher outro.

## Novidades da versão 2.5.11

- Descobrir, catálogo e episódios iniciam o carregamento das capas ao renderizar os cards visíveis, sem aguardar o foco.
- A grade continua virtualizada; ao navegar, novos grupos visíveis são carregados conforme entram na tela.

## Novidades da versão 2.5.10

- Aceita strings tipadas como `String` pelo brs-desktop e `roString` pelo Roku nas respostas e caches.
- Mantém o carregamento sob demanda de `fichas.txt` e aplica as capas ao catálogo e às séries.

## Novidades da versão 2.5.9

- Associação de pôsteres mais tolerante a diferenças de pontuação, acentuação e ano entre os fragmentos do catálogo e `fichas.txt`; o console registra linhas processadas, correspondências e capas associadas.
- Mantém o rastreamento do estado das imagens remotas para separar erro de associação de erro de download.

### Base da versão 2.5.8

- Leituras de cache verificam primeiro se o arquivo existe; uma instalação limpa deixa de emitir erros de cache ausente no console.
- O console informa o resultado do download de `fichas.txt`, quantos itens receberam capa e se os pôsteres focados carregaram ou falharam.

### Base da versão 2.5.7

- Imagens das grades de filmes, séries, destaques e episódios são solicitadas somente quando o seletor aproxima o foco do card, reduzindo requisições simultâneas e tráfego inicial.
- As fichas completas de capas são baixadas em segundo plano apenas ao entrar no catálogo e ficam em cache local; Descobrir usa as capas leves dos destaques.
- A grade do catálogo usa seis colunas e cartões próprios, preservando a legenda junto ao pôster.
- Episódios continuam em cards 16:9 com fallback para a capa da série.

### Base da versão 2.5.6

- Corrigida a fila de atualização do catálogo: se as fichas de capas terminam durante o carregamento de uma letra, a lista é recarregada para aplicar os pôsteres sem exigir nova navegação.
- Episódios consultam o Worker TMDB configurado pelo usuário por ID de série e temporada, sem expor a chave TMDB no Roku.
- Cards widescreen podem exibir imagem de cena, título, sinopse e duração de cada episódio; a capa da série permanece como fallback quando não há imagem de cena.
- Respostas por temporada ficam em cache local por 24 horas, com uso do cache anterior se a rede falhar.
- Capas de `fichas.txt` prevalecem sobre as capas de destaque; IDs TMDB das fichas ficam associados aos itens do catálogo.

### Base da versão 2.5.3

- Painel de prévia agrupado: badge, descrição e ações deixam de invadir o catálogo e as demais telas quando ocultos.
- Episódios usam cartões próprios 396x310 com thumb 16:9, numeral do episódio quando não há arte, badge de temporada/episódio, título, fontes e sinopse quando fornecida pelos dados.
- Descobrir informa quantas fileiras editoriais estão carregadas e mantém navegação vertical entre elas.

### Base da versão 2.5.2

- Nova identidade visual alinhada ao site Saimo: fundo quase preto, destaques em violeta, ciano e vermelho ao vivo, painéis translúcidos e tipografia Roboto com hierarquia mais clara.
- Logotipo oficial na barra lateral, ícones de navegação, pílulas de foco personalizadas e relógio no cabeçalho.
- Cartões de pôster em proporção **2:3** com legenda compacta (filme/série + ano ou contagem de episódios) e mais espaço entre as colunas.
- Painel de prévia redesenhado com badge de tipo, fundo cinematográfico ampliado e escurecido, metadados, descrição e chamada de ação.
- Cabeçalho com indicador de sincronização e relógio; Descobrir combina **hero que acompanha o foco** e fileiras editoriais, catálogo usa **6 colunas** e episódios usam cards **16:9**.
- Navegação horizontal nas fileiras preserva o foco entre capas; a barra lateral recebe o foco ao pressionar esquerda no primeiro cartão.
- Canais ao vivo usam selo vermelho e mostram programa atual/próximo e progresso do EPG quando esses dados existem.
- Ajustes, Guia de TV, Sobre, estados vazios e toasts receberam a mesma linguagem visual.
- Ícone, splash e arte de espaço reservado regenerados na nova paleta, sem dependências externas de imagem.

### Base da versão 2.4.0

- Catálogo VOD carregado por letra sob demanda: o app baixa o `indice.txt` e, ao abrir uma letra, apenas os fragmentos `filmes-LETRA.txt` e `series-LETRA.txt` necessários.
- Cache separado por letra e por filtro (todos, filmes, séries). A leitura do cache valida a assinatura do índice; quando o índice muda, letras, busca e capas derivadas são invalidadas.
- Capas e gêneros vindos de `fichas.txt` são aplicados dentro da tarefa de rede. A linha principal do app nunca lê o arquivo completo de fichas.
- Busca sem acento usando o índice `busca.txt`, com resultados limitados para manter a memória do Roku sob controle.
- Verificação de atualizações a cada **15 minutos**; o download só acontece quando o cache tem mais de **6 horas**. A atualização roda em segundo plano e não troca a tela atual do usuário.
- Player ao vivo sem pausa e sem busca; filmes e episódios mantêm pausa, avanço e retrocesso.
- Suíte de testes dos parsers puros, executada com `npm test`.

## Como o catálogo funciona

A fonte padrão de filmes e séries é `https://saimo-filmes.pages.dev/`. O app aceita a raiz do catálogo ou o endereço direto do índice e acrescenta os nomes de arquivo necessários:

- `indice.txt`: letras disponíveis, contagens, bases de vídeo e assinatura do catálogo.
- `destaques.txt`: fileiras da tela Descobrir.
- `filmes-LETRA.txt` e `series-LETRA.txt`: fragmentos baixados somente quando a letra é aberta.
- `series-LETRA-PARTE.txt`: episódios baixados somente quando uma série é selecionada.
- `busca.txt`: índice de busca.
- `fichas.txt`: capas e gêneros, processados em segundo plano.

Endereços antigos (`filmes-saimo.pages.dev` e `saimoplayer/main/vod`) são migrados automaticamente para a fonte canônica. A lista de canais ao vivo padrão é `https://saimo-canais.pages.dev/catalogo.txt`; o alias `canais-saimo.pages.dev` também é reconhecido e migrado.

O cache fica em `cachefs:` e pode ser descartado pelo Roku quando a memória estiver baixa. Se uma atualização falhar, o conteúdo já carregado é preservado. Trocar a URL de uma fonte não mistura itens da fonte anterior.

## Estrutura

- `SaimoTV/`: aplicativo Roku.
- `SaimoTV/source/bslib.brs`: parsers puros, URLs canônicas, cache por letra, destaques, busca e utilidades de player.
- `SaimoTV/components/MainScene.brs`: interface, navegação, sincronização e player.
- `SaimoTV/components/FetchTask.brs`: download e processamento em tarefa separada.
- `SaimoTV/images/`: ícone, splash, fundos, logotipo, ícones de navegação e bitmaps de foco.
- `SaimoTV/fonts/`: fontes Roboto empacotadas (Regular, Medium, Bold, Black e Italic) sob licença Apache 2.0 (`Roboto-LICENSE.txt`), usadas em toda a interface.
- `tools/tests/parsers_test.brs`: suíte BRS dos parsers.
- `tools/test_parsers.py`: executa a suíte BRS e falha quando algum teste não passa.
- `tools/check_project.py`: valida arquivos, XML, versão, fontes, cache e referências.
- `tools/package.py`: cria o ZIP para sideload e o checksum SHA-256.
- `tools/make_artwork.py`: gera a arte da interface em Python puro, sem Pillow.
- `bsconfig.json` e `package.json`: configuração de build.

## Configurar

1. No aplicativo, abra **Ajustes**.
2. **Fonte do catálogo de filmes e séries** já vem com a raiz canônica do catálogo Saimo. Também é possível informar uma lista M3U/M3U8 autorizada.
3. **Lista de canais ao vivo** usa `https://saimo-canais.pages.dev/catalogo.txt` por padrão.
4. Use **Atualizar catálogo VOD agora** para forçar uma sincronização manual.
5. O app verifica atualizações a cada 15 minutos, mas só baixa quando o cache tem mais de 6 horas.

Uma lista M3U de filmes e séries também é aceita. Nesse formato, `group-title` separa filmes, séries, anime e documentários, e `tvg-logo` fornece o pôster. Episódios com padrões como `S01E02`, `T01E02` e `1x02` são agrupados e ordenados automaticamente.

## Compilar e testar

Requisitos: Python 3.9+ e Node.js 18+ (Node 22 recomendado).

```bash
npm install
npm run check
npm test
npm run build
npm run package
```

- `npm run check` executa as verificações estáticas do projeto.
- `npm test` executa a suíte BRS dos parsers puros.
- `npm run build` compila com BrighterScript.
- `npm run package` gera `dist/SaimoTV-roku.zip` e `dist/SaimoTV-roku.zip.sha256`.

O ZIP gerado é um pacote de sideload para modo desenvolvedor, não um pacote comercial assinado.

## Instalar no Roku

1. Ative o modo desenvolvedor no dispositivo Roku e anote o IP exibido.
2. No computador conectado à mesma rede, abra `http://IP-DO-ROKU`.
3. Envie `dist/SaimoTV-roku.zip` no instalador de desenvolvimento e selecione **Install**.
4. Abra o app. Ajustes preserva separadamente a URL de canais, a URL do EPG e a URL do catálogo VOD.

## Limitações e validação

- A compilação BrighterScript, as verificações estáticas e a suíte de parsers passam neste repositório. A reprodução em um aparelho Roku real ainda precisa ser confirmada fisicamente.
- O atualizador automático roda enquanto o app está aberto; o Roku não executa o processo depois que o aplicativo é fechado.
- Listas M3U únicas acima de 25.000 entradas são rejeitadas integralmente para evitar catálogo parcial sem aviso.
- O player depende de streams permitidos e compatíveis com Roku. Alguns formatos, servidores, codecs ou requisitos de acesso podem não funcionar.
- A disponibilidade das URLs externas varia; falhas de rede preservam o cache já carregado.

## Créditos e referência

- Este cliente é uma derivação não oficial do projeto **Saimo TV**, agora mantido em https://github.com/saimotv. Créditos ao criador original e à equipe/projeto Saimo TV.
- Use somente com listas e fontes de mídia que você tenha autorização para acessar.

## Referências técnicas

- Documentação Roku SceneGraph PosterGrid: https://developer.roku.com/dev/docs/postergrid
- Documentação Roku Video: https://developer.roku.com/dev/docs/video
- Documentação Roku `roUrlTransfer`: https://developer.roku.com/dev/docs/rourltransfer
