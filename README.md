# Ridiculous Fishing (Réplica Flutter)

Réplica do clássico jogo **Ridiculous Fishing** desenvolvida em Flutter, com gráficos gerados proceduralmente via `CustomPainter`, física de lançamento, sistema de esquiva/captura, fase de tiro dinâmico, combos e loja completa de upgrades.

## 🎮 Mecânicas do Jogo

1. **Fase 1: Descida (Mergulho)**
   - Arrasta o dedo / rato para desviar dos peixes.
   - Quanto mais fundo fores, peixes mais valiosos e raros aparecem.
   - O anzol vira para a subida ao tocar num peixe ou atingir a profundidade máxima.

2. **Fase 2: Subida (Captura)**
   - Tenta apanhar o máximo de peixes possível respeitando a tua capacidade de anzóis.
   - Ao atingir a superfície, os peixes são arremessados para os céus!

3. **Fase 3: Céu (Disparos / Tiro)**
   - Toca repetidamente nos peixes no ar para os rebentar e ganhar dinheiro!
   - Acertos sucessivos geram **Combos (x2, x3, etc.)** aumentando a pontuação.

4. **Loja de Upgrades (Persistente)**
   - **Linha Mais Funda**: Aumenta o alcance máximo de profundidade.
   - **Mais Anzóis**: Permite puxar mais peixes por pescaria.
   - **Canhão Turbinado**: Reduz o tempo de recarga e cadência de tiro.
   - **Íman de Peixes**: Aumenta a área de atração/captura do anzol.
   - **Carretel Turbo**: Acelera a descida e subida da linha.
   - **Liquidificador**: Multiplicador de valor em dinheiro por peixe.

## 🚀 Compilar APK via GitHub Actions
Basta fazer push deste repositório para o GitHub. A pipeline em `.github/workflows/build-apk.yml` irá compilar automaticamente o ficheiro `.apk` para Android e disponibilizá-lo na aba **Actions** ou **Releases**.
