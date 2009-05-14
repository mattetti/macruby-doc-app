module DocSet
    
  DOCUTIL_PATH = '/Developer/usr/bin/docsetutil'
  DOCSET_PATH  = '/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset'
  
  Ref = Struct.new(:language, :type, :klass, :thing, :path, :full_path) 
  
  # Returns the doc reference
  def self.search(query_string)
    query_string = query_string
    raw_results = `#{DOCUTIL_PATH} search -skip-text -query #{query_string} #{DOCSET_PATH}`
    NSLog(raw_results)
    
    if raw_results.length > 0
      ref_str, doc_path = raw_results.split("\n")
      convert_references(ref_str)
    else
      ''
    end
  end
    
  # Split the query result into its component types and document path.
  # language is 'Objective-C', 'C', 'C++'
  # type is 'instm' (nstance method), 'clsm' (class method, 'func' , 'econst', 'tag', 'tdef' and so on.
  # klass holds the class or '-' if no class is appropriate (for a C function, for example).
  # thing is the method, function, constant, etc.
  def self.convert_references (ref_str)
          return nil unless ref_str
          ref = ref_str.split
          raise "Cannot parse reference: #{query_string}" if ref.length != 2
          language, type, klass, thing = ref[0].split('/')
          Ref.new(language, type, klass, thing, ref[1], "#{DOCSET_PATH}/Contents/Resources/Documents/#{ref[1]}")
  end  
  
end