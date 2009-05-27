class ResultStore < HotCocoa::TableDataSource
  
  attr_accessor :data
  
  def add_results(sender, results)
    # reseting the table view data
    @data = []
    results.each do |result|
      @data << result
    end
    sender.reloadData
  end
  
  def tableView(view, setObjectValue:object, forTableColumn:column, row:index)
    result = @data[index]
    case column.identifier
      when 'language'
        result.language = object
      when 'type'
        result.type     = object
      when 'klass'
        result.klass    = object
    end
  end
  
end