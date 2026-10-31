# Review — Links, visual, navegação, busca (Roku)

## Referências consultadas

- Projeto oficial Saimo TV para Roku (saimotv): https://github.com/saimotv/SaimoRoku
- Saimo TV (site): https://saimo-tv.pages.dev
- Projeto anterior/créditos: https://github.com/saimotv
- Roku SceneGraph layout e foco: grupos/translations, List/MarkupGrid, `onKeyEvent`, observers de foco.
- Roku Search/Keyboard: uso de `Keyboard` ou `KeyboardDialog`, com resultados ao lado.

## Links de canais e VOD

| Fonte | Situação atual no app | Verificação | Ação |
|---|---|---|---|
| Canais ao vivo padrão | `https://saimo-canais.pages.dev/catalogo.txt` | HTTP 200, 404.190 bytes | Mantido |
| Catálogo VOD padrão | migrado para `https://filmes-saimo.pages.dev/` | HTTP 200, teste idêntico | Atualizado e alinhado ao SaimoRoku oficial |
| VOD antigo `saimo-filmes.pages.dev` | alias reconhecido | redirecionamento/alias funcional | Mantido como alias |
| VOD legado `saimoplayer/main/vod` | migrado | domínio antigo indisponível | Mantido como alias |
| Canais legados `canais-saimo.pages.dev` | alias reconhecido | compatibilidade | Mantido |
| Canais raw GitHub antigo `gabrielsaimo/.../catalogo.txt` | reconhecido | HTTP 404 | Adicionado `saimotv/SaimoPlayer` na migração |

### Eventos, EPG e extras

O cliente atual não consome agenda esportiva, rádios nem EPG automático além da URL do usuário. O SaimoRoku oficial consome:
- `baseUrl + "guia.txt"`
- `https://saimo-tv.pages.dev/eventos-extra.json`
- `baseUrl + "radios.txt"`

Esses fluxos exigem componentes e dados novos; não estão implementados neste repositório.

## Visual e disposição do menu

### Estado atual
- Navegação principal à esquerda em `m.navList` ( })). 5 ou mais entradas: Canais, A–Z, Filmes, Séries, Favoritos, VOD.
- A tela ativa troca via `populateChannels`, `openVod`, `renderEntries`.
- As listas são `MarkupGrid` com foco gerenciado manualmente.
- O foco lateral é capturado nos extremos esquerdo/direito.

### Recomendações de Roku (SceneGraph)
- Usar uma barra superior (`TopNavBar`) quando houver muitas abas, como no SaimoRoku oficial.
- Manter `Group` + `translation` para overlays e painéis, evitando reposicionar filhos diretamente.
- Usar `MarkupList`/`MarkupGrid` com `numColumns` e `numRows` adequados ao scroll, disparam `itemFocused`.
- Evitar alteração manual do foco dentro do observer sempre que possível.

## Navegação entre abas e canais

### Estado atual
- `left` a partir do primeiro item da grade devolve o foco para `m.navList`.
- `right` a partir da navegação abre a grade.
- Episódios usam 3 colunas e seasons 4 colunas, com correção para saltos verticais.

### Recomendações
- Padronizar teclas: setas navegam, `OK` abre, `Back` volta.
- Centralizar transições de foco para evitar salto 4 em 1.
- Para listas muito longas, preferir rolagem horizontal com uma linha (já aplicado em temporadas/episódios).
- Confirmar com `onKeyEvent` e retornar `true` para teclas consumidas, `false` caso contrário.

## Busca

### Estado atual
- `openSearchDialog` usa `KeyboardDialog` modal.
- O usuário digita e confirma; só então `runSearch` executa.
- Busca não é instantânea.

### Recomendações / implementação sugerida
- Renderizar uma sobreposição (overlay) na própria cena com:
  - `Keyboard` à esquerda;
  - `LabelList`/`MarkupGrid` à direita.
- Observar `text` do teclado e disparar `runSearch` com debounce curto para manter performance.
- Preservar foco e cancelar com `Back`.
- Validar teclado PT-BR e campos de busca.

### Limitações atuais
- O cliente não possui tela de busca em tempo real; exige refatoração de UI.
- A busca do catálogo Saimo usa índice `busca.txt` e `runSearch` combina resultados locais e catálogo.

## Prioridade sugerida

1. Links públicos já atualizados para `filmes-saimo.pages.dev`.
2. Nova busca com `Keyboard` + resultados laterais (alta prioridade de UX).
3. Introduzir barra superior/menu no estilo do SaimoRoku oficial (impacto visual alto).
4. Evoluir visual para telas modulares (telas separadas, estilo TV Box) sem perder comportamento atual.
5. Integrar extras do oficial (EPG guia, eventos, rádios) em fases separadas.
