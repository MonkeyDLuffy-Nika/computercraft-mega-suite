# 🖥️ ComputerCraft Mega Suite: Hub OS, 24+ Games, Media & Utilities

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge" alt="License: GPL v3" /></a>
</p>


[English](#english) | [Русский](#русский)

---

<a name="english"></a>
## English

An all-in-one software ecosystem for **ComputerCraft: Tweaked** (Minecraft 1.12.2 – 1.20+). 

Includes a multitasking Desktop Operating System (`Hub OS`), 24 classic and arcade games, full-motion video/audio players, and industrial utilities like Applied Energistics 2 monitor and pixel art canvas.

### 🌟 What's Inside

#### 1. 🪟 Operating System (`os/`)
- **`hub.lua`**: Flagship desktop OS with an interactive window manager, application launcher, dock/taskbar, customizable themes, widget support, sound effects, and smooth rendering.
- **`startup.lua`**: Auto-bootloader to start Hub OS automatically upon computer or monitor boot.

#### 2. 🕹️ Games Collection (`games/` - 24 Games)
| Game | Description |
| :--- | :--- |
| **`mario.lua`** | Super Mario Bros platformer with jumping physics, enemies, and obstacles. |
| **`pacman.lua`** | Classic arcade Pac-Man with maze pathfinding and ghost AI. |
| **`chess.lua`** | 2-Player Chess with legal move validation and visual board. |
| **`chess4.lua`** | **4-Player Chess** on an expanded custom board! |
| **`tetris.lua`** | Authentic Tetris with block rotations, score counters, and lines clearing. |
| **`snake.lua`** | Smooth color Snake game with growing tail and speed scaling. |
| **`casino.lua`** | Interactive casino with roulette, slot machines, and chip balance. |
| **`2048.lua`** | Smooth number sliding puzzle game. |
| **`amongus.lua`** | Among Us mini-game with tasks and imposter mechanics. |
| **`flappy.lua`** | Flappy Bird with pipe generation and high score tracker. |
| **`race.lua`** | Fast-paced pseudo-3D / top-down racing arcade. |
| **`runner.lua`** | Endless runner with procedural obstacles. |
| **`space.lua`** | Space Invaders shooter with alien waves and shields. |
| **`sudoku.lua`** | Number placement puzzle with input validation. |
| **`tower.lua`** | Tower Defense with pathfinding creeps and defensive towers. |
| **`tycoon.lua`** | Business empire tycoon simulator. |
| **`doodle.lua`** | Doodle Jump arcade jumping game. |
| **`connect4.lua`** | Connect Four 2-player gravity board game. |
| **`mines.lua`** | Classic Minesweeper with flag placing and tile reveals. |
| **`pong.lua`** | 2-Player classic Pong table tennis. |
| **`dragon.lua`** | Ender Dragon battle mini-game. |
| **`cookie.lua`** | Cookie Clicker idle game with building upgrades. |
| **`solar.lua`** | Solar System orbital physics simulation. |
| **`rng.lua`** | Random number games & probability dice rolling. |

#### 3. 🎬 Media & Video Streamers (`media/`)
- **`badapple.lua`**: The legendary *Bad Apple!!* full video animation rendered in real-time.
- **`tv.lua`**: Virtual TV with channel switching, video player, and interactive UI.
- **`youtube.lua` & `twitch.lua`**: Integrations for streaming and online media metadata.
- **`uta.lua`, `zacepila.lua`, `miku.lua`, `dance.lua`, `pootis.lua`, `heaven.lua`, `extreme.lua`, `mista.lua`**: Dynamic animated music video players.
- **`player.lua`, `music.lua`**: DFPWM audio synthesizer players.

#### 4. 🛠️ Industrial & Productivity Utilities (`utils/`)
- **`ae2_monitor.lua`**: Applied Energistics 2 ME Network Storage monitor. Shows item counts, fluid levels, and storage utilization across large monitor walls.
- **`paint.lua`**: Multi-color pixel art painting tool with color picker, canvas saving, and brush sizes.
- **`art.lua`**: Full-screen art gallery slideshow viewer.
- **`bybit.lua`**: Real-time cryptocurrency price tracker and ticker.
- **`wireless.lua`**: Wireless rednet communication chat terminal.

### 🚀 In-Game Installation

1. Place an **Advanced Computer** (Gold) or **Advanced Monitor**.
2. Run the program directly from GitHub or copy into your Minecraft world save:
   ```bash
   -- To run Hub OS directly:
   wget run <URL-to-raw-file>/hub.lua
   ```
3. Or copy all files into:
   `.minecraft/saves/<WorldName>/computercraft/computer/<ID>/`

---

<a name="русский"></a>
## Русский

Универсальный программный комплекс для мода **ComputerCraft: Tweaked** (Minecraft версий 1.12.2 – 1.20+).

Включает в себя оконную операционную систему (`Hub OS`), сборку из 24 культовых игр, анимационные и музыкальные видеоплееры, а также прикладные утилиты (мониторинг хранилища Applied Energistics 2, графический редактор Paint и криптовалютный трекер).

### 🌟 Содержимое репозитория

- **Операционная система (`os/hub.lua`)**: Рабочий стол с иконками, панелью задач, запуском любых приложений в окнах, поддержкой мониторов и кастомными цветовыми палитрами.
- **Игры (`games/`)**: 24 готовые цветные игры — Марио, Пакман, Шахматы (включая Шахматы на 4 игрока!), Тетрис, Змейка, Казино, 2048, Tower Defense, Among Us, Гонки, Flappy Bird, Космические захватчики, Сапер и другие.
- **Медиаплееры (`media/`)**: Bad Apple, Виртуальный телевизор с переключением каналов (`tv.lua`), клипы Miku, Uta, Zacepila, плееры YouTube и Twitch.
- **Утилиты (`utils/`)**:
  - `ae2_monitor.lua` — большой монитор ME-сети из Applied Energistics 2 с отображением остатка ресурсов на стенах из мониторов.
  - `paint.lua` — цветной пиксельный графический редактор.
  - `bybit.lua` — онлайн-монитор курсов криптовалют.
  - `wireless.lua` — терминал беспроводного чата по Rednet.

### 🚀 Установка в Minecraft
Скопируйте нужные файлы в папку мира:
`.minecraft/saves/<Мир>/computercraft/computer/<НомерКомпьютера>/`

### 📄 License
MIT License.
