require 'hotcocoa'
require "#{File.dirname(__FILE__)}/docset.rb"
require "#{File.dirname(__FILE__)}/hotcocoa_doc.rb"
require "#{File.dirname(__FILE__)}/result_store.rb"

framework 'webkit'


class Application
  include HotCocoa
  include DocSet
  LOCAL_DOC_INDEX = '/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/index.html'
  
  def start
    application :name => "Cocoa Doc" do |app|
      app.delegate = self
      @main_window = window :frame => [100, 100, 825, 500], :title => "CocoaDoc" do |win|
        win << label(:text => "Cocoa & HotCocoa Documentation", :layout => {:start => false})
        win << doc_view
        win << result_table
        win << search_bar
        search_box.delegate = app
        set_responders(win)        
        win.will_close { exit }
      end
    end
  end
    
    
  # layout view including the hotcocoa mappings button
  # as well as the cocoa search field and button
  def search_bar
    @search_bar ||= layout_view(:mode => :horizontal, :frame => [0, 0, 0, 40], :layout => {:expand => :width, :bottom_padding => 2}, :margin => 0, :spacing => 0) do |hview|
      hview << hotcocoa_button
      hview << search_button
      hview << search_box
    end
  end
  
  
  # a webview displaying the result of the search
  # the webview sets a delegation to deal with various actions
  def doc_view
    @web_view ||= web_view( :url    => LOCAL_DOC_INDEX,
                            :layout => {:expand =>  [:width, :height]} ) do |wv| 
      wv.setPolicyDelegate(PolicyDelegate.new(self))
    end
  end
  
  def search_button
    @search_button ||= button(:title => "Search", :layout => {:align => :center}).on_action(&method(:perform_search))
  end

  def hotcocoa_button
    @hotcoca_button ||= button(:title => "HotCocoa Mappings", :layout => {:align => :center}).on_action(&method(:display_hotcocoa_index))
  end
  
  def search_box
    @search_box ||= text_field(:layout => {:expand => :width, :align => :center}).on_action(&method(:perform_search))
  end
  
  def display_hotcocoa_index(sender)
    doc_view.mainFrame.loadHTMLString(HotCocoaDoc.render_index, baseURL:nil)
  end
  
  def result_store
    @result_store ||= ResultStore.new([])
  end
  
  def result_table
    @result_table ||= layout_view :frame => [0, 0, 0, 0], :layout => {:expand => [:width, :height]}, :margin => 0, :spacing => 0 do |view|
                        view << scroll_view(:layout => {:expand => [:width, :height]}) do |scroll|
                          @result_table_view = table_view( 
                            :columns => [
                              column(:id => :language,    :title => "Language"), 
                              column(:id => :type,        :title => "Type"),
                              column(:id => :klass,       :title => "Class")
                              ]
                          )
                          @result_table_view.data = result_store
                          @result_table_view.tableColumns.each{|column| column.editable = false}
                          @result_table_view.delegate = self
                          scroll << @result_table_view
                        end
                      end
  end
  
  # performing a search using the DocSet class
  # to work properly, the user needs to have the macosx developer tools installed.
  def perform_search(sender)
    NSLog("searching for #{@search_box.to_s}")
    begin
      refs = DocSet.search(@search_box.to_s)
    rescue DocSetError => error_message
      alert(:message => "Missing documentation", :info => error_message.to_s) 
    else
      # loading the table view
      result_store.add_results(@result_table_view, refs)
      if refs.first.respond_to?(:full_path)
        @web_view.url = refs.first.full_path
        search_box.text = ''
      else
        alert :message => "No documentation found", :info => "Sorry, we couldn't find anything about #{@search_box.to_s}, please use another term and try again."
        search_box.text = ''
      end
    end
  end
  
  # Makes the search box the default item on focus
  # and creates a focus/responder loop between the search box and the search button
  def set_responders(win)
    def win.acceptsFirstResponder; true; end
    win.makeFirstResponder(search_box)
    search_box.nextKeyView    = search_button
    search_button.nextKeyView = search_box
  end


  # called when the user selects a new row
  def tableViewSelectionDidChange(notification)
    @web_view.url = result_store.data[@result_table_view.selectedRow].full_path
  end
  
  # file/open
  def on_open(menu)
  end
  
  # file/new 
  def on_new(menu)
  end
  
  # help menu item
  def on_help(menu)
  end
  
  # This is commented out, so the minimize menu item is disabled
  #def on_minimize(menu)
  #end
  
  # window/zoom
  def on_zoom(menu)
  end
  
  # window/bring_all_to_front
  def on_bring_all_to_front(menu)
  end
end

class PolicyDelegate
  
  attr_reader :app
  
  def initialize(app)
    @app = app
  end
  
  def webView(view, decidePolicyForNavigationAction:action, request:request, frame:frame, decisionListener:listener)
    action_url = action.objectForKey(WebActionOriginalURLKey).absoluteString
    case action.objectForKey(WebActionNavigationTypeKey)
    when WebNavigationTypeLinkClicked
      if action_url =~ /hotcocoa:(.*)/
        if $1 == '_index'
          view.mainFrame.loadHTMLString(HotCocoaDoc.render_index, baseURL:nil)
        else
          view.mainFrame.loadHTMLString(HotCocoaDoc.new($1.intern).render, baseURL:nil)
        end
        listener.ignore
      elsif action_url =~ /search:(.*)/
        app.search_box.text = $1
        app.perform_search(nil)
        listener.ignore
      elsif action_url =~ /open:(.*)/
        `open #{$1}`
        listener.ignore
      else
        listener.use
      end
    when WebNavigationTypeOther
      listener.use
    else
      listener.use
    end
  end
end

Application.new.start