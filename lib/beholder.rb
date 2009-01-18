require 'rubygems'
gem :fsevents
require 'fsevents'

class Proc
  alias :cast! :call
end

class Beholder

  attr_reader :paths_to_watch, :sent_an_int, :mappings, :working_directory, :be_verbose
  attr_reader :the_eye, :treasure_maps, :possible_map_locations, :all_examples
  
  def initialize
    @paths_to_watch, @all_examples = [], []
    @mappings, @treasure_maps = {}, {}
    @sent_an_int = false
    @working_directory = Dir.pwd
    @be_verbose = ARGV.include?("-v") || ARGV.include?("--verbose")
    @possible_map_locations = ["#{@working_directory}/.treasure_map.rb", "#{@working_directory}/treasure_map.rb", "#{@working_directory}/config/treasure_map.rb"]
  end

  def self.cast_thy_gaze
    beholder = new
    beholder.read_all_maps
    beholder.set_all_examples if beholder.all_examples.empty?
    beholder.prepare_for_interlopers    
    beholder.open_your_eye
  end

  def read_all_maps
    read_default_map

    possible_map_locations.each do |map_location|
      if File.exist?(map_location)
        say "Found a treasure map at #{map_location}"
        instance_eval(File.readlines(map_location).join("\n"))
        return
      end
    end
  end

  def prepare_for_interlopers
    trap 'INT' do
      if @sent_an_int then      
        puts "   A second INT?  Ok, I get the message.  Shutting down now."
        close_your_eye
      else
        puts "   Did you just send me an INT? Ugh.  I'll quit for real if you do it again."
        @sent_an_int = true
        Kernel.sleep 1.5
        reclaim_stolen_treasure_at all_examples
      end
    end
  end    

  def open_your_eye
    say("Watching the following locations:\n  #{paths_to_watch.join(", ")}")
    @the_eye = FSEvents::Stream.watch(paths_to_watch) do |treasure_chest|
      notice_thief_taking(treasure_chest.modified_files)
      puts "\n\nWaiting to hear from the disk since #{Time.now}"
    end
    @the_eye.run
  end    
  
  def read_default_map
    map_for(:default_dungeon) do |wizard|

      wizard.keep_a_watchful_eye_for 'lib', 'examples'

      wizard.prepare_spell_for %r%examples/(.*)_example\.rb% do |spell_component|
        ["examples/#{spell_component[1]}_example.rb"]
      end

      wizard.prepare_spell_for %r%examples/example_helper\.rb% do |spell_component|
        Dir["examples/**/*_example.rb"]
      end

      wizard.prepare_spell_for %r%lib/(.*)\.rb% do |spell_component|
        ["examples/lib/#{spell_component[1]}_example.rb"]
      end

    end
  end

  def map_for(map_name)
    @treasure_maps[map_name] ||= []
    @current_map = @treasure_maps[map_name]
    yield self if block_given?
  ensure
    @current_map = nil
  end

  def prepare_spell_for(arcane_enemy, &spell)
    @current_map << [arcane_enemy, spell]
  end
  alias :add_mapping :prepare_spell_for

  def cast_feeble_mind
    @treasure_maps = {}
  end
  
  def set_all_examples
    if paths_to_watch.include?('examples')
      @all_examples += Dir['examples/**/*_example.rb']
    end
    
    if paths_to_watch.include?('test')
      @all_examples += Dir['test/**/*_test.rb']
    end
    
    if paths_to_watch.include?('spec')
      @all_examples += Dir['spec/**/*_spec.rb']
    end
  end

  def keep_a_watchful_eye_for(*paths)
    @paths_to_watch.concat(paths)
  end

  def blink
    @sent_an_int = false
  end

  def close_your_eye
    the_eye.shutdown
    exit
  end

  def identify_stolen_treasure(treasure)
    treasure_maps.each do |name, treasure_locations|
      treasure_locations.each do |stolen_by_enemy, spell| 
        if spell_components = treasure.match(stolen_by_enemy)
          say "Found the stolen treasure using the #{name} map "
          return spell.cast!(spell_components)
        end
      end
    end

    puts "Unknown file: #{treasure}"
    return []
  end

  def reclaim_stolen_treasure_at(coordinates)
    coordinates.flatten!

    coordinates.reject! do |coordinate|
      found_treasure = File.exist?(coordinate)
      puts "#{coordinate} does not exist." unless found_treasure
    end

    return if coordinates.empty?

    puts "\nRunning #{coordinates.join(', ').inspect}" 
    system "ruby #{coordinates.join(' ')}"
    blink
  end

  def notice_thief_taking(treasure)
    say "#{treasure} changed" unless treasure.empty?
    coordinates = treasure.map { |t| identify_stolen_treasure(t) }.uniq.compact
    reclaim_stolen_treasure_at coordinates
  end

  private
  def say(this_message_please)
    puts this_message_please if be_verbose
  end

end