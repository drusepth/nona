DOCUMENT_UNDO_DEPTH = 100 # How many document states to store for undoing through

class KeyboardCommands
  def self.open_document app
    filename = app.ask_open_file
    app.info "Opening #{filename}"
    app.instance_variable_get(:@edit_box).text = File.read filename
    app.instance_variable_set(:@open_file_path, filename)

    app.instance_variable_get(:@command_stack).prepend { app.inscription "Opened file" }
  end

  def self.save_document app
    open_file_path = app.instance_variable_get(:@open_file_path) # || ask_open_file
    if open_file_path
      app.info "Writing to #{open_file_path}"
      document_text = app.instance_variable_get(:@edit_box).text
      File.open(open_file_path, 'w') { |fh| fh.write document_text }
    else
      app.info "Couldn't get path to write to"
    end
  end
  
  def self.undo_last_action app
    state_history = app.instance_variable_get(:@state_history).dup
    state_history.shift if state_history.count > 1

    app.instance_variable_get(:@edit_box).text = state_history.first
    app.instance_variable_set(:@state_history, state_history)
  end
  
  def self.exit_gracefully app
    exit
  end
end

Shoes.app title: "nona" do
  keypress do |keycode|
    puts "#{keycode.inspect} was pressed"
    case keycode
      when :control_o; KeyboardCommands.open_document    self
      when :control_s; KeyboardCommands.save_document    self
      when :control_z; KeyboardCommands.undo_last_action self
      when :control_q; KeyboardCommands.exit_gracefully  self
    end
  end

  # Style
  background "#FFF"

  # Onload
  @state_history = []

  # Layout
  flow do
    @command_stack = stack width: 200, height: app.height do
      background "#DEDEDE"

      #tagline "nona"
      @character_counter = strong("0")
      para @character_counter, " chars"
      #inscription "help"
      #list_box items: ["foo", "bar", "baz"]
      #button "command 0"
      #para "command 1"
      #para "command 2"
    end
    @edit_stack = stack width: -200 do
      background "#FFF"
      @edit_box = edit_box width: 1.0, height: app.height do |edit_box|
        @state_history = @state_history.unshift(edit_box.text).take(1 + DOCUMENT_UNDO_DEPTH)
        @character_counter.text = edit_box.text.size
      end
    end
  end
end
