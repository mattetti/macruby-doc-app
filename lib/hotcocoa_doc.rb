class HotCocoaDoc
  def self.mapping_index
    index = []
    HotCocoa::Mappings.mappings.keys.sort.each do |key|
      index << %{<li><a href="hotcocoa:#{key}">#{key}</a></li>}
    end
    %{
      <html>
      <body>
      <h1>HotCocoa Mappings</h1>
      <ul>
      #{index.join("\n")}
      </ul>
      </html>
    }
  end
  
  def self.mapping_documentation_for(mapping_id)
    mapping = HotCocoa::Mappings.mappings[mapping_id]
    control_module = mapping.control_module
    if control_module.defaults
      defaults = %{
        <h2>Default options:</h2>
        <ul>
        #{
          control_module.defaults.keys.map {|key| "<li>#{key}:  #{control_module.defaults[key].inspect}</li>" }.join('')
        }
        </ul>
      }
    else
      defaults = ''
    end
    constants = ""
    if control_module.custom_methods
      custom_methods = %{
        <h2>Custom methods</h2>
        <div>#{(control_module.custom_methods.instance_methods - Object.methods).sort.join(", ")}</div>
      }
    else
      custom_methods = ''
    end
    
    
    %{
      <html>
      <body>
      <a href="hotcocoa:_index">Back to list...</a>
      <h1>Documentation for the '#{mapping_id}' method</h1>
      <div class="class_info">Class returned: <a href="search:#{mapping.control_class}">#{mapping.control_class}</a></div>
      #{defaults}
      #{constants}
      #{custom_methods}
      </html>
    }
  end
end