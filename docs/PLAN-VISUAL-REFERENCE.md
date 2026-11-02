# Plano de redesign visual — referência `snapshots/SaimoTV.mp4`

> **Status:** planejamento. Nenhuma alteração de código foi feita.
> **Fonte:** `snapshots/SaimoTV.mp4` — 1600×940, 2 min 25 s, captura do app Android Saimo TV 2.5.
> **Alvo:** 1920×1080 (FHD do Roku), margem segura de 96 px (5%).
> **Relação com planos antigos:** substitui o item 9 de `.memory/plan/appearance-refresh/plan.md` ("a sidebar continua à esquerda"). A referência nova usa barra superior; o restante daquele plano (paleta, tipografia, véus, foco) continua válido.

## Resumo

Cinco mudanças concentram quase toda a diferença percebida:

1. **Barra superior** com pílulas (Buscar, Início, Ao vivo, Guia, On Demand, Favoritos, Ajustes) no lugar da sidebar de 400 px.
2. **Fundo aurora** mais presente e paleta sem violeta estrutural; accent mint `#5BF0C8`.
3. **Início** com saudação e duas prateleiras (canais 16:9 e pôsteres 2:3).
4. **Lista de canais** com número, logo, programa e barra de progresso, ao lado de um cartão de preview.
5. **Player** com barra de informações no canto inferior esquerdo.

Ordem de execução: fundação (tokens/assets) → barra superior → Início → Ao vivo → On Demand/ficha → busca/ajustes/guia → player. O MVP visual (Fases 0+1+2+6) entrega a maior parte do efeito e serve para validar a direção antes de reescrever as demais telas.

---

## 1. Objetivo

Aproximar o visual do canal Roku da referência em três níveis, nesta ordem de impacto:

1. **Estrutura** — trocar a sidebar de 400 px por uma barra superior de abas, liberando a largura total para o conteúdo.
2. **Superfície** — fundo aurora (teal no topo direito, azul no centro, violeta embaixo à esquerda), cartões arredondados, foco em pílula branca, tipografia maior e mais hierárquica.
3. **Conteúdo** — Home com saudação e prateleiras, canais com número/logo/progresso, ficha com backdrop cheio, ajustes em duas colunas e player com barra de informações.

O comportamento não muda: reprodução, failover, cache, sincronização, busca, favoritos e navegação continuam com os mesmos contratos.

---

## 2. Como a referência foi analisada

Frames extraídos com `ffmpeg` (via `imageio-ffmpeg`) em `/tmp/opencode/full` e contatos em `/tmp/opencode/sheetB_*.png`. Nada disso entra no repositório.

| Tempo | Tela | O que observar |
| --- | --- | --- |
| ≈ 0:00–0:08 | Início | Saudação, subtítulo, dica, prateleira "Ao vivo agora" (16:9), prateleira "Em alta" (2:3) |
| ≈ 0:08–0:12 | Busca | Painel esquerdo translúcido, campo arredondado com placeholder, teclado compacto, dica centralizada à direita |
| ≈ 0:12–0:20 | Ao vivo | Lista de canais numerada com logo, programa e barra teal; preview 16:9 à direita; cartão de programa; painel "Fontes · Band" |
| ≈ 0:20–0:35 | Player | Barra inferior esquerda com número, canal, programa, progresso, faixa de horário e "A seguir"; selo de qualidade à direita |
| ≈ 0:35–0:47 | Eventos | Título + contagem teal; cartões 16:9 com horário, escudos e "X"; nome do confronto e competição abaixo |
| ≈ 0:47–1:22 | On Demand | Filtros em pílula, ficha com backdrop cheio, nota/ano/gêneros, sinopse, prateleiras por categoria |
| ≈ 1:22–1:40 | Ajustes | Duas colunas, cabeçalhos teal em caixa alta, linha selecionada em caixa branca com texto escuro |
| ≈ 1:40–2:25 | Séries/Animes/Doramas | Mesma gramática de prateleiras, chips de categoria ativos em teal |

### Medidas convertidas para 1920×1080

A referência é 1600×940; os valores abaixo convertem por ≈1,2 e são ajustados para a margem segura do Roku e para a grade de 8 px.

| Elemento | Referência (1600) | Alvo (1920) |
| --- | --- | --- |
| Margem lateral | 33 | 96 (margem segura Roku; a referência usa 3%, o Roku pede 5%) |
| Altura da barra superior | 104 | 152 |
| Pílula de aba | ~46×22 | 48 de altura, raio 24 |
| Título de página | 30 | 44–48 |
| Subtítulo teal | 14 | 26 |
| Dica | 12 | 20 |
| Cabeçalho de seção | 16 | 30 |
| Cartão 16:9 (canais) | 152×86 | 304×171 |
| Pôster 2:3 | 155×232 | 186×279 |
| Raio de cartão | 10 | 14–16 |
| Raio de painel | 16 | 24 |

> As proporções foram medidas nos frames, mas o vídeo tem compressão e o app Android usa densidades diferentes. O plano fixa os valores de 1920 acima; o ajuste fino acontece no primeiro build em aparelho.

---

## 3. Sistema visual alvo

### 3.1 Paleta

Formato Roku `0xRRGGBBAA`. Valores amostrados nos frames e normalizados para a paleta existente.

| Token | Hex | Uso |
| --- | --- | --- |
| `bg.base` | `0x06060FFF` | Base do fundo |
| `bg.mid` | `0x0B0E14FF` | Superfície padrão (já usado) |
| `aurora.teal` | `0x1E6E63FF` | Brilho radial no topo direito |
| `aurora.blue` | `0x1B2A4AFF` | Faixa azul no centro-esquerda |
| `aurora.violet` | `0x4B2570FF` | Brilho no quadrante inferior esquerdo |
| `surface.card` | `0x16161FFF` | Tiles de canal, cartões de evento |
| `surface.panel` | `0x101720FF` | Painéis de busca/ajustes |
| `surface.raised` | `0x1C1C26FF` | Linha de lista em repouso |
| `text.primary` | `0xF7F7FAFF` | Títulos |
| `text.secondary` | `0xA8B4C0FF` | Metadados |
| `text.faint` | `0x6B7280FF` | Dicas |
| `accent` | `0x5BF0C8FF` | Progresso, seção, destaque (vídeo ≈ `#58F8D0`; o atual `#4FE3D0` fica como fallback) |
| `accent.dim` | `0x335BF0C8` | Preenchimento de progresso em repouso |
| `live` | `0xFF4D4FFF` | Apenas AO VIVO e erro |
| `focus.fill` | `0xFFFFFFFF` | Pílula de aba ativa, linha selecionada em Ajustes |
| `focus.text` | `0x0B0E14FF` | Texto sobre a pílula branca |

**Sai da interface:** violeta `#8B5CF6` / `#A78BFA` em barras, faixas e foco. O violeta só permanece no fundo aurora, como cor de ambiente.

### 3.2 Tipografia

Roboto já está empacotado e é a fonte da referência. A mudança é de escala e peso.

| Papel | Fonte | Tamanho alvo | Cor |
| --- | --- | --- | --- |
| Saudação / título de página | Roboto Bold | 48 | primary |
| Título de ficha | Roboto Bold | 64 | primary |
| Cabeçalho de seção/prateleira | Roboto Medium | 30 | primary |
| Título de cartão | Roboto Medium | 22 | primary |
| Corpo e sinopse | Roboto Regular | 24 | primary/secondary |
| Metadados | Roboto Regular | 18 | secondary |
| Dica/rodapé | Roboto Regular | 18 | faint |
| Cabeçalho de seção em Ajustes | Roboto Medium | 18, caixa alta | accent |
| Número do canal | Roboto Black | 30 | accent |

Regras:
- Título de página nunca divide linha; `maxLines="1"`.
- Sinopse da ficha: 3 linhas no máximo (`maxLines="3"`), com `ellipsizeOnBoundary`.
- Não usar Roboto Black fora de números de canal e do título da ficha.

### 3.3 Grade, espaçamento e raios

- Grade de 12 colunas: margem 96, gutter 24, largura útil **1728**.
- Escala de espaço: 8 / 12 / 16 / 24 / 32 / 48 / 64.
- Raio: 12 (chip), 16 (cartão), 24 (painel), 999 (pílula).
- Sombra: o SceneGraph não tem sombra; usar véu PNG ou 1 px de borda `0xFFFFFF14`.

### 3.4 Foco

| Contexto | Estado |
| --- | --- |
| Aba superior | Pílula branca cheia, ícone/texto escuro; inativa: texto secondary, sem fundo |
| Chip de categoria | Borda accent 2 px + preenchimento `0x26FFFFFF` |
| Cartão 16:9 / pôster | Borda accent 3 px, raio 14, preenchimento interno `0x14FFFFFF` |
| Linha de canal | Fundo `0x1C1C26`, borda accent 2 px; número e barra ficam accent |
| Linha de Ajustes | Caixa branca, raio 12, texto escuro |
| Botão de ação (ficha) | Pílula branca com texto escuro (primária) / contorno accent (secundária) |

Sem escala animada e sem transição própria. O `focusPercent` nativo e o `floatingFocus` existente continuam controlando a animação.

### 3.5 Cantos arredondados em imagens remotas

O Roku não mascara `Poster` em firmware antigo. Duas opções, nesta ordem:

1. **Roku OS 16+** — `Poster.shaderCompatible = true` + nó `Effect` de canto arredondado, com *feature detect* (`hasField("shaderCompatible")`). Fallback automático.
2. **Firmware antigo** — moldura 9-patch gerada por `make_artwork.py` (`card_frame_9p.png`): o pôster entra 6 px menor sobre um fundo arredondado. Lê como moldura, não como canto perfeito.

Critério: nenhuma costura visível sobre o fundo aurora. Se a moldura aparecer, manter cantos retos e arredondar só o contêiner.

### 3.6 Fundo

`tools/make_artwork.py::make_bg_app` já gera o degradê. Ajustes:

- Teal mais presente no topo direito (raio maior, opacidade ~0,30).
- Faixa azul mais larga, cruzando o centro entre y=300 e y=700.
- Violeta deslocado para baixo/esquerda, começando em y=700.
- Base quase preta, sem banding: adicionar *dither* de 2 níveis no gradiente.
- Versão 1920×1080 e uma variante mais escura (`bg_app_dim.png`) para overlays de busca e ajustes.

---

## 4. Diagnóstico: referência × app atual

| Elemento | Hoje (`MainScene.xml`) | Referência | Ação |
| --- | --- | --- | --- |
| Navegação | Sidebar 400 px + `navList` vertical + grupos | Barra superior com pílulas | **Substituir** a sidebar pela barra superior |
| Área de conteúdo | x=400, largura 1520 | x=96, largura 1728 | Reflow de todas as listas e grids |
| Cabeçalho | Eyebrow teal + título 36 + barra violeta 3 px | Saudação/título 48, subtítulo teal, dica | Remover barra violeta; subir escala |
| Início | Não existe (abre em Ao vivo) | Saudação + 2 prateleiras | **Criar** |
| Canais | `LabelList` com texto "Nome • Programa · %" | Cartões com número, logo, programa e barra | **Substituir** a lista por `MarkupGrid` 1 coluna |
| Previews | Nenhum | Preview 16:9 + cartão de programa | Criar cartão de preview (logo + EPG) |
| Categorias | Itens no fim da sidebar | Chips horizontais acima da lista | Mover para chips |
| VOD | 6 colunas 210×362 com `Rectangle` de fundo | 8 colunas 186×279, sem fundo, canto arredondado | Ajustar grid e `VodCard` |
| Ficha | Backdrop + veils + pôster 304×456 | Backdrop cheio + título grande + nota/ano/gêneros | Refinar hierarquia |
| Busca | Tela preta, teclado à esquerda, painel de resultados | Painel esquerdo translúcido, campo arredondado, dica à direita | Reestilizar |
| Ajustes | Lista única 1220 + ajuda à direita | Duas colunas com seções teal e linha branca | Reestruturar |
| Player | Título no topo, progresso no rodapé | Info no canto inferior esquerdo, progresso sob o título | Reorganizar |
| Toasts | Retângulo escuro com barra teal | Barra arredondada central | Reestilizar |

### 4.1 Defeitos visuais encontrados no caminho

- **Fontes inexistentes na busca.** `MainScene.xml` usa `dictionary:fontTitle` (linha 263) e `dictionary:fontSection` (linhas 265 e 269), mas nenhum dos dois é declarado no bloco de fontes da cena. O Roku cai no fallback e o resultado é o texto sobreposto visto em `snapshots/2.5.17/busca.png` ("Buscar" em cima de "DIGITE PARA BUSCAR"). Corrigir na Fase 0, junto com a escala tipográfica.
- **`settingsGroup` começa em x=96 com largura 1728**, mas a `settingsList` fica em x=100 com largura 1220 e o divisor em x=1350 — ou seja, a lista invade a coluna de ajuda. A Fase 5 corrige a geometria.
- **`headerAccent` violeta** (`0x8B5CF6`) aparece em todas as views e não existe na referência.
- **`searchOverlayTitle` não tem `maxLines` nem altura compatível** com a fonte usada; ao trocar a escala, precisa de `width`/`height` explícitos.

---

## 5. Arquitetura de navegação

### 5.1 Barra superior

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ [logo] ( 🔍 Buscar )   Início   Ao vivo   Guia   On Demand   Favoritos        ⚙   01:12 │
└────────────────────────────────────────────────────────────────────────────────────┘
   96                                                                          1824
```

- Altura 152; linha de pílulas centrada em y=96, altura 48.
- `logo.png` vira `logo_tile.png` (48×48, cantos 12) — na referência o ícone do app fica ao lado das abas.
- "Buscar" é a primeira aba, com ícone de lupa; no `MarkupGrid` ela tem a mesma largura das outras (200), embora a referência a desenhe mais larga. O destaque fica por conta da pílula branca quando focada.
- Relógio alinhado à direita em `x=1724`, `y=84`.

### 5.2 De `LabelList` para `MarkupGrid`

`m.navList` é usado em 179 pontos (`setFocus`, `hasFocus`, `itemFocused`, `itemSelected`, `jumpToItem`, `content`). Para não reescrever todos:

- Trocar o nó de `LabelList` para **`MarkupGrid`** com `numColumns="7"`, `numRows="1"`, `itemComponentName="TopTab"`, `itemSize="[200,48]"`, `itemSpacing="[8,0]"`.
- São 7 itens: Buscar, Início, Ao vivo, Guia, On Demand, Favoritos, Ajustes. O `MarkupGrid` não permite larguras diferentes por item; a pílula de Buscar fica com a mesma largura das demais (a referência a desenha mais larga — adaptação aceita).
- `MarkupGrid` expõe a mesma API (`itemSelected`, `itemFocused`, `jumpToItem`, `content`, `setFocus`, `hasFocus`), então `buildNav`, `onNavSelected` e `findNavIndex` continuam funcionando.
- `TopTab` desenha: ícone 24×24 + texto 20, fundo em pílula (branca quando `itemHasFocus`), texto escuro no foco.

### 5.3 Separação entre abas e categorias

Hoje `m.navEntries` mistura abas, cabeçalhos e grupos de canais. Passa a haver dois conjuntos:

- `m.tabEntries` — Buscar, Início, Ao vivo, Guia, On Demand, Favoritos, Ajustes.
- `m.groupEntries` — "Todos" + grupos da playlist, renderizados como chips em Ao vivo.

`buildNav` vira `buildTabs` + `buildGroupChips`; `findNavIndex` passa a operar só sobre `m.tabEntries`; `onNavSelected` mantém o `switch` por `kind`.

### 5.4 Cadeia de foco

| Origem | Tecla | Destino |
| --- | --- | --- |
| Barra superior | ↓ | Primeiro item da view ativa |
| Primeira linha do conteúdo | ↑ | Aba ativa |
| Conteúdo (borda esquerda) | ← | Não sai mais para a sidebar; permanece no conteúdo |
| Barra superior | ← → | Aba anterior/próxima (sem wrap) |
| Qualquer view | Back | Mantém a lógica atual; sem view anterior, volta para Início |

`onKeyEvent` deixa de tratar `left → navList` e passa a tratar `up → navList`; a lógica de `back` é preservada.

### 5.5 Mapa de abas

| Aba | `kind`/`value` | Handler atual | Observação |
| --- | --- | --- | --- |
| Buscar | `search` | `openSearchDialog` | Overlay sobre a view atual |
| Início | `view/home` | **novo** `showHome` | Nova view padrão |
| Ao vivo | `view/channels` | `populateChannels` | Ganha chips + preview |
| Guia | `guide` | `openGuide` | Reestilizado como "Eventos" |
| On Demand | `view/discover` | `openVodHome("all")` | Chips Filmes/Séries/Animes/Doramas/A–Z |
| Favoritos | `view/favorites` | `showVodFavorites` | Ordenação em pílula |
| Ajustes | `settings` | `openSettings` | Também absorve "Sincronizar" |

Catálogo A–Z, Filmes, Séries e categorias deixam de ser abas e viram chips/filtros dentro de On Demand e Ao vivo.

---

## 6. Tela por tela

### 6.1 Início (nova)

```
Boa noite                                            y=190, 48 bold
O que vamos assistir?                                y=250, 26 teal
Use as setas para navegar • OK abre • * favorita     y=288, 20 faint

Ao vivo agora                                        y=352, 30
[16:9] [16:9] [16:9] [16:9] [16:9] [16:9…]           y=396, 304×171, gap 20
Band        SBT        TV Brasil   Globo SP          y=580, 22
Esporte Total  …                                     y=610, 18 secondary
▬▬▬▬▬▬                                               y=640, 3 accent/dim

Em alta                                              y=676, 30
[2:3] [2:3] [2:3] [2:3] [2:3] [2:3] [2:3] [2:3]      y=716, 186×279, gap 24
Título (2026)                                        y=1003, 22
```

> Na Home a dica global inferior (`m.hint`) fica oculta: a referência coloca a dica logo abaixo da saudação. Com isso as duas prateleiras cabem sem scroll (716 + 279 + 22 = 1017, dentro da área segura de 1026).

Dados:
- Canais: `m.channels` + `m.epg` (título atual, `nowStart`/`nowStop` para o progresso). Logo de `ch.logo`; sem logo, tile escuro com a inicial.
- Pôsteres: `m.saimoHighlights` / `m.saimoShelves`, com `pickSaimoHighlights(m.saimoHighlights, "all", 8)`.
- Sem EPG: mostrar só nome do canal e "Ao vivo".
- Sem catálogo: prateleira de canais permanece; a de pôsteres some.

Novos nós em `MainScene.xml`: `homeGroup` (greeting, `homeChannels` `RowList`, `homePosters` `RowList`).
Novos componentes: `ChannelTile.xml|.brs`, `PosterTile.xml|.brs`.
Novas funções: `showHome()`, `buildHomeShelves()`, `greetingForHour()`.

### 6.2 Ao vivo

```
Canais                                    123  330        y=190 / 44
[TV Aberta] [Filmes e Séries] [Esportes] [Notícias]        chips y=252
┌──────────────────────────┐  ┌─────────────────────────┐
│ 1  [logo]  Band          │  │                         │
│    Esporte Total         │  │      logo do canal      │
│    ▬▬▬▬▬▬▬▬▬             │  │      (16:9, 720×405)    │
├──────────────────────────┤  └─────────────────────────┘
│ 2  [logo]  Band Campinas │  ┌─────────────────────────┐
│    Esporte Total         │  │ 2  Band Campinas        │
│    ▬▬▬▬▬▬▬▬▬             │  │ Esporte Total           │
└──────────────────────────┘  │ 01:10 – 02:00 · 46 min  │
                              │ A seguir: Fórmula Band  │
                              └─────────────────────────┘
```

- Lista: `MarkupGrid` 1 coluna, `itemSize="[760,132]"`, `itemComponentName="ChannelRow"`, 5–6 linhas visíveis.
- `ChannelRow`: número (Roboto Black 30 accent), tile 64×64 com logo, nome 26, programa 20 secondary, barra de progresso 4 px (accent sobre `0x2A2D36`).
- Coluna direita: preview 720×405 (logo centralizado sobre `surface.card`, raio 16), cartão de programa 720×220 abaixo com número/nome, programa, faixa de horário, restante e "A seguir".
- Chips de categoria: `RowList` horizontal de 1 linha, `itemComponentName="CategoryChip"`, seleção com borda accent.
- Painel "Fontes": overlay lateral direito 620 px, aberto por `*`; lista `ch.sources` com check no ativo e troca imediata. Sem ele, o failover continua automático.
- O preview **não** é vídeo ao vivo (o Roku não tem thumbnail de vídeo sem tocar). É logo + EPG; a dica "OK assistir" deixa isso claro.

Novos componentes: `ChannelRow.xml|.brs`, `CategoryChip.xml|.brs`, `LivePreview.xml|.brs`.

### 6.3 Guia (equivalente a "Eventos")

A referência mostra eventos esportivos com escudos. Não temos metadados de times/competição; **não inventar**. O Guia usa os dados de EPG que já existem e adota a gramática de cartões:

- Cabeçalho: "Guia" + subtítulo teal "N programas nas próximas 24 h · N ao vivo".
- Cartões 396×222 em 4 colunas: chip de horário no topo, título do programa, canal, barra de progresso quando no ar.
- Agrupamento por período: "Agora", "Hoje mais tarde", "Amanhã".
- Foco: borda accent, sem preenchimento branco.

`openGuide`/`buildGuide` são reescritos, mantendo a fonte `m.epg`.

### 6.4 On Demand

- Filtros em pílula: Filmes · Séries · Animes · Doramas · Catálogo A–Z.
- Ficha de destaque no topo (quando há item em foco): backdrop cheio com véu lateral, título 64, linha `★ 7,1 · 2026 · Terror, Comédia`, sinopse 3 linhas.
- Prateleiras horizontais: "Em alta", "Lançamentos de 2026", "Animes", "Doramas".
- Pôster 186×279, raio 16, título 22 em até 2 linhas, ano 18 secondary.
- Grid do catálogo A–Z: 8 colunas, `itemSize="[186,340]"`, `itemSpacing="[24,20]"`, 2 linhas visíveis.

`VodCard` perde o `Rectangle cardBg`; o pôster passa a ocupar o cartão inteiro; `title`/`meta` descem para y=288/312.

### 6.5 Ficha (filme/série)

Mantém a composição de `.memory/plan/appearance-refresh`, com ajustes da referência:

- Backdrop de 1920×1080 (hoje 1520) e véu lateral mais forte à esquerda.
- Pôster 304×456 à esquerda; à direita: tipo (teal, 18 caixa alta), título 64, `★ nota · ano · gêneros` em 24 secondary, sinopse 24 em 3 linhas.
- Ações: "Assistir" (pílula branca, texto escuro), "Favoritar" (contorno accent), "Fontes" (contorno).
- Temporadas: chips 220×64 em linha única horizontal; episódios em 3 colunas 396×310, com número grande, título, duração e marcador de assistido.
- A ficha continua cabendo em uma tela; nada de scroll.

### 6.6 Busca

```
┌──────────────────────────────┐
│  ( 🔍 …scar filmes, séries )  │   campo 560×64, raio 16
│                              │
│   A   B   C   D   E   F      │   teclado 6×5, tecla 72×72
│   G   H   I   J   K   L      │
│   …                          │
│   espaço   ⌫   limpar        │
│                              │
│  Dica: erros de digitação e  │
│  falta de acento não atrapalham. │
└──────────────────────────────┘
   painel 620 px, fundo 0x0B0E14CC + borda direita 0xFFFFFF14

                       RESULTADOS                    (painel direito 1040)
                       [linha de resultado]
```

- Overlay ocupa a tela toda, mas o fundo aurora aparece (hoje é preto chapado).
- Painel esquerdo 620 px com fundo translúcido.
- Campo de busca: o `MiniKeyboard` embutido já desenha a caixa de texto no topo; ela é a única parte do componente que não dá para estilizar. Manter o texto da consulta ali e, se o encaixe permitir, sobrepor um `Label` com o placeholder "...scar filmes, séries, canais..." que some na primeira tecla. Caso contrário, a dica fica abaixo do campo.
- Teclado: `MiniKeyboard` embutido, `keyColor="0x12141C"`, `focusedKeyColor="0xF2F3F5"`, sem linhas divisórias visíveis (limitação do componente).
- Resultados à direita: painel 1040×840, raio 24, cabeçalho "RESULTADOS" teal, linhas de 64 px com título + tipo/ano e pílula de foco branca.
- Sem digitação: dica centralizada à direita ("Digite o nome — os resultados aparecem enquanto você digita"), como no vídeo.
- **Não trocar o `MiniKeyboard` por componente próprio nesta fase** — a navegação foi recém-corrigida e confirmada; um teclado custom é risco isolado (ver decisão 3).

### 6.7 Favoritos

- Título + contagem; à direita, pílula "Ordenar: Mais novos" (A–Z / Mais novos / Mais antigos).
- Vazio: texto central em duas linhas + dica "Segure OK num título para favoritar" (o app usa `*`; ajustar a dica para o controle remoto).
- Grid de pôsteres igual ao On Demand.

### 6.8 Ajustes

```
Ajustes                        │  CANAIS AO VIVO, FILMES E SÉRIES AO VIVO
Saimo TV 2.5.17                │  Ao abrir o app
ID do aplicativo…              │  Mantém a última tela
Informe erros ao @…            │
                               │  GERAL
                               │  ┌──────────────────────────────┐
                               │  │ Desligar automaticamente     │ ← branco
                               │  └──────────────────────────────┘
                               │  …
                               │  SISTEMA
                               │  Procurar atualização
                               │  Recarregar catálogo
                               │  Enviar uso anônimo
```

- Duas colunas: esquerda 96..456 (360), direita 504..1824 (1320).
- Cabeçalhos de seção em teal, caixa alta, 18.
- Linha: título 24 + subtítulo 18 com `maxLines="1"`.
- Selecionada: caixa branca, raio 12, texto escuro; o resto sem fundo.
- "Sincronizar" vira linha em SISTEMA; o refresh também aparece no `syncHint` do topo.
- O `settingsHelp` da direita é removido (a referência não tem painel de ajuda; o subtítulo da linha já explica).

### 6.9 Player

```
┌──────────────────────────────────────────────────────────────┐
│                                                    ● AO VIVO  │  topo, y=48
│                                                              │
│                    (vídeo)                                   │
│                                                              │
│  1  Band                                              [HD]   │  y=830
│  Esporte Total                                               │  y=874, 40
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬                  │  y=930
│  01:10 – 02:00 · faltam 46 min · A seguir: Fórmula Band      │  y=948
│  OK pausa · ← -10s · → +30s · Back sai                       │  y=984
└──────────────────────────────────────────────────────────────┘
```

- Remover `playerTitle`/`playerSubtitle` do topo; manter só o selo AO VIVO e o logo do canal como marca d'água no canto superior direito.
- Barra inferior: véu PNG de 380 px; bloco de info em [96, 820] com largura 1100.
- Progresso de 6 px com trilho `0x2A2D36` e preenchimento accent; o mesmo nó `progressFill` continua sendo atualizado por `onProgressTimer`.
- Selo de qualidade à direita: `quality`/`streamFormat` da fonte atual (ex.: "HD", "FHD"); sem dados, oculto. Bitrate real não é exposto de forma confiável pelo `Video`, então não entra.
- Auto-hide de 3 s preservado (`playerAutoHideTimer`); qualquer tecla reexibe.
- Para VOD: mesma barra, trocando "AO VIVO" por tempo decorrido/total e mantendo o comportamento de pausa/seek já implementado.

### 6.10 Estados vazios, toasts e erros

- Vazio: ícone 72 + título 30 + uma linha 22 secondary + ação teal 20. Centralizado na área de conteúdo (não na tela toda).
- Toast: pílula 900×64, fundo `0xD90B0E14`, raio 16, barra accent de 4 px à esquerda, ícone e texto 20.
- Erro: mesma pílula com `live` na barra e no ícone.
- Nada de texto sobreposto: todo label tem `width`, `maxLines` e `wrap` definidos.

---

## 7. Fases de implementação

Cada fase termina com `npm run check`, `npm test`, `npm run build` e um build instalável. Nenhuma fase muda contratos de dados.

### Fase 0 — Fundação visual (S, ~1 sessão)

**Escopo**
- `tools/make_artwork.py`: aurora mais forte, `bg_app_dim.png`, `nav_pill.png`, `settings_focus.png` (branco), `card_frame_9p.png`, `toast_bg.png`.
- `SaimoTV/source/theme.brs`: novos tokens (`accent` `0x5BF0C8FF`, `focus.fill`, `focus.text`, `surface.card`, `surface.panel`).
- `MainScene.xml`: escala tipográfica, remoção das barras violeta, cores dos labels, declaração de `fontTitle`/`fontSection` (ou troca pelos papéis existentes) e correção do texto sobreposto da busca.
- `tools/check_project.py`: checks de paleta, assets e de que nenhum `dictionary:font*` usado no XML esteja indefinido.

**Aceite**
- App abre com o novo fundo e a nova escala, ainda com sidebar.
- Nenhuma barra violeta na interface.
- `npm run art`, `check`, `build` verdes; screenshots em 1080p sem texto cortado.

**Risco:** baixo. Só visual.

### Fase 1 — Barra superior e reflow (L, ~2 sessões)

**Escopo**
- Novo `TopTab.xml|.brs`.
- `MainScene.xml`: remover `sidebarBg`, `brand` e `brandSub`; converter `navList` em `navGrid`; criar `topBar` (logo, search pill, `navGrid`, clock). Reflow de `itemList`, `vodGrid`, `shelfList`, `vodDetailGroup`, `settingsGroup`, `guideGroup`, `aboutGroup` para 96..1824.
- **`status`:** o nó é escrito em 18 pontos (`m.status.text`). Não remover na Fase 1; mantê-lo invisível e redirecionar as mensagens para `syncHint`/toast numa fase posterior, para não quebrar o código de sincronização.
- `MainScene.brs`: `buildTabs`, `buildGroupChips`, `onNavSelected`, `onKeyEvent` (up/down), `showHeader`, `openSettings`/`openGuide`/`openAbout` (posições).
- `check_project.py`: garantir ausência de `sidebarBg` e presença de `topBar`/`navGrid`.

**Aceite**
- Sidebar não existe mais; conteúdo usa 1728 px.
- Todas as views abrem pelas abas; foco sobe para a aba com ↑ e desce com ↓.
- Back continua funcionando em todas as views.
- Busca, ajustes, guia e player abrem sem sobreposição.

**Risco:** alto (179 referências a `m.navList`). Mitigação: manter a API do `MarkupGrid` idêntica à do `LabelList` e não renomear `m.navList`.

### Fase 2 — Início (M, ~2 sessões)

**Escopo**
- `showHome`, `buildHomeShelves`, `greetingForHour`.
- Componentes `ChannelTile`, `PosterTile`.
- `homeGroup` no XML; EPG para o subtítulo dos tiles.
- Aba Início como padrão de abertura (decisão 1).
- Fallbacks: sem EPG, sem catálogo, sem canais.

**Aceite**
- Home abre em < 1 s com cache; sem travamento durante sincronização.
- Saudação correta por horário; prateleiras navegáveis; OK abre o canal/título.
- Sem dados, mostra estado vazio coerente (sem prateleira vazia).

### Fase 3 — Ao vivo (L, ~2 sessões)

**Escopo**
- Componentes `ChannelRow`, `CategoryChip`, `LivePreview`.
- `populateChannels` passa a montar `MarkupGrid` 1 coluna + preview + cartão de programa + chips.
- Painel de fontes (`*`) com troca de fonte.
- `renderEntries` deixa de formatar canal como string.

**Aceite**
- Linha mostra número, logo, nome, programa e progresso.
- Preview e cartão acompanham o item focado em tempo real.
- Chips filtram sem perder a posição; "Todos" restaura.
- Sem EPG, o cartão mostra nome do canal e "Ao vivo".
- Fontes abre/fecha e troca a fonte ativa.

### Fase 4 — On Demand + ficha (M, ~2 sessões)

**Escopo**
- `VodCard` sem fundo, 186×279, raio; grid 8 colunas.
- `ShelfCard` vira `PosterTile`.
- Chips de filtro no topo de On Demand.
- Ficha com backdrop 1920, tipografia nova, gêneros/nota, ações em pílula.
- Catálogo A–Z com 8 colunas.

**Aceite**
- 8 pôsteres por linha em 1080p, sem corte.
- Ficha cabe em uma tela, sem sobreposição de sinopse/ações.
- Filtros trocam a prateleira sem recarregar a rede.
- Foco visível em pôster, chip e ação.

### Fase 5 — Busca, Favoritos, Ajustes e Guia (M, ~2 sessões)

**Escopo**
- Busca: overlay com aurora, painel 620, painel de resultados com raio e cabeçalho teal, dica à direita.
- Favoritos: ordenação e vazio.
- Ajustes: duas colunas, seções teal, linha branca.
- Guia: cartões por período, 4 colunas.
- Toasts e estados vazios.

**Aceite**
- Busca abre com foco no teclado; resultados continuam instantâneos (índice local).
- Nenhum texto sobreposto no painel de resultados.
- Ajustes: 12 linhas navegáveis, linha selecionada branca, sem painel de ajuda.
- Guia navega por cartões e abre o canal.

### Fase 6 — Player (S, ~1 sessão)

**Escopo**
- Reorganizar `playerOverlay`: info embaixo à esquerda, progresso sob o título, selo de qualidade, topo minimalista.
- Manter pausa/seek/auto-hide.

**Aceite**
- Barra aparece/some em 3 s; teclas a reexibem.
- Número, canal, programa, horário e progresso corretos em ao vivo e VOD.
- Nenhum texto do topo colide com o selo AO VIVO.

### Fase 7 — Polimento e verificação (S, ~1 sessão)

- Contraste, 720p, margens seguras, textos longos, estados de erro.
- `docs/FEATURE-MAP.md`, `.context.md` de imagens/componentes.
- Screenshots novas em `snapshots/<versão>/`.
- Bump de versão e release somente após aprovação.

**Total estimado:** 11–13 sessões. Se o objetivo for o maior impacto pelo menor custo, o **MVP visual** é Fase 0 + 1 + 2 + 6 (fundo, barra superior, Home e player), que entrega ~80% da diferença percebida.

---

## 8. O que não muda

- `FetchTask`, parsers, cache, assinaturas, sincronização e failover.
- Busca local por índice (`buildSaimoSearchIndex` / `searchSaimoIndex`) e o debounce.
- Player: pausa/retomada, Play/Pause, seek acelerado, troca de fonte.
- Favoritos de canais e VOD; `*` continua favoritando.
- Navegação por letras do catálogo e retorno de foco (`focusSaimoTitle`).
- Contratos de `ContentNode` e nomes de campos (`title`, `hdPosterUrl`, `itemContent`).
- Versão e release só depois de aprovação do build.

---

## 9. Verificação

### Automática (a cada fase)

- `npm run art` — regenera os assets sem erro.
- `npm run check` — precisa continuar em 202+ verificações; novas checks para `topBar`, `navGrid`, tokens e assets.
- `npm test` — 138 testes; parsers intocados.
- `npm run build` — zero erro de compilação BrightScript.
- `npm run package` — ZIP com os novos assets.

### Manual (no Roku, por fase)

| Cenário | O que validar |
| --- | --- |
| 1080p | Margens de 96 px, nada cortado, 8 pôsteres por linha |
| 720p | UI FHD é reduzida pelo Roku; textos continuam legíveis |
| Lista vazia | Estado vazio centralizado, sem prateleira fantasma |
| Sem EPG | Canal e "Ao vivo", sem barra de progresso |
| Sem catálogo | Home só com canais |
| Texto longo | Título de 60+ caracteres com `maxLines` e reticências |
| Falha de rede | Toast de erro, cache preservado |
| Navegação | ↑/↓ entre aba e conteúdo; Back em todas as views |
| Busca | Digitação rápida, apagar, resultado vazio |
| Player | Pausa, seek, auto-hide, troca de fonte |

### Performance

- Prateleiras: no máximo 12 itens por linha e 2 linhas montadas; nunca 40 pôsteres remotos de uma vez.
- `loadSync="true"` só para assets locais pequenos (≤ 128 KB).
- Fundo em 1920×1080, PNG otimizado (o atual tem 140 KB; manter abaixo de 250 KB).
- Nenhum log novo no console.

---

## 10. Riscos

| Risco | Prob. | Impacto | Mitigação |
| --- | --- | --- | --- |
| Reflow quebrar foco em views antigas | Alta | Alto | `MarkupGrid` com a mesma API; testar view por view; manter `m.navList` |
| Cantos arredondados sem máscara no Roku | Alta | Médio | `Effect` no OS 16 + moldura 9-patch no antigo; fallback reto |
| Home não caber em uma tela | Média | Médio | Pôsteres de 186×279 + dica inferior oculta; se o Roku cortar, uma prateleira visível e a segunda por ↓ |
| Preview sem vídeo decepcionar | Média | Baixo | Cartão com logo + EPG + "OK assistir"; não prometer thumbnail |
| Assets novos aumentarem o pacote | Baixa | Baixo | PNG com zlib, reutilizar máscaras, limite de 250 KB por fundo |
| Regressão na busca recém-validada | Baixa | Alto | Não tocar em `MiniKeyboard` nem na lógica de índice na Fase 5 |

---

## 11. Decisões pendentes

1. **Tela inicial:** Início (como no vídeo) ou manter Ao vivo como padrão? *Recomendo Início.*
2. **Densidade da Home:** duas prateleiras visíveis com pôsteres de 186×279 (como no vídeo) ou uma prateleira maior + segunda por ↓? *Recomendo duas visíveis, com a dica inferior oculta.*
3. **Teclado da busca:** manter `MiniKeyboard` (seguro, visual 80% próximo) ou criar teclado próprio (100% fiel, risco de regressão)? *Recomendo manter na primeira entrega.*
4. **Guia vs. Eventos:** usar o EPG no formato de cartões (sem inventar times) ou esconder a aba até existir fonte de eventos? *Recomendo EPG em cartões.*
5. **Cantos arredondados:** aceitar a moldura 9-patch no firmware antigo ou manter cantos retos e arredondar só contêineres? *Recomendo moldura 9-patch com fallback reto se houver costura.*
6. **Escopo da primeira entrega:** MVP visual (Fases 0+1+2+6) ou sequência completa? *Recomendo MVP para validar a direção antes de mexer em todas as telas.*

---

## 12. Próximo passo

Com as decisões acima, a execução começa pela Fase 0 (assets + tokens), que é reversível e já muda a percepção do app inteiro. Em seguida, a Fase 1 (barra superior) precisa de um build de teste no aparelho antes de qualquer outra tela, porque é a única mudança que altera a estrutura de todas as views.
