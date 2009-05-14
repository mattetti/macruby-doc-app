require 'hotcocoa'
require "#{File.dirname(__FILE__)}/docset.rb"
framework 'webkit'
framework 'QuartzCore'
framework 'ApplicationServices'


class Application
  include HotCocoa
  include DocSet
  LOCAL_DOC_INDEX = '/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/index.html'
  
  def start
    application :name => "Cocoa Doc" do |app|
      app.delegate = self
      @main_window = window :frame => [100, 100, 825, 500], :title => "CocoaDoc" do |win|
        win << label(:text => "Cocoa Documentation", :layout => {:start => false})
        win << doc_view
        win << search_bar
        search_box.delegate = app
        
        set_responders(win)
        win.will_close { exit }
      end
    end
  end
    
  def search_bar
    @search_bar ||= layout_view(:mode => :horizontal, :frame => [0, 0, 0, 40], :layout => {:expand => :width, :bottom_padding => 2}, :margin => 0, :spacing => 0) do |hview|
      hview << search_button
      hview << search_box
    end
  end
  
  def doc_view
    @web_view ||= web_view( :url    => LOCAL_DOC_INDEX,
                            :layout => {:expand =>  [:width, :height]} )
  end
  
  def search_button
    @search_button ||= button(:title => "Search", :layout => {:align => :center}).on_action do
      NSLog("searching for #{@search_box.to_s}")
      ref = DocSet.search(@search_box.to_s)
      if ref.respond_to?(:full_path)
        @web_view.url = ref.full_path
        search_box.text = ''
      else
        alert :message => "No documentation found", :info => "Sorry, we couldn't find anything about #{@search_box.to_s}, please use another term and try again."
        search_box.text = ''
      end
    end
  end
  
  def search_box
    @search_box ||= text_field(:layout => {:expand => :width, :align => :center})
    def @search_box.doCommandBySelector(selector); NSLog('selector: ' + selector.inspect); end
    # def @search_box.controlTextDidEndEditing(notification); NSLog( 'notification: ' + notification.inspect); end
    @search_box
  end
  
  # Makes the search box the default item on focus
  # and creates a focus/responder loop between the search box and the search button
  def set_responders(win)
    def win.acceptsFirstResponder; true; end
    win.makeFirstResponder(search_box)
    search_box.nextKeyView    = search_button
    search_button.nextKeyView = search_box
  end
  
  def control(textView, doCommandBySelector: commandSelector)
      result = false
      NSLog commandSelector.inspect
      true
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

Application.new.start