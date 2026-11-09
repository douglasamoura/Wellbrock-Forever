# Wellbrock Classic — WoW Forever / Classic Era / Hardcore / SoD

Versão do addon **Wellbrock** adaptada para **World of Warcraft Classic** (Vanilla 1.12 / 1.15.x, Classic Era, Hardcore, Season of Discovery).

## 📦 Módulos Incluídos

| Módulo | Descrição | Status |
|--------|-----------|--------|
| **AutoLoot** | Saque rápido instantâneo (SpeedyAutoLoot) | ✅ Completo |
| **VendorAutomation** | Venda automática de lixo cinza + reparo automático | ✅ Completo |
| **BlizzMove** | Movimentação de janelas da Blizzard (frames seguros) | ✅ Completo |
| **MinimapMod** | Minimapa quadrado + borda + alinhamento de botões | ✅ Completo |
| **MapCoords** | Exibição de coordenadas + favoritos de localização | ✅ Completo |
| **QuestCinematic** | Diálogo imersivo de missões (Lorewalker style) | ✅ Completo |
| **ConfigUI** | Painel de configurações via InterfaceOptions | ✅ Completo |

## ❌ Módulos Removidos (Incompatíveis com Classic)

| Módulo Retail | Motivo |
|---------------|--------|
| **Transmog** | Sistema de transmog não existe no Classic |
| **WaypointHUD** | Waypoints/SuperTracking não existem |
| **MapPins** (waypoints) | Substituído por **MapCoords** (coordenadas + favoritos simples) |

## 🔧 Diferenças Técnicas (Retail → Classic)

| API Retail | API Classic (Usada) |
|------------|---------------------|
| `C_Container.*` | `GetContainerItemInfo`, `GetContainerItemLink`, `UseContainerItem` |
| `C_TransmogCollection` | **Removido** |
| `C_Navigation`, `C_Map.GetUserWaypoint` | **Removido** |
| `TooltipDataProcessor`, `Enum.TooltipDataType` | `GameTooltip:HookScript("OnTooltipSetItem")` |
| `Settings.RegisterCanvasLayoutCategory` | `InterfaceOptions_AddCategory` |
| `ContainerFrameItemButtonMixin` | Hooks em `ContainerFrameItemButton_OnUpdate` / XML |
| `AddonCompartment` | Botão no Minimap (WellbrockMinimapButton) |
| `PlayerSpellsFrame`, `CollectionsJournal` | Removidos de `BlizzMove.DEFAULT_FRAMES` |

## 🚀 Instalação

1. Copie a pasta `Wellbrock_Classic` para:
   ```
   Interface/AddOns/Wellbrock_Classic/
   ```
2. Reinicie o WoW ou faça `/reload`
3. Digite `/wb` para abrir o painel de configurações

## ⌨️ Comandos de Chat

| Comando | Descrição |
|---------|-----------|
| `/wb` ou `/wellbrock` | Abre painel de configurações |
| `/wb status` | Mostra status de todos os módulos |
| `/wb loot` | Alterna AutoLoot |
| `/wb move` | Alterna BlizzMove |
| `/wb coords` | Alterna exibição de coordenadas |
| `/wb quest` | Alterna diálogo imersivo |
| `/wb square` | Alterna minimapa quadrado |
| `/wb vendor` | Alterna venda/reparo automático |
| `/wb pin save [nome]` | Salva coordenada atual |
| `/wb pin list` | Lista favoritos salvos |
| `/wb pin del [id]` | Remove favorito |
| `/wb debug` | Alterna mensagens de debug |

## 🎯 Funcionalidades Principais

### AutoLoot (Speedy)
- Saque instantâneo sem delay visual
- Shift para ignorar e abrir janela normal
- Confirmação automática de BoP (solo)
- Verificação de espaço nas bolsas

### Vendor Automation (Leatrix Style)
- Vende automaticamente itens cinza (lixo) ao abrir comerciante
- Repara equipamentos automaticamente
- Usa fundos da guilda se disponível e permitido
- Resumo de ouro no chat

### BlizzMove
- Move janelas padrão da Blizzard
- Shift+Right-Click para resetar posição individual
- Salva/restaura posições entre sessões
- **Apenas frames seguros** (evita taint em combate)

### MinimapMod (Leatrix Style)
- Minimapa quadrado com máscara personalizada
- Borda fina configurável
- Botões de addons alinhados na borda inferior
- Botão do Wellbrock arrastável (radial ou dockado)

### MapCoords
- Exibe coordenadas atuais acima do minimapa
- Arraste com Shift para reposicionar
- Sistema de favoritos (pins) por coordenadas
- Funciona em masmorras/raids (mostra zona)

### QuestCinematic (Lorewalker)
- Painel estilizado para textos de missões
- Space/Esc para avançar/fechar
- Auto-esconde em combate
- Arrastável e redimensionável

## 📋 Requisitos

- **WoW Classic Era** (1.15.x)
- **Classic Hardcore** 
- **Season of Discovery** (3.4.x+)
- **LibDBIcon-1.0** (opcional, para integração com outros addons)

## 🐛 Known Issues / Limitações

1. **ItemUpgradeFrame** pode não existir em todas as versões Classic
2. **WorldMapFrame** movido pode conflitar com outros addons de mapa
3. Coordenadas em instâncias mostram apenas nome da zona (limitação da API Classic)
4. LibDBIcon callback pode disparar antes do ADDON_LOADED (tratado com timers)

## 📝 Changelog

### v1.3.0-classic (2026-11-08)
- Port inicial para Classic Era
- Removidos módulos incompatíveis (Transmog, WaypointHUD, MapPins waypoints)
- Adicionado MapCoords (coordenadas + favoritos)
- ConfigUI reescrito para InterfaceOptions
- APIs modernas substituídas por globais Classic
- BlizzMove filtrado para frames não-protegidos
- AutoLoot otimizado (OnUpdate throttled 10Hz)
- VendorAutomation usando APIs Classic (GetContainerItem*)

## 🤝 Créditos

- **SpeedyAutoLoot** — inspiração para AutoLoot
- **Leatrix Plus** — inspiração para VendorAutomation, BlizzMove, Square Minimap
- **Lorewalker** — inspiração para QuestCinematic
- **Map Pin Enhanced** — inspiração para MapCoords
- **Can I Mog It?** — inspiração para Transmog (Retail only)

## 📄 Licença

MIT License — Use, modifique, distribua livremente.

---

**Desenvolvido por Douglas**  
Para WoW Classic Forever / Era / Hardcore / SoD 🇧🇷