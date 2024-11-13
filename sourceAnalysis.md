# 基于 wasm4 游戏开发框架，moonbit语言的简单小游戏结构与逻辑

在这个游戏中，玩家控制一个“圆形”在屏幕上移动，同时需要避免其他圆形（AvoidCircles），可以吸收特定圆形（AbsorbCircles），并在游戏中生成炸弹（Bombs）。代码包含多个结构体和函数，分别用于定义游戏的元素、游戏状态，以及核心的游戏逻辑。下面是一个详细的解释：

## 1. 游戏元素的结构体

在代码中，多个结构体定义了不同的游戏元素，每个元素有特定的属性。

- **Circle**: 定义一个基本的圆形结构，包含圆形的 `x` 和 `y` 坐标，以及 `width` 和 `height` 属性。

- **ControlCircle**: 定义玩家控制的圆形，使用 `mut` 表示 `x` 和 `y` 是可变的，即可以通过玩家输入移动。包含 `speed` 用于控制移动速度。

- **AvoidCircle**: 需要避开的圆形，与 `ControlCircle` 相似，带有 `speed` 属性，用于自动朝向玩家圆形移动。

- **AbsorbCircle**: 可吸收的圆形，这些物体在游戏中为玩家提供得分。

- **Bomb**: 定义了炸弹的结构，包含 `active` 属性表示炸弹是否激活。

## 2. 游戏状态的结构体

- **Game**: 这是游戏的主结构体，包含游戏的整体状态和数据。
  - `controlCircle`: 玩家控制的圆形对象。
  - `avoid_circle`、`absorb_circle` 和 `bombs`: 存储避开、吸收和炸弹对象的数组。
  - `score`: 游戏分数。
  - `frame_count`: 用于控制帧数。
  - `prev_gamepad`: 记录上一次的游戏控制器状态。
  - `game_over`: 游戏结束标志。
  - `bomb_animation_frame` 和 `bomb_animation_frame_max`: 控制炸弹动画效果。
  - `last_stars`: 存储上一次生成的星星位置，用于生成背景星空。

## 3. 转换函数

这些函数将不同类型的圆形对象（如 `ControlCircle`、`Bomb` 等）转换为 `Circle` 类型，以便在通用的碰撞检测等功能中使用。

```rust
fn control_to_circle(control: ControlCircle) -> Circle
fn bomb_to_circle(bomb: Bomb) -> Circle
fn avoid_to_circle(avoid: AvoidCircle) -> Circle
fn absorb_to_circle(absorb: AbsorbCircle) -> Circle
```
## 4. 游戏初始化函数

- **Game::new()**: 初始化 `Game` 对象，设置所有属性的初始值，包括圆形的位置、炸弹的初始生成、星空背景初始化等。

## 5. 游戏主循环更新函数

- **update()**: 这是游戏的核心更新函数。根据当前游戏状态决定不同的处理逻辑，包括显示指令、更新玩家控制输入、移动圆形、生成新物体、处理碰撞等。主要步骤包括：

  - 若 `show_instructions` 为真，显示游戏指令界面，按下按钮开始游戏。
  - 若 `game_over` 为真，显示游戏结束画面，并播放游戏结束音效。
  - 处理用户输入、圆形移动、生成新物体、更新炸弹、检查碰撞、渲染游戏元素等。

## 6. 渲染函数

- **display_instructions()**: 显示游戏指令界面，描述了控制按钮、游戏物体和玩家的功能。

- **draw_space_background()**: 绘制星空背景，包括星星位置的随机生成和帧更新。

- **render()**: 渲染游戏中的所有对象，包括 `ControlCircle`、`AvoidCircles`、`AbsorbCircles` 和 `Bomb` 的位置和状态，并在每帧中检查并更新炸弹动画效果。

## 7. 游戏逻辑控制函数

- **moveAvoidAndAbsorbCircles()**: 控制 `AvoidCircle` 自动朝向玩家移动，`AbsorbCircle` 则以较慢速度朝向玩家移动。

- **spawnAvoidCircle()**, **spawnAbsorbCircle()**, **spawnBomb()**: 定时生成新的 `AvoidCircle`、`AbsorbCircle` 和 `Bomb`，生成的频率分别为 120、180 和 300 帧。

- **updateBombs()**: 处理 `Bomb` 的逻辑。若玩家控制的圆形碰撞炸弹，炸弹会爆炸，触发 `bomb_activated`，然后触发炸弹爆炸音效。

- **collision()**: 检测玩家控制圆形与 `AvoidCircle`、`AbsorbCircle` 是否发生碰撞：
  - 与 `AvoidCircle` 碰撞时触发 `game_over`。
  - 与 `AbsorbCircle` 碰撞时增加得分并移除该 `AbsorbCircle`。

- **input()**: 处理玩家的控制输入，更新 `ControlCircle` 的位置并限制其在屏幕边界内。

## 8. 辅助函数

- **check_collision()**: 检测两个 `Circle` 对象是否发生碰撞。

- **随机位置生成函数**: 包含 `random_x_position()`, `random_y_position()`, `random_x_position_bomb()`, 和 `random_y_position_bomb()`，用于生成物体的随机坐标。

- **is_in_bomb_range()**: 用于检测 `AvoidCircle` 是否处于炸弹的范围内，在炸弹激活后将 `AvoidCircle` 转换为 `AbsorbCircle`。
