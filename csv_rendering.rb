require 'fastercsv'

module CsvRendering
  
  protected
    
    def render_data_table_as_csv(data_table, objects, csv_name = "report.csv")
      csv_display_proc = Proc.new do |field_name, column_opts, controller, object, standard_render|
        if (field_def = column_opts[:field_def]) && !column_opts[:display_proc]
          field_def.csv_display_proc.call(field_def.reader_proc.call(object))
        else
          standard_render.call(controller, object)
        end
      end
      
      records = data_table.make_response_hash(objects, {}, csv_display_proc)[:records]
      
      stream_csv(csv_name) do |csv|        
        top_line = []
        data_keys = []
        
        data_table.column_defs.each do |coldef|
          if coldef[:children]
            coldef[:children].each do |child_coldef|
              data_keys << child_coldef[:key]
              top_line << child_coldef[:label]
            end
          else
            data_keys << coldef[:key]
            top_line << coldef[:label]
          end
        end
        csv << top_line
        
        records.each do |record|
          line = []
          data_keys.each do |key|
            line << record[key.to_sym]
          end
          csv << line
        end
      end      
    end
    
    def stream_csv(filename)
      #this is required if you want this to work with IE
      if request.env['HTTP_USER_AGENT'] =~ /msie/i
        headers['Pragma'] = 'public'
        headers["Content-type"] = "text/plain"
        headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" if ::DOWNLOAD_REPORT_CSV_AS_FILE
        headers['Expires'] = "0"
      else
        headers["Content-Type"] = 'text/csv' if ::DOWNLOAD_REPORT_CSV_AS_FILE
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" if ::DOWNLOAD_REPORT_CSV_AS_FILE
      end
      
      render :text => Proc.new { |response, output|
        unless output.respond_to?("<<")
          output.instance_eval do
            class << self
              def <<(arg)
                self.write(arg)
              end
            end
          end
        end
        csv = FasterCSV.new(output, :row_sep => "\r\n")
        yield csv
      }
    end
  
  
end