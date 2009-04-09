# Tunnel

class Tunnel < Processing::App

  module Lookup
    def self.generate
      @sin_table = []
      @cos_table = []

      @precision = 0.2
      @inverse = 1.0 / @precision
      @table_length = (360.0 * @inverse).to_i

      @direction_x = 5
      @direction_y = 0

      (0..@table_length).each do |i|
        @sin_table[i] = Math.sin i * (Math::PI / 180) * @precision
        @cos_table[i] = Math.cos i * (Math::PI / 180) * @precision
      end
    end

    def self.change_direction
      @direction_x += 0.5 - rand if rand > 0.98
      @direction_y += 0.5 - rand if rand > 0.98
    end

    def self.sin_table
      @sin_table
    end

    def self.cos_table
      @cos_table
    end

    def self.table_length
      @table_length
    end

    def self.inverse
      @inverse
    end

    def self.direction_x ; @direction_x ; end
    def self.direction_y ; @direction_y ; end
  end

  class Ring
    attr_reader :diameter, :offset

    def initialize(x, y, diameter, offset, width, height)
      @x, @y, @diameter, @offset = x, y, diameter, offset
      @step = 10
      @width = width
      @height = height
      # Set these to 1 + rand(3) for a nice effect in no delete mode
      @grow_speed = 2.0
      @spin_speed = 2.5
      @base_colour = color(80, 30, 30)

      @direction_x = Lookup.direction_x
      @direction_y = Lookup.direction_y
    end

    def update(base_colour = nil)
      @base_colour = base_colour if base_colour

      # Needs to get faster as it gets wider
      @diameter += @grow_speed + (@diameter * Lookup.sin_table[(@diameter % Lookup.table_length) / 8])
      @offset += @spin_speed
      
      # These can wrap, but this isn't used in tunnel mode
      @diameter = 0 if @diameter >= Lookup.table_length
      @offset = 0 if @offset >= Lookup.table_length

      @x = @x + (Lookup.cos_table[@offset] * @direction_x)
      @y = @y + (Lookup.sin_table[@offset] * @direction_y)
    end

    def draw
      radius = 16 + @height * Lookup.sin_table[@diameter]

      (0..360/@step).each do |i|
        i *= @step
        theta = (i * Lookup.inverse + @offset) % Lookup.table_length

        x = @x + (Lookup.cos_table[theta] * radius)
        y = @y + (Lookup.sin_table[theta] * radius)
         
        plot x, y
      end
    end

    def plot(x, y)
      set x, y, @base_colour
    end
  end

  def setup
    color_mode RGB, 255
    background 0
    
    Lookup.generate

    @ring_size_limit = 256
    @palette = make_palette
    @rings = []

    add_ring 1, 1

    frame_rate 30
  end
  
  def draw
    background 0
    @rings.each do |ring|
      # The widest the ring can be needs to be calculated here
      colour_index = (ring.diameter.to_f / 60) * 255
      base_colour = @palette[colour_index]
      ring.update(base_colour)
      ring.draw
    end
  
    @rings.delete_if { |ring| ring.diameter > 400 }

    if @rings.size < @ring_size_limit and @rings.last.diameter > 6
      Lookup.change_direction
      add_ring 0, @rings.last.offset + 2
    end
  end

  def add_ring(diameter, offset)
    @rings << Ring.new(width / 2, height / 2, diameter, offset, width, height)
  end

  def make_palette
    palette = []
    # Create the bands of colour for the palette (256 is the maximum colour)
    limit = 256
    base_colour = 1
    (0..limit).each do |i|
      offset = base_colour + i
      offset = 255 if offset > 255
      palette[i] = [base_colour, base_colour, offset]

      base_colour += Lookup.sin_table[i]
    end
    palette.collect { |p| color(*p) }
  end
end

Tunnel.new :title => "Tunnel", :width => 640, :height => 480
