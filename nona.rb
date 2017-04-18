class KeyboardCommands
  def self.open_document app
    filename = app.ask_open_file
    app.info "Opening #{filename}"
    app.instance_variable_get(:@edit_box).text = File.read filename
    app.instance_variable_set(:@open_file_path, filename)
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
end

Shoes.app title: "nona" do
  keypress do |keycode|
    case keycode
      when :control_o; KeyboardCommands.open_document self
      when :control_s; KeyboardCommands.save_document self
    end
  end

  # Style
  background "#FFF"

  # Layout
  flow do
    command_stack = stack width: 200, height: app.height do
      background "#DEDEDE"

      caption "nona"
      #button "command 0"
      #para "command 1"
      #para "command 2"
    end
    @edit_stack = stack width: -200 do
      background "#FFF"
      @edit_box = edit_box width: 1.0, height: app.height
    end
  end
end
