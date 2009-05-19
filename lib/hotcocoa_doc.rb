require 'hotcocoa'
require 'ripper'

class HotCocoaDoc

  def self.render_index
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
  
  attr_reader :mappings, :mapping_id
  
  def initialize(mapping_id)
    @mapping_id = mapping_id
  end
  
  def render
    unless defaults_structure.empty?
      defaults = %{
        <h2>Default options:</h2>
        <ul>
        #{
          defaults_structure.map {|item| "<li>#{item[0]} => #{item[1]}</li>" }.join('')
        }
        </ul>
      }
    else
      defaults = ''
    end
    unless constants_structures.empty?
      constants = constants_structures.map do |constant_structure|
        html = "<div>#{constant_structure[0]} =></div><ul>"
        constant_structure[1].each do |pairs|
          html << "<li>#{pairs[0]} => #{pairs[1]}</li>"
        end
        html << "</ul>"
      end.join("")
      constants = %{
        <h2>Constants:</h2>
        #{constants}
      }
    else
      constants=''
    end
    if custom_methods && !custom_methods.empty?
      custom_methods_html = %{
        <h2>Custom methods</h2>
        <div>#{custom_methods.join(", ")}</div>
      }
    else
      custom_methods = ''
    end
    if delegate_structures.empty?
      delegates = ""
    else
      delegates = "<h2>Delegate Methods</h2><ul>"
      delegate_structures.keys.sort.each do |selector|
        mapping = delegate_structures[selector]
        if mapping[:parameters]
          param_list = "| #{mapping[:parameters].join(", ")} |"
        else
          param_list = ''
        end
        delegates << "<li>#{mapping[:to]} { #{param_list} ... } #{mapping[:required] ? '<span style="color:ff0000">*</span>' : ''}</li>"
      end
      delegates << "</ul>"
    end
    %{
      <html>
      <body>
      <a href="hotcocoa:_index">Back to list...</a>
      <h1>Documentation for the '#{mapping_id}' mapping.</h1>
      <div class="class_info">Class returned: <a href="search:#{control_class}">#{control_class}</a></div>
      <div class="file_info">Mapping file: <a href="open:#{mapping_file}">#{mapping_id}.rb</a></div>
      #{defaults}
      #{constants}
      #{delegates}
      #{custom_methods_html}
      </html>
    }
  end
  
  private
  
    def mapping
      @mapping ||= HotCocoa::Mappings.mappings[mapping_id]
    end
    
    def control_module
      @control_module ||= mapping.control_module
    end
    
    def control_class
      @control_class ||= mapping.control_class
    end
    
    def mapping_file
      $LOADED_FEATURES.detect {|f| f.include?("mappings/#{mapping_id}.rb")}
    end
    
    def custom_methods
      @custom_methods ||= control_module.custom_methods ? (control_module.custom_methods.instance_methods - Object.methods).sort : nil
    end
    
    def sexp
      @sexp ||= Ripper.sexp(File.read(mapping_file))
    end
    
    def defaults_structure
      @defaults_structure ||= parse_defaults_structure
    end
    
    def constants_structures
      @constants_structures ||= parse_constants_structures
    end
    
    def delegate_structures
      @delegates_structures ||= control_module.delegate_map
    end
    
    def build_mapping_structure
      command_list = 
      command_list.each do |item|
      end
    end
    
    def parse_defaults_structure
      defaults_sexp = sexp[1][0][2][2].detect {|element| element[0] == :command && element[1][0] == :@ident && element[1][1] == 'defaults'}
      if defaults_sexp
        extract_pattern(:assoc_new, defaults_sexp).map { |element_sexp| [to_source(element_sexp[1]), to_source(element_sexp[2])] }
      else
        []
      end
    end
    
    def parse_constants_structures
      sexp[1][0][2][2].select { |element| element[0] == :command && element[1][0] == :@ident && element[1][1] == 'constant' }.map {|constant_sexp| parse_constant_structure(constant_sexp)}
    end
    
    def parse_constant_structure(constant_sexp)
      [
        to_source(constant_sexp[2][1][0]),
        extract_pattern(:assoc_new, constant_sexp[2][1][1]).map { |element_sexp| 
          [to_source(element_sexp[1]), to_source(element_sexp[2])] 
        }
      ]
    end
    
    def extract_pattern(key, structure)
      result = []
      structure.each do |item|
        result << item if item.kind_of?(Array) && item[0] == key
      end
      if result.empty?
        structure.each do |item|
          result = extract_pattern(key, item) if item.kind_of?(Array)
          break unless result.empty?
        end
      end
      result
    end
    
    def to_source(element_sexp)
      case element_sexp[0]
      when :string_literal
        if element_sexp[1] == [:string_content]
          '""'
        else
          %{"#{element_sexp[1][1][1]}"}
        end
      when :symbol_literal
        ":#{element_sexp[1][1][1]}"
      when :hash
        if element_sexp[1] == nil
          '{}'
        else
          NSLog "Unhandled hash:"
          NSLog element_sexp.inspect
          '__hash__'
        end
      when :@int
        element_sexp[1]
      when :var_ref
        if element_sexp[1].kind_of?(Array)
          if element_sexp[1][0] == :@const || element_sexp[1][0] == :@kw
            element_sexp[1][1]
          else
            NSLog "Unhandled var:"
            NSLog element_sexp.inspect
            '__var__'
          end
        else
          NSLog "Unhandled var:"
          NSLog element_sexp.inspect
          '__var__'
        end
      when :array
        if element_sexp[1] == nil
          '[]'
        else
          %{[#{element_sexp[1].map{|item_sexp|to_source(item_sexp)}.join(', ')}]}
        end
      else
        NSLog "Unhandled element:"
        NSLog element_sexp.inspect
        "UNKOWN"
      end
    end
  
end
