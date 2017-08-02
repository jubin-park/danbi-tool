# encoding: utf-8
# ruby 2.3.3p222 (2016-11-21 revision 56859) [x64-mingw32]

module Game
  module_function
  def init; @gameMap = Map.new; end
  def map;  return @gameMap; end
end

class Character
  attr_reader   :id                       # ID
  attr_reader   :x                        # 맵 X 좌표 (논리 좌표)
  attr_reader   :y                        # 맵 Y 좌표 (논리 좌표)
  attr_reader   :real_x                   # 맵 X 좌표 (실좌표 * 128)
  attr_reader   :real_y                   # 맵 Y 좌표 (실좌표 * 128)
  attr_reader   :tile_id                  # 타일 ID  (0 이라면 무효)
  attr_reader   :character_name           # 캐릭터 파일명
  attr_reader   :character_hue            # 캐릭터 색상
  attr_reader   :opacity                  # 불투명도
  attr_reader   :blend_type               # 합성 방법
  attr_reader   :direction                # 방향
  attr_reader   :pattern                  # 패턴
  attr_reader   :through                  # 통행 가능
  attr_accessor :animation_id             # 애니메이션 ID
  attr_accessor :transparent              # 투명상태
  attr_accessor :move_speed
  attr_accessor :damages
  attr_accessor :isIcon

  def initialize
    @id = 0
    @x = 0
    @y = 0
    @real_x = 0
    @real_y = 0
    @tile_id = 0
    @character_name = ""
    @character_hue = 0
    @opacity = 255
    @blend_type = 0
    @direction = 2
    @pattern = 0
    @through = false
    @animation_id = 0
    @transparent = false
    @original_direction = 2
    @original_pattern = 0
    @move_type = 0
    @move_speed = 4
    @move_frequency = 6
    @move_route = nil
    @move_route_index = 0
    @original_move_route = nil
    @original_move_route_index = 0
    @walk_anime = true
    @step_anime = false
    @direction_fix = false
    @always_on_top = false
    @anime_count = 0
    @stop_count = 0
    @jump_count = 0
    @jump_peak = 0
    @wait_count = 0
    @locked = false
    @prelock_direction = 0
    @damages = []
    @isIcon = false
  end

  def moveto(x, y)
    @x = x % Game.map.width
    @y = y % Game.map.height
    @real_x = @x * 128
    @real_y = @y * 128
  end
end

class Event < Character
  attr_reader   :trigger
  attr_reader   :list
  attr_reader   :starting
  attr_reader   :page
  attr_accessor :erased

  def initialize(map_id, event)
    super()
    @map_id = map_id
    @event = event
    @id = @event.id
    # 초기 위치에 이동
    moveto(@event.x, @event.y)
  end
end


class Map
  attr_accessor :tileset_name             # 타일 세트 파일명
  attr_accessor :autotile_names           # 오토 타일 파일명
  attr_accessor :panorama_name            # 파노라마 파일명
  attr_accessor :panorama_hue             # 파노라마 색상
  attr_accessor :fog_name                 # 포그 파일명
  attr_accessor :fog_hue                  # 포그 색상
  attr_accessor :fog_opacity              # 포그 불투명도
  attr_accessor :fog_blend_type           # 포그 브랜드 방법
  attr_accessor :fog_zoom                 # 포그 확대율
  attr_accessor :fog_sx                   # 포그 SX
  attr_accessor :fog_sy                   # 포그 SY
  attr_accessor :battleback_name          # 배틀 백 파일명
  attr_accessor :display_x                # 표시 X 좌표 * 128
  attr_accessor :display_y                # 표시 Y 좌표 * 128
  attr_accessor :need_refresh             # 리프레쉬 요구 플래그
  attr_reader   :passages                 # 통행 테이블
  attr_reader   :priorities               # priority 테이블
  attr_reader   :terrain_tags             # 지형 태그 테이블
  attr_reader   :fog_ox                   # 포그 원점 X 좌표
  attr_reader   :fog_oy                   # 포그 원점 Y 좌표
  attr_reader   :fog_tone                 # 포그 색조
  attr_reader   :events                   # 이벤트
  attr_reader   :netplayers               # 넷플레이어
  attr_reader   :npcs                     # NPC
  attr_reader   :enemies                   # 에너미

  def initialize
    @map_id = 0
    @display_x = 0
    @display_y = 0
  end

  def setup(map_id)
    @map_id = map_id
    @map = load_data(sprintf("Data/Map%03d.rxdata", @map_id))
    tileset = $data_tilesets[@map.tileset_id]
    @tileset_name = tileset.tileset_name
    @autotile_names = tileset.autotile_names
    @panorama_name = tileset.panorama_name
    @panorama_hue = tileset.panorama_hue
    @fog_name = tileset.fog_name
    @fog_hue = tileset.fog_hue
    @fog_opacity = tileset.fog_opacity
    @fog_blend_type = tileset.fog_blend_type
    @fog_zoom = tileset.fog_zoom
    @fog_sx = tileset.fog_sx
    @fog_sy = tileset.fog_sy
    @battleback_name = tileset.battleback_name
    @passages = tileset.passages
    @priorities = tileset.priorities
    @terrain_tags = tileset.terrain_tags
    @display_x = 0
    @display_y = 0
    @need_refresh = false
    @events = {}
    for i in @map.events.keys
      @events[i] = Event.new(@map_id, @map.events[i])
    end
    @netplayers = {}
    @npcs = {}
    @enemies = {}
    @items = {}
    @fog_ox = 0
    @fog_oy = 0
    @fog_tone = nil#Tone.new(0, 0, 0, 0)
    @fog_tone_target = nil#Tone.new(0, 0, 0, 0)
    @fog_tone_duration = 0
    @fog_opacity_duration = 0
    @fog_opacity_target = 0
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
  end

  def map_id
    return @map_id
  end

  def width
    return @map.width
  end

  def height
    return @map.height
  end

  def data
    return @map.data
  end

  def valid?(x, y)
    return (x >= 0 and x < width and y >= 0 and y < height)
  end

  def passable?(x, y, d, self_event = nil)
    unless valid?(x, y)
      return false
    end
    bit = (1 << (d / 2 - 1)) & 0x0f
    for event in events.values
      if event.tile_id >= 0 and event != self_event and
         event.x == x and event.y == y and not event.through
        if @passages[event.tile_id] & bit != 0
          return false
        elsif @passages[event.tile_id] & 0x0f == 0x0f
          return false
        elsif @priorities[event.tile_id] == 0
          return true
        end
      end
    end
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      if tile_id == nil
        return false
      elsif @passages[tile_id] & bit != 0
        return false
      elsif @passages[tile_id] & 0x0f == 0x0f
        return false
      elsif @priorities[tile_id] == 0
        return true
      end
    end
    return true
  end
end

module RPG
  class Map
    def initialize(width, height)
      @tileset_id = 1
      @width = width
      @height = height
      @autoplay_bgm = false
      @bgm = RPG::AudioFile.new
      @autoplay_bgs = false
      @bgs = RPG::AudioFile.new('', 80)
      @encounter_list = []
      @encounter_step = 30
      @data = Table.new(width, height, 3)
      @events = {}
    end
    attr_accessor :tileset_id
    attr_accessor :width
    attr_accessor :height
    attr_accessor :autoplay_bgm
    attr_accessor :bgm
    attr_accessor :autoplay_bgs
    attr_accessor :bgs
    attr_accessor :encounter_list
    attr_accessor :encounter_step
    attr_accessor :data
    attr_accessor :events
  end
   
  class MapInfo
    def initialize
      @name = ''
      @parent_id = 0
      @order = 0
      @expanded = false
      @scroll_x = 0
      @scroll_y = 0
    end
      attr_accessor :name
      attr_accessor :parent_id
      attr_accessor :order
      attr_accessor :expanded
      attr_accessor :scroll_x
      attr_accessor :scroll_y
    end
  
  class Event
    def initialize(x, y)
      @id = 0
      @name = ''
      @x = x
      @y = y
      @pages = [RPG::Event::Page.new]
    end
      attr_accessor :id
      attr_accessor :name
      attr_accessor :x
      attr_accessor :y
      attr_accessor :pages
    end
  
  class Event
    class Page
      def initialize
        @condition = RPG::Event::Page::Condition.new
        @graphic = RPG::Event::Page::Graphic.new
        @move_type = 0
        @move_speed = 3
        @move_frequency = 3
        @move_route = RPG::MoveRoute.new
        @walk_anime = true
        @step_anime = false
        @direction_fix = false
        @through = false
        @always_on_top = false
        @trigger = 0
        @list = [RPG::EventCommand.new]
      end
      attr_accessor :condition
      attr_accessor :graphic
      attr_accessor :move_type
      attr_accessor :move_speed
      attr_accessor :move_frequency
      attr_accessor :move_route
      attr_accessor :walk_anime
      attr_accessor :step_anime
      attr_accessor :direction_fix
      attr_accessor :through
      attr_accessor :always_on_top
      attr_accessor :trigger
      attr_accessor :list
    end
  end
   
  class Event
    class Page
      class Condition
        def initialize
          @switch1_valid = false
          @switch2_valid = false
          @variable_valid = false
          @self_switch_valid = false
          @switch1_id = 1
          @switch2_id = 1
          @variable_id = 1
          @variable_value = 0
          @self_switch_ch = 'A'
        end
        attr_accessor :switch1_valid
        attr_accessor :switch2_valid
        attr_accessor :variable_valid
        attr_accessor :self_switch_valid
        attr_accessor :switch1_id
        attr_accessor :switch2_id
        attr_accessor :variable_id
        attr_accessor :variable_value
        attr_accessor :self_switch_ch
      end
    end
  end
   
  class Event
    class Page
      class Graphic
        def initialize
          @tile_id = 0
          @character_name = ''
          @character_hue = 0
          @direction = 2
          @pattern = 0
          @opacity = 255
          @blend_type = 0
        end
        attr_accessor :tile_id
        attr_accessor :character_name
        attr_accessor :character_hue
        attr_accessor :direction
        attr_accessor :pattern
        attr_accessor :opacity
        attr_accessor :blend_type
      end
    end
  end
   
  class EventCommand
    def initialize(code = 0, indent = 0, parameters = [])
      @code = code
      @indent = indent
      @parameters = parameters
    end
    attr_accessor :code
    attr_accessor :indent
    attr_accessor :parameters
  end
  
  class MoveRoute
    def initialize
      @repeat = true
      @skippable = false
      @list = [RPG::MoveCommand.new]
    end
    attr_accessor :repeat
    attr_accessor :skippable
    attr_accessor :list
  end
  
  class MoveCommand
    def initialize(code = 0, parameters = [])
      @code = code
      @parameters = parameters
    end
    attr_accessor :code
    attr_accessor :parameters
  end
  
  class Actor
    def initialize
      @id = 0
      @name = ''
      @class_id = 1
      @initial_level = 1
      @final_level = 99
      @exp_basis = 30
      @exp_inflation = 30
      @character_name = ''
      @character_hue = 0
      @battler_name = ''
      @battler_hue = 0
      @parameters = Table.new(6,100)
      for i in 1..99
        @parameters[0,i] = 500+i*50
        @parameters[1,i] = 500+i*50
        @parameters[2,i] = 50+i*5
        @parameters[3,i] = 50+i*5
        @parameters[4,i] = 50+i*5
        @parameters[5,i] = 50+i*5
      end
      @weapon_id = 0
      @armor1_id = 0
      @armor2_id = 0
      @armor3_id = 0
      @armor4_id = 0
      @weapon_fix = false
      @armor1_fix = false
      @armor2_fix = false
      @armor3_fix = false
      @armor4_fix = false
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :class_id
    attr_accessor :initial_level
    attr_accessor :final_level
    attr_accessor :exp_basis
    attr_accessor :exp_inflation
    attr_accessor :character_name
    attr_accessor :character_hue
    attr_accessor :battler_name
    attr_accessor :battler_hue
    attr_accessor :parameters
    attr_accessor :weapon_id
    attr_accessor :armor1_id
    attr_accessor :armor2_id
    attr_accessor :armor3_id
    attr_accessor :armor4_id
    attr_accessor :weapon_fix
    attr_accessor :armor1_fix
    attr_accessor :armor2_fix
    attr_accessor :armor3_fix
    attr_accessor :armor4_fix
  end
 
  class Class
    def initialize
      @id = 0
      @name = ''
      @position = 0
      @weapon_set = []
      @armor_set = []
      @element_ranks = Table.new(1)
      @state_ranks = Table.new(1)
      @learnings = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :position
    attr_accessor :weapon_set
    attr_accessor :armor_set
    attr_accessor :element_ranks
    attr_accessor :state_ranks
    attr_accessor :learnings
  end
  
  class Class
    class Learning
      def initialize
        @level = 1
        @skill_id = 1
      end
      attr_accessor :level
      attr_accessor :skill_id
    end
  end
  
  class Skill
    def initialize
      @id = 0
      @name = ''
      @icon_name = ''
      @description = ''
      @scope = 0
      @occasion = 1
      @animation1_id = 0
      @animation2_id = 0
      @menu_se = RPG::AudioFile.new('', 80)
      @common_event_id = 0
      @sp_cost = 0
      @power = 0
      @atk_f = 0
      @eva_f = 0
      @str_f = 0
      @dex_f = 0
      @agi_f = 0
      @int_f = 100
      @hit = 100
      @pdef_f = 0
      @mdef_f = 100
      @variance = 15
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :scope
    attr_accessor :occasion
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :menu_se
    attr_accessor :common_event_id
    attr_accessor :sp_cost
    attr_accessor :power
    attr_accessor :atk_f
    attr_accessor :eva_f
    attr_accessor :str_f
    attr_accessor :dex_f
    attr_accessor :agi_f
    attr_accessor :int_f
    attr_accessor :hit
    attr_accessor :pdef_f
    attr_accessor :mdef_f
    attr_accessor :variance
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  class Item
    def initialize
      @id = 0
      @name = ''
      @icon_name = ''
      @description = ''
      @scope = 0
      @occasion = 0
      @animation1_id = 0
      @animation2_id = 0
      @menu_se = RPG::AudioFile.new('', 80)
      @common_event_id = 0
      @price = 0
      @consumable = true
      @parameter_type = 0
      @parameter_points = 0
      @recover_hp_rate = 0
      @recover_hp = 0
      @recover_sp_rate = 0
      @recover_sp = 0
      @hit = 100
      @pdef_f = 0
      @mdef_f = 0
      @variance = 0
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :scope
    attr_accessor :occasion
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :menu_se
    attr_accessor :common_event_id
    attr_accessor :sp_cost
    attr_accessor :power
    attr_accessor :atk_f
    attr_accessor :eva_f
    attr_accessor :str_f
    attr_accessor :dex_f
    attr_accessor :agi_f
    attr_accessor :int_f
    attr_accessor :hit
    attr_accessor :pdef_f
    attr_accessor :mdef_f
    attr_accessor :variance
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  class Item
    def initialize
      @id = 0
      @name = ''
      @icon_name = ''
      @description = ''
      @scope = 0
      @occasion = 0
      @animation1_id = 0
      @animation2_id = 0
      @menu_se = RPG::AudioFile.new('', 80)
      @common_event_id = 0
      @price = 0
      @consumable = true
      @parameter_type = 0
      @parameter_points = 0
      @recover_hp_rate = 0
      @recover_hp = 0
      @recover_sp_rate = 0
      @recover_sp = 0
      @hit = 100
      @pdef_f = 0
      @mdef_f = 0
      @variance = 0
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :scope
    attr_accessor :occasion
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :menu_se
    attr_accessor :common_event_id
    attr_accessor :price
    attr_accessor :consumable
    attr_accessor :parameter_type
    attr_accessor :parameter_points
    attr_accessor :recover_hp_rate
    attr_accessor :recover_hp
    attr_accessor :recover_sp_rate
    attr_accessor :recover_sp
    attr_accessor :hit
    attr_accessor :pdef_f
    attr_accessor :mdef_f
    attr_accessor :variance
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
 
  class Weapon
    def initialize
      @id = 0
      @name = ''
      @icon_name = ''
      @description = ''
      @animation1_id = 0
      @animation2_id = 0
      @price = 0
      @atk = 0
      @pdef = 0
      @mdef = 0
      @str_plus = 0
      @dex_plus = 0
      @agi_plus = 0
      @int_plus = 0
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :price
    attr_accessor :atk
    attr_accessor :pdef
    attr_accessor :mdef
    attr_accessor :str_plus
    attr_accessor :dex_plus
    attr_accessor :agi_plus
    attr_accessor :int_plus
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  class Armor
    def initialize
      @id = 0
      @name = ''
      @icon_name = ''
      @description = ''
      @kind = 0
      @auto_state_id = 0
      @price = 0
      @pdef = 0
      @mdef = 0
      @eva = 0
      @str_plus = 0
      @dex_plus = 0
      @agi_plus = 0
      @int_plus = 0
      @guard_element_set = []
      @guard_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :kind
    attr_accessor :auto_state_id
    attr_accessor :price
    attr_accessor :pdef
    attr_accessor :mdef
    attr_accessor :eva
    attr_accessor :str_plus
    attr_accessor :dex_plus
    attr_accessor :agi_plus
    attr_accessor :int_plus
    attr_accessor :guard_element_set
    attr_accessor :guard_state_set
  end
  
  class Enemy
    def initialize
      @id = 0
      @name = ''
      @battler_name = ''
      @battler_hue = 0
      @maxhp = 500
      @maxsp = 500
      @str = 50
      @dex = 50
      @agi = 50
      @int = 50
      @atk = 100
      @pdef = 100
      @mdef = 100
      @eva = 0
      @animation1_id = 0
      @animation2_id = 0
      @element_ranks = Table.new(1)
      @state_ranks = Table.new(1)
      @actions = [RPG::Enemy::Action.new]
      @exp = 0
      @gold = 0
      @item_id = 0
      @weapon_id = 0
      @armor_id = 0
      @treasure_prob = 100
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :battler_name
    attr_accessor :battler_hue
    attr_accessor :maxhp
    attr_accessor :maxsp
    attr_accessor :str
    attr_accessor :dex
    attr_accessor :agi
    attr_accessor :int
    attr_accessor :atk
    attr_accessor :pdef
    attr_accessor :mdef
    attr_accessor :eva
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :element_ranks
    attr_accessor :state_ranks
    attr_accessor :actions
    attr_accessor :exp
    attr_accessor :gold
    attr_accessor :item_id
    attr_accessor :weapon_id
    attr_accessor :armor_id
    attr_accessor :treasure_prob
  end
  
  class Enemy
    class Action
      def initialize
        @kind = 0
        @basic = 0
        @skill_id = 1
        @condition_turn_a = 0
        @condition_turn_b = 1
        @condition_hp = 100
        @condition_level = 1
        @condition_switch_id = 0
        @rating = 5
      end
      attr_accessor :kind
      attr_accessor :basic
      attr_accessor :skill_id
      attr_accessor :condition_turn_a
      attr_accessor :condition_turn_b
      attr_accessor :condition_hp
      attr_accessor :condition_level
      attr_accessor :condition_switch_id
      attr_accessor :rating
    end
  end
  
  class Troop
    def initialize
      @id = 0
      @name = ''
      @members = []
      @pages = [RPG::Troop::Page.new]
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :members
    attr_accessor :pages
  end
  
  class Troop
    class Member
      def initialize
        @enemy_id = 1
        @x = 0
        @y = 0
        @hidden = false
        @immortal = false
      end
      attr_accessor :enemy_id
      attr_accessor :x
      attr_accessor :y
      attr_accessor :hidden
      attr_accessor :immortal
    end
  end
  
  class Troop
    class Page
      def initialize
        @condition = RPG::Troop::Page::Condition.new
        @span = 0
        @list = [RPG::EventCommand.new]
      end
      attr_accessor :condition
      attr_accessor :span
      attr_accessor :list
    end
  end
  
  class Troop
    class Page
      class Condition
        def initialize
          @turn_valid = false
          @enemy_valid = false
          @actor_valid = false
          @switch_valid = false
          @turn_a = 0
          @turn_b = 0
          @enemy_index = 0
          @enemy_hp = 50
          @actor_id = 1
          @actor_hp = 50
          @switch_id = 1
        end
        attr_accessor :turn_valid
        attr_accessor :enemy_valid
        attr_accessor :actor_valid
        attr_accessor :switch_valid
        attr_accessor :turn_a
        attr_accessor :turn_b
        attr_accessor :enemy_index
        attr_accessor :enemy_hp
        attr_accessor :actor_id
        attr_accessor :actor_hp
        attr_accessor :switch_id
      end
    end
  end
  
  class State
    def initialize
      @id = 0
      @name = ''
      @animation_id = 0
      @restriction = 0
      @nonresistance = false
      @zero_hp = false
      @cant_get_exp = false
      @cant_evade = false
      @slip_damage = false
      @rating = 5
      @hit_rate = 100
      @maxhp_rate = 100
      @maxsp_rate = 100
      @str_rate = 100
      @dex_rate = 100
      @agi_rate = 100
      @int_rate = 100
      @atk_rate = 100
      @pdef_rate = 100
      @mdef_rate = 100
      @eva = 0
      @battle_only = true
      @hold_turn = 0
      @auto_release_prob = 0
      @shock_release_prob = 0
      @guard_element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :animation_id
    attr_accessor :restriction
    attr_accessor :nonresistance
    attr_accessor :zero_hp
    attr_accessor :cant_get_exp
    attr_accessor :cant_evade
    attr_accessor :slip_damage
    attr_accessor :rating
    attr_accessor :hit_rate
    attr_accessor :maxhp_rate
    attr_accessor :maxsp_rate
    attr_accessor :str_rate
    attr_accessor :dex_rate
    attr_accessor :agi_rate
    attr_accessor :int_rate
    attr_accessor :atk_rate
    attr_accessor :pdef_rate
    attr_accessor :mdef_rate
    attr_accessor :eva
    attr_accessor :battle_only
    attr_accessor :hold_turn
    attr_accessor :auto_release_prob
    attr_accessor :shock_release_prob
    attr_accessor :guard_element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  class Animation
    def initialize
      @id = 0
      @name = ''
      @animation_name = ''
      @animation_hue = 0
      @position = 1
      @frame_max = 1
      @frames = [RPG::Animation::Frame.new]
      @timings = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :animation_name
    attr_accessor :animation_hue
    attr_accessor :position
    attr_accessor :frame_max
    attr_accessor :frames
    attr_accessor :timings
  end
  
class Animation
  class Frame
    def initialize
      @cell_max = 0
      @cell_data = Table.new(0, 0)
    end
    attr_accessor :cell_max
    attr_accessor :cell_data
    end
  end 
  
class Animation
  class Timing
    def initialize
      @frame = 0
      @se = RPG::AudioFile.new('', 80)
      @flash_scope = 0
      @flash_color = Color.new(255,255,255,255)
      @flash_duration = 5
      @condition = 0
    end
      attr_accessor :frame
      attr_accessor :se
      attr_accessor :flash_scope
      attr_accessor :flash_color
      attr_accessor :flash_duration
      attr_accessor :condition
    end
  end
  
  class Tileset
    def initialize
      @id = 0
      @name = ''
      @tileset_name = ''
      @autotile_names = ['']*7
      @panorama_name = ''
      @panorama_hue = 0
      @fog_name = ''
      @fog_hue = 0
      @fog_opacity = 64
      @fog_blend_type = 0
      @fog_zoom = 200
      @fog_sx = 0
      @fog_sy = 0
      @battleback_name = ''
      @passages = Table.new(384)
      @priorities = Table.new(384)
      @priorities[0] = 5
      @terrain_tags = Table.new(384)
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :tileset_name
    attr_accessor :autotile_names
    attr_accessor :panorama_name
    attr_accessor :panorama_hue
    attr_accessor :fog_name
    attr_accessor :fog_hue
    attr_accessor :fog_opacity
    attr_accessor :fog_blend_type
    attr_accessor :fog_zoom
    attr_accessor :fog_sx
    attr_accessor :fog_sy
    attr_accessor :battleback_name
    attr_accessor :passages
    attr_accessor :priorities
    attr_accessor :terrain_tags
  end
    
  class CommonEvent
    def initialize
      @id = 0
      @name = ''
      @trigger = 0
      @switch_id = 1
      @list = [RPG::EventCommand.new]
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :trigger
    attr_accessor :switch_id
    attr_accessor :list
  end
  
  class System
    def initialize
      @magic_number = 0
      @party_members = [1]
      @elements = [nil, '']
      @switches = [nil, '']
      @variables = [nil, '']
      @windowskin_name = ''
      @title_name = ''
      @gameover_name = ''
      @battle_transition = ''
      @title_bgm = RPG::AudioFile.new
      @battle_bgm = RPG::AudioFile.new
      @battle_end_me = RPG::AudioFile.new
      @gameover_me = RPG::AudioFile.new
      @cursor_se = RPG::AudioFile.new('', 80)
      @decision_se = RPG::AudioFile.new('', 80)
      @cancel_se = RPG::AudioFile.new('', 80)
      @buzzer_se = RPG::AudioFile.new('', 80)
      @equip_se = RPG::AudioFile.new('', 80)
      @shop_se = RPG::AudioFile.new('', 80)
      @save_se = RPG::AudioFile.new('', 80)
      @load_se = RPG::AudioFile.new('', 80)
      @battle_start_se = RPG::AudioFile.new('', 80)
      @escape_se = RPG::AudioFile.new('', 80)
      @actor_collapse_se = RPG::AudioFile.new('', 80)
      @enemy_collapse_se = RPG::AudioFile.new('', 80)
      @words = RPG::System::Words.new
      @test_battlers = []
      @test_troop_id = 1
      @start_map_id = 1
      @start_x = 0
      @start_y = 0
      @battleback_name = ''
      @battler_name = ''
      @battler_hue = 0
      @edit_map_id = 1
    end
    attr_accessor :magic_number
    attr_accessor :party_members
    attr_accessor :elements
    attr_accessor :switches
    attr_accessor :variables
    attr_accessor :windowskin_name
    attr_accessor :title_name
    attr_accessor :gameover_name
    attr_accessor :battle_transition
    attr_accessor :title_bgm
    attr_accessor :battle_bgm
    attr_accessor :battle_end_me
    attr_accessor :gameover_me
    attr_accessor :cursor_se
    attr_accessor :decision_se
    attr_accessor :cancel_se
    attr_accessor :buzzer_se
    attr_accessor :equip_se
    attr_accessor :shop_se
    attr_accessor :save_se
    attr_accessor :load_se
    attr_accessor :battle_start_se
    attr_accessor :escape_se
    attr_accessor :actor_collapse_se
    attr_accessor :enemy_collapse_se
    attr_accessor :words
    attr_accessor :test_battlers
    attr_accessor :test_troop_id
    attr_accessor :start_map_id
    attr_accessor :start_x
    attr_accessor :start_y
    attr_accessor :battleback_name
    attr_accessor :battler_name
    attr_accessor :battler_hue
    attr_accessor :edit_map_id
  end
    
  class System
    class Words
      def initialize
        @gold = ''
        @hp = ''
        @sp = ''
        @str = ''
        @dex = ''
        @agi = ''
        @int = ''
        @atk = ''
        @pdef = ''
        @mdef = ''
        @weapon = ''
        @armor1 = ''
        @armor2 = ''
        @armor3 = ''
        @armor4 = ''
        @attack = ''
        @skill = ''
        @guard = ''
        @item = ''
        @equip = ''
      end
      attr_accessor :gold
      attr_accessor :hp
      attr_accessor :sp
      attr_accessor :str
      attr_accessor :dex
      attr_accessor :agi
      attr_accessor :int
      attr_accessor :atk
      attr_accessor :pdef
      attr_accessor :mdef
      attr_accessor :weapon
      attr_accessor :armor1
      attr_accessor :armor2
      attr_accessor :armor3
      attr_accessor :armor4
      attr_accessor :attack
      attr_accessor :skill
      attr_accessor :guard
      attr_accessor :item
      attr_accessor :equip
    end
  end
    
  class System
    class TestBattler
      def initialize
        @actor_id = 1
        @level = 1
        @weapon_id = 0
        @armor1_id = 0
        @armor2_id = 0
        @armor3_id = 0
        @armor4_id = 0
      end
      attr_accessor :actor_id
      attr_accessor :level
      attr_accessor :weapon_id
      attr_accessor :armor1_id
      attr_accessor :armor2_id
      attr_accessor :armor3_id
      attr_accessor :armor4_id
    end
  end
    
  class AudioFile
    def initialize(name = '', volume = 100, pitch = 100)
      @name = name
      @volume = volume
      @pitch = pitch
    end
    attr_accessor :name
    attr_accessor :volume
    attr_accessor :pitch
  end
end
  
module RPG
  module Cache
    @cache = {}
    def self.load_bitmap(folder_name, filename, hue = 0)
      path = folder_name + filename
      if not @cache.include?(path) or @cache[path].disposed?
          if filename != ''
            @cache[path] = Bitmap.new(path)
          else
            @cache[path] = Bitmap.new(32, 32)
          end
        end
        if hue == 0
          @cache[path]
        else
          key = [path, hue]
          if not @cache.include?(key) or @cache[key].disposed?
            @cache[key] = @cache[path].clone
          @cache[key].hue_change(hue)
          end
          @cache[key]
         end
      end
      def self.animation(filename, hue)
        self.load_bitmap('Graphics/Animations/', filename, hue)
      end
      def self.autotile(filename)
        self.load_bitmap('Graphics/Autotiles/', filename)
      end
      def self.battleback(filename)
        self.load_bitmap('Graphics/Battlebacks/', filename)
      end
      def self.battler(filename, hue)
        self.load_bitmap('Graphics/Battlers/', filename, hue)
      end
      def self.character(filename, hue)
        self.load_bitmap('Graphics/Characters/', filename, hue)
      end
      def self.fog(filename, hue)
        self.load_bitmap('Graphics/Fogs/', filename, hue)
      end
      def self.gameover(filename)
        self.load_bitmap('Graphics/Gameovers/', filename)
      end
      def self.icon(filename)
        self.load_bitmap('Graphics/Icons/', filename)
      end
      def self.panorama(filename, hue)
        self.load_bitmap('Graphics/Panoramas/', filename, hue)
      end
      def self.picture(filename)
        self.load_bitmap('Graphics/Pictures/', filename)
      end
      def self.tileset(filename)
        self.load_bitmap('Graphics/Tilesets/', filename)
      end
      def self.title(filename)
        self.load_bitmap('Graphics/Titles/', filename)
      end
      def self.windowskin(filename)
        self.load_bitmap('Graphics/Windowskins/', filename)
      end
      def self.tile(filename, tile_id, hue)
        key = [filename, tile_id, hue]
        if not @cache.include?(key) or @cache[key].disposed?
          @cache[key] = Bitmap.new(32, 32)
          x = (tile_id - 384) % 8 * 32
          y = (tile_id - 384) / 8 * 32
          rect = Rect.new(x, y, 32, 32)
          @cache[key].blt(0, 0, self.tileset(filename), rect)
          @cache[key].hue_change(hue)
        end
        @cache[key]
      end
      def self.clear
        @cache = {}
        GC.start
      end
    end
  
end
 
module RPG
  class Weather
    def initialize(viewport = nil)
      @type = 0
      @max = 0
      @ox = 0
      @oy = 0
      color1 = Color.new(255, 255, 255, 255)
      color2 = Color.new(255, 255, 255, 128)
      @rain_bitmap = Bitmap.new(7, 56)
      for i in 0..6
        @rain_bitmap.fill_rect(6-i, i*8, 1, 8, color1)
      end
      @storm_bitmap = Bitmap.new(34, 64)
      for i in 0..31
        @storm_bitmap.fill_rect(33-i, i*2, 1, 2, color2)
        @storm_bitmap.fill_rect(32-i, i*2, 1, 2, color1)
        @storm_bitmap.fill_rect(31-i, i*2, 1, 2, color2)
      end
      @snow_bitmap = Bitmap.new(6, 6)
      @snow_bitmap.fill_rect(0, 1, 6, 4, color2)
      @snow_bitmap.fill_rect(1, 0, 4, 6, color2)
      @snow_bitmap.fill_rect(1, 2, 4, 2, color1)
      @snow_bitmap.fill_rect(2, 1, 2, 4, color1)
      @sprites = []
      for i in 1..40
        sprite = Sprite.new(viewport)
        sprite.z = 1000
        sprite.visible = false
        sprite.opacity = 0
        @sprites.push(sprite)
      end
    end
    def dispose
      for sprite in @sprites
        sprite.dispose
      end
      @rain_bitmap.dispose
      @storm_bitmap.dispose
      @snow_bitmap.dispose
    end
    def type=(type)
      return if @type == type
      @type = type
      case @type
      when 1
        bitmap = @rain_bitmap
      when 2
        bitmap = @storm_bitmap
      when 3
        bitmap = @snow_bitmap
      else
        bitmap = nil
      end
      for i in 1..40
        sprite = @sprites[i]
        if sprite != nil
          sprite.visible = (i <= @max)
          sprite.bitmap = bitmap
        end
      end
    end
    def ox=(ox)
      return if @ox == ox
      @ox = ox
      for sprite in @sprites
        sprite.ox = @ox
      end
    end
    def oy=(oy)
      return if @oy == oy
      @oy = oy
      for sprite in @sprites
        sprite.oy = @oy
      end
    end
    def max=(max)
      return if @max == max
      @max = [[max, 0].max, 40].min
      for i in 1..40
        sprite = @sprites[i]
        if sprite != nil
          sprite.visible = (i <= @max)
        end
      end
    end
    def update
      return if @type == 0
      for i in 1..@max
        sprite = @sprites[i]
        if sprite == nil
          break
        end
        if @type == 1
          sprite.x -= 2
          sprite.y += 16
          sprite.opacity -= 8
        end
        if @type == 2
          sprite.x -= 8
          sprite.y += 16
          sprite.opacity -= 12
        end
        if @type == 3
          sprite.x -= 2
          sprite.y += 8
          sprite.opacity -= 8
        end
        x = sprite.x - @ox
        y = sprite.y - @oy
        if sprite.opacity < 64 or x < -50 or x > 750 or y < -300 or y > 500
          sprite.x = rand(800) - 50 + @ox
          sprite.y = rand(800) - 200 + @oy
          sprite.opacity = 255
        end
      end
    end
    attr_reader :type
    attr_reader :max
    attr_reader :ox
    attr_reader :oy
  end
end

class Table
  attr_reader :xsize, :ysize, :zsize
  def initialize(xsize, ysize=1, zsize=1)
    @xsize = xsize
    @ysize = ysize
    @zsize = zsize
    @data  = Array.new(@xsize*@ysize*@zsize, 0)
  end
  def resize(xsize, ysize=1, zsize=1)

  end

  def [](x, y=0, z=0)
    return nil if x >= @xsize or y >= @ysize
    @data[x + y * @xsize + z * @xsize * @ysize]
  end

  def []=(x, y=0, z=0, v) #:nodoc:
    @data[x + y * @xsize + z * @xsize * @ysize]=v
  end

  def self._load(s) #:nodoc:
    Table.new(1).instance_eval {
      @size, @xsize, @ysize, @zsize, xx, *@data = s.unpack('LLLLLS*')
      self
    }
  end

  def _dump(d = 0) #:nodoc:
    [@size, @xsize, @ysize, @zsize, @xsize*@ysize*@zsize, *@data].pack('LLLLLS*')
  end
end

def load_data(filename)
  File.open(filename, "rb") { |f|
    obj = Marshal.load(f)
  }
end