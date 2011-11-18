require 'RMagick'
include Magick

module Magick
  class Image
    def left_edge_histogram
      return @left_edge_histogram if @left_edge_histogram
      left_edge_pixels = self.get_pixels(0, 0, 1, self.rows)
      @left_edge_histogram = LuminosityHistogram.from_pixels left_edge_pixels
    end
    
    def right_edge_histogram
      return @right_edge_histogram if @right_edge_histogram
      right_edge_pixels = self.get_pixels(self.columns - 1, 0, 1, self.rows)
      @right_edge_histogram = LuminosityHistogram.from_pixels right_edge_pixels
    end
  end
end

class LuminosityHistogram < Array
  def self.from_pixels(pixels)
    lh = []
    pixels.each do |pixel|
      h, s, l, a = pixel.to_hsla
      lh << Math.sqrt(s) + (l / 10)
    end
    lh
  end

  def self.distance(lh_a, lh_b)
    dist = 0.0
    (0...lh_a.size).each do |i|
      dist += (lh_a[i] - lh_b[i]).abs
    end
    return dist
  end
end

class ImageUnshredder
  attr_reader :image, :slices, :sorted_slices, :slice_width

  def initialize(image_in_path, image_out_path = nil)
    @image = Image.read(image_in_path).first
    @slices = []
    @slice_width = 32
    self.unshred(image_out_path)
  end

  def unshred(to_file)
    self.slice_image
    self.sort_slices!
    self.write_result(to_file) if to_file
  end

  def slice_image
    slice_count = @image.columns / @slice_width
    (0...slice_count).each do |index|
      x_offset = index * @slice_width
      @slices << @image.excerpt(x_offset, 0, @slice_width, @image.rows)
    end
  end

  def sort_slices!
    @sorted_slices = [@slices.shift]
    while !@slices.empty?
      first = @sorted_slices.first
      last = @sorted_slices.last

      lowest = 1.0/0
      lowest_slice = nil
      lowest_direction = nil

      @slices.each do |slice|
        d = LuminosityHistogram.distance(slice.right_edge_histogram, first.left_edge_histogram)
        if d < lowest
          lowest = d
          lowest_slice = slice
          lowest_direction = :left
        end
        d = LuminosityHistogram.distance(last.right_edge_histogram, slice.left_edge_histogram)
        if d < lowest
          lowest = d
          lowest_slice = slice
          lowest_direction = :right
        end
      end

      case lowest_direction
        when :left
          @sorted_slices.unshift(lowest_slice)
        when :right
          @sorted_slices.push(lowest_slice)
      end
      @slices.delete(lowest_slice)
    end
  end
  
  def write_result(to_file)
    out_image = Image.new(@image.columns, @image.rows)
    (0...@sorted_slices.count).each do |i|
      slice_pixels = @sorted_slices[i].get_pixels(0, 0, @slice_width, @image.rows)
      out_image.store_pixels((i * @slice_width), 0, @slice_width, @image.rows, slice_pixels)
    end
    out_image.write(to_file)
  end
end