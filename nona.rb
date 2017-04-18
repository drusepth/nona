DOCUMENT_UNDO_DEPTH = 100 # How many document states to store for undoing through

class DocumentHelpers
  def self.cursor_position_after before_text, after_text
    before_characters = before_text.chars
    after_characters  = after_text.chars
    
    before_characters.each_index do |i|
      return 1 + i if i > after_characters.count
      return 1 + i unless before_characters[i] == after_characters[i]
    end
  end

  def self.recalculate_displayed_state_info app
    state_history = app.instance_variable_get(:@state_history).dup

    if state_history.count > 1
      current_state = state_history[0]
      
      cursor_index = DocumentHelpers.cursor_position_after state_history[0], state_history[1]
      all_lines    = current_state.split("\n")
      line_index   = 1 + current_state[0..cursor_index].count("\n")
      current_line = all_lines[line_index - 1]
      current_line_start_index = 1 + (current_state[0..cursor_index].rindex("\n") || 0)
      current_col  = cursor_index - current_line_start_index

      app.instance_variable_set(:@state_information, {
        current_line:      line_index,
        current_column:    current_col,
        current_character: cursor_index
      })

      app.instance_variable_set(:@document_information, {
        total_lines: all_lines.length,
        total_columns: current_line.length,
        total_characters: current_state.length
      })
    end
  end

  def self.update_displayed_state_info app
    state_information    = app.instance_variable_get(:@state_information).dup
    document_information = app.instance_variable_get(:@document_information).dup

    app.instance_variable_get(:@displayed_state_info).text = [
      "line #{state_information[:current_line]}/#{document_information[:total_lines]} ",
      "(#{(state_information[:current_line].to_f / document_information[:total_lines] * 100).round}%)\n",
      "col #{state_information[:current_column]}/#{document_information[:total_columns]} ",
      "(#{(state_information[:current_column].to_f / document_information[:total_columns] * 100).round}%)\n",
      "char #{state_information[:current_character]}/#{document_information[:total_characters]} ",
      "(#{(state_information[:current_character].to_f / document_information[:total_characters] * 100).round}%)\n"
    ].join
  end
end

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
      when :left;  @state_information[:current_character] = [@state_information[:current_character] - 1, 0].max
      when :right; @state_information[:current_character] = [@state_information[:current_character] + 1, @edit_box.text.length].min

      when :control_o; KeyboardCommands.open_document    self
      when :control_s; KeyboardCommands.save_document    self
      when :control_z; KeyboardCommands.undo_last_action self
      when :control_q; KeyboardCommands.exit_gracefully  self
    end

    DocumentHelpers.update_displayed_state_info self
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
      para @character_counter, " bytes"

      @state_information = {
        current_line: 0,
        current_column: 0,
        current_character: 0
      }
      @document_information = {
        total_lines: 0,
        total_columns: 0,
        total_characters: 0
      }
      @displayed_state_info = para

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

        DocumentHelpers.recalculate_displayed_state_info self
        DocumentHelpers.update_displayed_state_info      self
      end
    end
  end
end
