require 'pdf-reader'
require 'rubygems'
require 'open-uri'
require 'byebug'

class PdfReader
	def pdf_reader_action
    @president = ""
    @secretary = ""
  	f = File.open('pdf_output.xml','w')
  	f.puts "<akomaNtoso>"
  	f.puts "  <debate>"
  	f.puts "    <debatebody>"
  	f.puts "      <debatesection>"
    # io = open("url_here")
    # reader = PDF::Reader.new(io)
		reader = PDF::Reader.new("sample_file.pdf")
		last_ele = ":"
    debate = false
    debate_index = 0
		reader.pages.each_with_index do |page, ind|
			# unless(ind == 0 or ind == 1 or ind == 59)
  			slice_element = []
  			topic_arr = page.text.split(/\n{2,}/)
        topic_arr.each do |f|
          f.gsub!(/\s{2,}/,'')
        end
        topic_arr.slice!(0) if topic_arr[0].match(/\d{1,2}/)
        topic_arr.pop
        if topic_arr.join(' ').match(/ACTA No. \d{1,2}/)
          act_no = topic_arr.join(' ').match(/ACTA No. \d{1,2}/).to_s
          act_no_index = topic_arr.index act_no
          order_index = topic_arr.index "ORDEN DEL DÍA"
          check_date_time topic_arr,order_index+1
          f.puts "        <heading>#{@year}</heading>" unless @year.nil?
          unless @month.nil?
            f.puts "        <debatesection>"
            f.puts "          <heading>#{@month}</heading>"  
          end
          unless(@date.nil? or @month.nil? or @year.nil?)
            f.puts "          <debatesection>"
            f.puts "            <heading>#{@date}.#{@month}.#{@year}</heading>"
          end
          f.puts "            <debatesection>" unless @year.nil?
          f.puts "              <heading>NAME OF HANSARD - #{act_no}</heading>"
          narrative = topic_arr[act_no_index+1...order_index].join('<br>')
          narrative.gsub!(/\n/,"<br>")
          f.puts "                <narrative>#{narrative}</narrative>"
        elsif topic_arr.include? "CUESTIONARIO"
          que_index = topic_arr.index "CUESTIONARIO"
          topic_arr.slice!(0..que_index)
          # topic_arr.pop
          unless topic_arr.empty?
            topic_arr.each do |que|
              if que.match(/^\d{1,2}/)
                no = que.match(/^\d{1,2}/).to_s
                f.puts "              <questions id='no-" + no + "'>"
                f.puts "                <heading id='hno-" + no + "'></heading>"
                f.puts "                <question by='#'>" + "#{que} </question>"
                f.puts "                <answer by='#'></answer>"
                f.puts "              </questions>"
              end
            end
          end
        end
        if topic_arr.include?("LO QUE PROPONGAN LOS HONORABLES SENADORES." || "LO QUE PROPONGAN LOS HONORABLES SENADORES" || "LO QUE PROPONGAN LOS H. REPRESENTANTES" || "LO QUE PROPONGAN LOS H. REPRESENTANTES.")
          debate = true
          debate_index = topic_arr.index("LO QUE PROPONGAN LOS HONORABLES SENADORES") || topic_arr.index("LO QUE PROPONGAN LOS HONORABLES SENADORES.") || topic_arr.index("LO QUE PROPONGAN LOS H. REPRESENTANTES") || topic_arr.index("LO QUE PROPONGAN LOS H. REPRESENTANTES.")
          # topic_arr.pop
          topic_arr.slice!(0..debate_index)
        end

        if debate and !topic_arr.empty?
          # topic_arr.slice!(0)
          # topic_arr.pop
          (topic_arr.length-1).downto(1) do |i|
            unless topic_arr[i].match(/(^[A-Z](.*):)\s/)
              topic_arr[i-1] = topic_arr[i-1] + topic_arr[i]
              slice_element << i
            end
          end
  			  slice_element.each do |a|
  				  topic_arr.slice!(a)
  			  end
          puts ind 
          unless topic_arr[0].match(/(^[A-Z](.*):)\s/)
            if !last_ele.nil? and last_ele.match(/(^[A-Z](.*):)\s/)
              topic_arr[0] = last_ele + topic_arr[0]
              topic_arr.slice!(0)
            end
          else
            file_write f,last_ele
          end
  			  last_ele = topic_arr.last
          topic_arr.pop
  			  topic_arr.each do |topic|
            file_write f,topic
  			  end
        end
  		# end
		end
    f.puts "            </debatesection>" unless @year.nil?
    f.puts "          </debatesection>" unless(@date.nil? or @month.nil? or @year.nil?)
    f.puts "        </debatesection>" unless @month.nil?
		f.puts "      </debatesection>"
		f.puts "    </debatebody>"
		f.puts "  </debate>"
		f.puts "</akomaNtoso>"
	end

  def file_write file,content
    itopic = content.split(":")
    head = itopic[0]
    if(@president == "" or @secretary == "")
      check_president_secretary head
    end
    unless head.nil?
      head.gsub!(' ', '-') 
      head.gsub!(/\n|\*{1,}/,"")
    end
    body = itopic.length <= 2 ? itopic[1] : itopic[1..itopic.length-1].join('')
    body.gsub!(/\n/, '<br>') unless body.nil?
    head.downcase! unless head.nil?
    head = @president if !head.nil? and head.match(/president/i)
    head = @secretary if !head.nil? and head.match(/secretaria/i)
    unless(head.nil? or body.nil?)
      file.puts "              <speech by='##{head}' startTime='#{@final_date}'>"
      unless head.nil?
        head.upcase!
        head.gsub!(/#|\n|\*{1,}/,"")
        head.gsub!(/-{1,}/," ")
      end
      file.puts "                <from>#{head}</from>"
      file.puts "                  <p>#{body}</p>"
      file.puts
      file.puts "              </speech>"
    end
  end

  def check_date_time topics,i
    months = ['enero','febrero','marcha','abril','pueda','junio','julio','augusto','septiembre','octubre','noviembre','diciembre']
    time = ""
    months.each do |m|
      date = '\d{1,2}\sde\s' + "#{m}" + '\sde\s\d{4}'
      if topics[i].match(/#{date}/i)
        @month = months.index(m) + 1
        a = topics[i].match(/#{date}/i).to_s
        @date = a.match(/\d{1,2}\sde/).to_s.scan(/\d/).join('').to_i
        @year = a.match(/\sde\s\d{4}/).to_s.scan(/\d/).join('').to_i
      end
      if topics[i].match(/\d{1,2}:\d{2}/)
        t1 = topics[i].match(/\d{1,2}:\d{2}.*/i).to_s
        t2h = t1.match(/\d{1,2}:/).to_s.scan(/\d/).join('').to_i
        t2m = t1.match(/:\d{2}/).to_s.scan(/\d/).join('')

        time = t1.scan(/[a-z]/i).join('').downcase == "am" ? "#{t2h}:"+t2m : "#{t2h+12}:"+t2m
      end
      if @date
        break
      end
    end
    @final_date = "#{@year}-#{@month}-#{@date}T#{time}"
  end

  def check_president_secretary str
    if !str.nil? and str.match(/president/i)
      p = str.match(/president[a-z]*/i).to_s
      pre = str.split(p)
      first_letter = pre[1].index(pre[1].match(/[a-z]/i).to_s)
      pre[1].slice!(0...first_letter)
      @president = pre[1]
    end
    if !str.nil? and str.match(/secretaria/i)
      s = str.match(/secretaria/i).to_s
      sec = str.split(s)
      first_letter = sec[1].index(sec[1].match(/[a-z]/i).to_s)
      sec[1].slice!(0...first_letter)
      @secretary = sec[1]
    end
  end

end

pf = PdfReader.new
pf.pdf_reader_action
puts "all done"