module DocSet
    
  DOCUTIL_PATH = '/Developer/usr/bin/docsetutil'
  DOCSET_PATH  = '/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset'  
  Ref = Struct.new(:language, :type, :klass, :thing, :path, :full_path) 
  class DocSetError < StandardError; end
  
  # Returns an array of doc reference
  def self.search(query_string)
    verify_user_system
    query_string = query_string
    raw_results = `#{DOCUTIL_PATH} search -skip-text -query #{query_string} #{DOCSET_PATH}`
    
    if raw_results.length > 0
      results = raw_results.split("\n")
      results.map do |ref|
        convert_references(ref)
      end.flatten
    else
      []
    end
  end
    
  # Split the query result into its component types and document path.
  # language is 'Objective-C', 'C', 'C++'
  # type is 'instm' (instance method), 'clsm' (class method, 'func' , 'econst', 'tag', 'tdef' and so on.
  # klass holds the class or '-' if no class is appropriate (for a C function, for example).
  # thing is the method, function, constant, etc.
  #
  # === Returns
  # <Array>:: Array of references
  def self.convert_references (ref_str)
    return nil unless ref_str
    reference, path = ref_str.split("   ")
    raise DocSetError, "Cannot parse reference string: #{ref_str}" if reference.nil? || path.nil?
    language, type, klass, thing = reference.split('/')
    Ref.new(language, type, klass, thing, path, "#{DOCSET_PATH}/Contents/Resources/Documents/#{path}")
  end
  
  protected
  def self.verify_user_system
    @@tool_requirements ||= File.exist?(DOCUTIL_PATH) && File.exist?(DOCSET_PATH)
    raise DocSetError, "The cocoa documentation wasn't found on your machine, make sure to install the MacOSX developer tools that came with your mac" unless @@tool_requirements
  end
  
end