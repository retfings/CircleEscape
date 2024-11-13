// 定义结构体
pub struct Circle {
  x : Int
  y : Int
  width : Int
  height : Int
}

//  你
pub struct ControlCircle {
  mut x : Int
  mut y : Int
  width : Int
  height : Int
  speed : Int
}

//  避免碰撞
pub struct AvoidCircle {
  mut x : Int
  mut y : Int
  width : Int
  height : Int
  speed : Int
}

//  可吸收的
pub struct AbsorbCircle {
  mut x : Int
  mut y : Int
  width : Int
  height : Int
}

pub struct Bomb {
  x : Int
  y : Int
  width : Int
  height : Int
  mut active : Bool
}

// 定义游戏结构体
pub struct Game {
  mut controlCircle : ControlCircle // 玩家控制的圆
  mut avoid_circle : Array[AvoidCircle] // 玩家需要避开的物体
  mut absorb_circle : Array[AbsorbCircle] // 可吸收的物体
  mut bombs : Array[Bomb] // 游戏中的 Bombs
  mut score : UInt // 游戏得分
  mut frame_count : UInt
  mut prev_gamepad : @wasm4.GamePad
  mut game_over : Bool // 游戏结束标志
  mut game_over_sound_played : Bool
  mut show_instructions : Bool // 控制是否显示启动界面
  mut bomb_animation_frame : Int // 控制 Bomb 的动画帧
  mut bomb_activated : Bool // Bomb 是否被激活
  mut bomb_animation_frame_max : Int // 控制 Bomb 的动画帧
  mut is_init_backgrand : Bool
  mut last_stars : Array[(Int, Int)] // 存放上一次的星星位置
}

// 定义转换函数
fn control_to_circle(control : ControlCircle) -> Circle {
  return {
    x: control.x,
    y: control.y,
    width: control.width,
    height: control.height,
  }
}

fn bomb_to_circle(bomb : Bomb) -> Circle {
  return { x: bomb.x, y: bomb.y, width: bomb.width, height: bomb.height }
}

fn avoid_to_circle(avoid : AvoidCircle) -> Circle {
  return { x: avoid.x, y: avoid.y, width: avoid.width, height: avoid.height }
}

fn absorb_to_circle(absorb : AbsorbCircle) -> Circle {
  return {
    x: absorb.x,
    y: absorb.y,
    width: absorb.width,
    height: absorb.height,
  }
}

pub fn Game::new() -> Game {
  {
    controlCircle: { x: 80, y: 80, width: 8, height: 8, speed: 2 },
    frame_count: 0,
    prev_gamepad: @wasm4.GamePad::default(),
    game_over: false,
    game_over_sound_played: false,
    show_instructions: true, // 初始化为 true 表示显示启动界面
    score: 0,
    bomb_animation_frame: 0,
    bomb_animation_frame_max: 20,
    bomb_activated: false,
    avoid_circle: [],
    absorb_circle: [],
    bombs: [
      // 初始 Bombs，位置随机
      { x: 40, y: 60, width: 12, height: 12, active: true },
    ],
    is_init_backgrand: false,
    last_stars: [],
  }
}

let game : Game = Game::new()

let random : @random.Rand = @random.new()

pub fn update() -> Unit {
  if game.show_instructions {
    display_instructions()
    let gamepad = @wasm4.get_gamepad()
    if gamepad.button_1 { // 按下按钮1（例如“X”键）以开始游戏
      game.show_instructions = false
    }
    return
  }
  if game.game_over {
    @wasm4.set_draw_colors(2)
    @wasm4.text("Game Over!", 20, 40)
    @wasm4.text("Just Get ", 0, 70)
    @wasm4.text(game.score.to_string(), 80, 70)
    @wasm4.set_draw_colors(2)
    @wasm4.text("Score ", 100, 70)
    @wasm4.text("Press R to Restart ", 0, 100)
    if not(game.game_over_sound_played) {
      // 播放游戏结束音效
      @wasm4.tone_note_mode(
        (@wasm4.Note::new(50, bend=0), None),
        @wasm4.ADSR::new(60),
        @wasm4.ADSRVolume::new(100),
        @wasm4.ToneFlag::new(),
      )
      game.game_over_sound_played = true // 确保音效仅播放一次
    }
    return
  }
  game.frame_count = game.frame_count + 1
  game.input()
  game.moveAvoidAndAbsorbCircles() // 移动 Avoid 和 Absorb 圆形
  game.spawnAvoidCircle()
  game.spawnAbsorbCircle()
  game.spawnBomb() // 每次更新时检查是否生成新的 bomb
  game.updateBombs()
  game.collision()
  game.render()

  // 游戏过程中循环播放的背景音乐
  // if game.frame_count % 60 == 0 {
  //   @wasm4.tone_note_mode(
  //     (@wasm4.Note::new(60, bend=0), None),
  //     @wasm4.ADSR::new(60),
  //     @wasm4.ADSRVolume::new(100),
  //     @wasm4.ToneFlag::new(),
  //   ) // 游戏背景音
  // }
}

pub fn display_instructions() -> Unit {
  @wasm4.set_draw_colors(2)
  @wasm4.text("--- HOW TO PLAY ---", 10, 10)

  // 显示玩家的圆形
  @wasm4.set_draw_colors(3) // 设置玩家圆形颜色
  @wasm4.oval(10, 30, 8, 8) // 绘制玩家的圆形
  @wasm4.text(": You", 20, 30)

  // 显示需要避开的物体
  @wasm4.set_draw_colors(2)
  @wasm4.oval(10, 40, 8, 8) // 绘制避开的物体
  @wasm4.text(": Avoid", 20, 40)

  // 显示可以吸收的物体
  @wasm4.set_draw_colors(4)
  @wasm4.oval(10, 50, 8, 8) // 绘制可吸收的物体
  @wasm4.text(": Absorb", 20, 50)

  // 显示 Bomb
  //   @wasm4.set_draw_colors(0) // 设置为透明
  //   @wasm4.oval(10, 60, 12, 12) // 先绘制一个透明的圆
  //   @wasm4.set_draw_colors(2) // 设置边框颜色为黑色
  //   @wasm4.set_draw_colors(2, index=2)
  @wasm4.set_draw_colors(1)
  @wasm4.oval(8, 60, 12, 12) // 绘制空心的黑色边框圆
  @wasm4.set_draw_colors(2)
  @wasm4.text(": Bomb", 20, 60)

  // 播放开始界面的背景音乐
  // @wasm4.tone(220, 10, 20, 1) // 简单的背景音

  // 其他说明
  //   @wasm4.set_draw_colors(1, index=1)
  //   @wasm4.set_draw_colors(2, index=2)
  //   @wasm4.set_draw_colors(3, index=3)
  //   @wasm4.set_draw_colors(4, index=4)
  //   @wasm4.set_draw_colors(2)

  @wasm4.text("Move:", 10, 80)
  @wasm4.text("Left Right Up Down", 10, 100)
  @wasm4.text("Start: X", 10, 120)
  //   @wasm4.text("-- Multiplayer --", 10, 110)
  //   @wasm4.text("Up to 4 Players", 10, 120)
  //   @wasm4.text("Press X to Start", 10, 140)
}

pub fn draw_space_background(self : Game) -> Unit {
  // 绘制一个深色的背景（如黑色）
  @wasm4.set_draw_colors(0) // 0 代表黑色
  @wasm4.rect(0, 0, 160, 160) // 绘制整个屏幕
  if self.is_init_backgrand {
    for i = 0; i < self.last_stars.length(); i = i + 1 {
      @wasm4.set_draw_colors(4) //
      @wasm4.rect(self.last_stars[i].0, self.last_stars[i].1, 2, 2) // 绘制小星星
    }
  }
  if not(self.is_init_backgrand) {
    let stars = []
    for i = 0; i < 40; i = i + 1 {
      let star_x = random.int() % 160
      let star_y = random.int() % 160
      stars.append([(star_x, star_y)])
      @wasm4.set_draw_colors(4) //
      @wasm4.rect(star_x, star_y, 2, 2) // 绘制小星星
    }
    self.is_init_backgrand = true
    self.last_stars = stars // 保存上一次的星星位置
    // 随机绘制一些星星
  } else if self.frame_count % 60 == 0 {
    // 更新星星位置
    let new_stars : Array[(Int, Int)] = []
    for i = 0; i < 40; i = i + 1 {
      let star_x = random.int() % 160
      let star_y = random.int() % 160
      new_stars.append([(star_x, star_y)])
    }
    self.last_stars = new_stars
  }
}

// 移动 AvoidCircle 和 AbsorbCircle
pub fn moveAvoidAndAbsorbCircles(self : Game) -> Unit {
  // 移动 AvoidCircle
  for avoid in self.avoid_circle {
    let dx = self.controlCircle.x - avoid.x
    let dy = self.controlCircle.y - avoid.y
    avoid.x += if dx > 0 {
      avoid.speed
    } else if dx < 0 {
      -avoid.speed
    } else {
      0
    }
    avoid.y += if dy > 0 {
      avoid.speed
    } else if dy < 0 {
      -avoid.speed
    } else {
      0
    }
  }

  // 移动 AbsorbCircle
  for absorb in self.absorb_circle {
    let dx = self.controlCircle.x - absorb.x
    let dy = self.controlCircle.y - absorb.y
    absorb.x += if dx > 0 { 1 } else if dx < 0 { -1 } else { 0 }
    absorb.y += if dy > 0 { 1 } else if dy < 0 { -1 } else { 0 }
  }
}

// 渲染游戏元素
pub fn render(self : Game) -> Unit {
  draw_space_background(self)
  @wasm4.set_draw_colors(3)
  @wasm4.oval(
    self.controlCircle.x,
    self.controlCircle.y,
    self.controlCircle.width,
    self.controlCircle.height,
  )
  for avoid in self.avoid_circle {
    @wasm4.set_draw_colors(2)
    @wasm4.oval(avoid.x, avoid.y, avoid.width, avoid.height)
  }
  for absorb in self.absorb_circle {
    @wasm4.set_draw_colors(4) // 吸收物体的颜色
    @wasm4.oval(absorb.x, absorb.y, absorb.width, absorb.height)
  }
  for bomb in self.bombs {
    if bomb.active {
      @wasm4.set_draw_colors(1)
      @wasm4.oval(bomb.x, bomb.y, bomb.width, bomb.height)
    }
  }

  // Bomb 扩展动画效果
  if self.bomb_activated {
    self.bomb_animation_frame += 1
    @wasm4.set_draw_colors(1)
    @wasm4.oval(
      self.controlCircle.x - self.bomb_animation_frame,
      self.controlCircle.y - self.bomb_animation_frame,
      self.bomb_animation_frame * 2,
      self.bomb_animation_frame * 2,
    )
    if self.bomb_animation_frame > self.bomb_animation_frame_max {
      self.bomb_activated = false
      self.bomb_animation_frame = 0
    }
  }

  // 持续将范围内的 Avoid 转换为 Absorb
  if game.bomb_animation_frame > 0 {
    for index = 0; index < game.avoid_circle.length(); index = index + 1 {
      let avoid = game.avoid_circle[index]
      for bomb in game.bombs {
        if is_in_bomb_range(
            avoid_to_circle(avoid),
            bomb_to_circle(bomb),
            game.bomb_animation_frame,
          ) {
          let new_absorb = avoid_to_absorb(avoid)
          game.absorb_circle.push(new_absorb)
          let _ = game.avoid_circle.remove(index)

        }
      }
    }
    // 每次调用减少 bomb_animation_frame 直到其归零
    // game.bomb_animation_frame -= 1
  }
  @wasm4.set_draw_colors(2)
  @wasm4.text("Score: " + self.score.to_string(), 5, 5)
}

// 生成新的 AvoidCircle
pub fn spawnAvoidCircle(self : Game) -> Unit {
  if self.frame_count % 120 == 0 {
    let x = random_x_position()
    let y = random_y_position()
    self.avoid_circle.push({ x, y, width: 6, height: 6, speed: 1 })
  }
}

// 生成新的 AbsorbCircle
pub fn spawnAbsorbCircle(self : Game) -> Unit {
  if self.frame_count % 180 == 0 {
    let x = random_x_position()
    let y = random_y_position()
    self.absorb_circle.push({ x, y, width: 6, height: 6 })
  }
}

// 生成新的 Bomb
pub fn spawnBomb(self : Game) -> Unit {
  if self.frame_count % 300 == 0 {
    let x = random_x_position_bomb()
    let y = random_y_position_bomb()
    self.bombs.push({ x, y, width: 12, height: 12, active: true })
  }
}

// 更新 Bombs
pub fn updateBombs(self : Game) -> Unit {
  for bomb in self.bombs {
    if bomb.active &&
      check_collision(
        control_to_circle(self.controlCircle),
        bomb_to_circle(bomb),
      ) {
      bomb.active = false
      self.bomb_activated = true

      // Bomb 爆炸音效
      @wasm4.tone_note_mode(
        (@wasm4.Note::new(72, bend=0), None),
        @wasm4.ADSR::new(40),
        @wasm4.ADSRVolume::new(80),
        @wasm4.ToneFlag::new(),
      )
      for index = 0; index < self.avoid_circle.length(); index = index + 1 {
        let avoid = self.avoid_circle[index]
        if is_in_bomb_range(
            avoid_to_circle(avoid),
            bomb_to_circle(bomb),
            self.bomb_animation_frame_max,
          ) {
          let new_absorb = avoid_to_absorb(avoid)
          self.absorb_circle.push(new_absorb)
          let _ = self.avoid_circle.remove(index)

        }
      }
    }
  }
}

// 将 AvoidCircle 转换为 AbsorbCircle 的函数
fn avoid_to_absorb(avoid : AvoidCircle) -> AbsorbCircle {
  return { x: avoid.x, y: avoid.y, width: avoid.width, height: avoid.height }
}

// 检查碰撞
pub fn collision(self : Game) -> Unit {
  for avoid in self.avoid_circle {
    if check_collision(
        control_to_circle(self.controlCircle),
        avoid_to_circle(avoid),
      ) {
      self.game_over = true

      // 播放奖励音效
      @wasm4.tone_note_mode(
        (@wasm4.Note::new(76, bend=0), None),
        @wasm4.ADSR::new(20),
        @wasm4.ADSRVolume::new(90),
        @wasm4.ToneFlag::new(),
      )
    }
  }
  for index = 0; index < self.absorb_circle.length(); index = index + 1 {
    let absorb = self.absorb_circle[index]
    if check_collision(
        control_to_circle(self.controlCircle),
        absorb_to_circle(absorb),
      ) {
      self.score += 1
      let _ = self.absorb_circle.remove(index)

      // 播放“吃到”物体的音效
      @wasm4.tone_note_mode(
        (@wasm4.Note::new(64, bend=0), None),
        @wasm4.ADSR::new(20),
        @wasm4.ADSRVolume::new(50),
        @wasm4.ToneFlag::new(),
      )
    }
  }
}

// 控制输入
pub fn input(self : Game) -> Unit {
  let gamepad = @wasm4.get_gamepad()
  if gamepad.button_down {
    self.controlCircle.y = self.controlCircle.y + self.controlCircle.speed
  }
  if gamepad.button_left {
    self.controlCircle.x = self.controlCircle.x - self.controlCircle.speed
  }
  if gamepad.button_right {
    self.controlCircle.x = self.controlCircle.x + self.controlCircle.speed
  }
  if gamepad.button_up {
    self.controlCircle.y = self.controlCircle.y - self.controlCircle.speed
  }
  // 限制 ControlCircle 的移动范围在屏幕内
  let max_x = 160 - self.controlCircle.width
  let max_y = 160 - self.controlCircle.height
  if self.controlCircle.x < 0 {
    self.controlCircle.x = 0
  } else if self.controlCircle.x > max_x {
    self.controlCircle.x = max_x
  }
  if self.controlCircle.y < 0 {
    self.controlCircle.y = 0
  } else if self.controlCircle.y > max_y {
    self.controlCircle.y = max_y
  }
  self.prev_gamepad = gamepad
}

// 工具函数
fn check_collision(a : Circle, b : Circle) -> Bool {
  let dx = a.x + a.width / 2 - (b.x + b.width / 2)
  let dy = a.y + a.height / 2 - (b.y + b.height / 2)
  let distance_squared = dx * dx + dy * dy
  let radius_sum = a.width / 2 + b.width / 2
  let radius_sum_squared = radius_sum * radius_sum
  return distance_squared < radius_sum_squared
}

fn random_x_position() -> Int {
  // 先随机选择范围，然后生成对应范围内的随机 x 坐标
  if random.int() % 2 == 0 {
    return -160 + random.int() % 160
  } else {
    return 160 + random.int() % 160
  }
}

fn random_y_position() -> Int {
  // 先随机选择范围，然后生成对应范围内的随机 y 坐标
  if random.int() % 2 == 0 {
    return -160 + random.int() % 160
  } else {
    return 160 + random.int() % 160
  }
}

fn random_x_position_bomb() -> Int {
  return random.int() % 160
}

fn random_y_position_bomb() -> Int {
  return random.int() % 160
}

fn is_in_bomb_range(avoid : Circle, bomb : Circle, radius : Int) -> Bool {
  let dx = avoid.x + avoid.width / 2 - (bomb.x + bomb.width / 2)
  let dy = avoid.y + avoid.height / 2 - (bomb.y + bomb.height / 2)
  let distance_squared = dx * dx + dy * dy
  let radius_squared = radius * radius
  return distance_squared < radius_squared
}
