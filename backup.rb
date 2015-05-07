require 'pdf-reader'
require 'rubygems'
require 'byebug'

class PdfReader
	def pdf_reader_action
  	f = File.open('pdf_output.xml','w')
  	f.puts "<akomaNtoso>"
  	f.puts "  <debate>"
  	f.puts "    <debatebody>"
  	f.puts "      <debatesection>"
		reader = PDF::Reader.new("sample_file2.pdf")
		last_ele = ""
		reader.pages.each_with_index do |page, ind|
			unless(ind == 0 or ind == 1 or ind == 59)
  			slice_element = []
  			topic_arr = page.text.split(/\n{2,}/)
        topic_arr.each do |f|
          f.gsub!(/\s{2,}/,'')
        end
        topic_arr.slice!(0)
        topic_arr.pop
        (topic_arr.length-1).downto(1) do |i|
          unless topic_arr[i].match(/(^[A-Z](.*):)\s/)
            topic_arr[i-1] = topic_arr[i-1] + topic_arr[i]
            slice_element << i
          end
        end
  			slice_element.each do |a|
  				topic_arr.slice!(a)
  			end
        unless topic_arr[0].match(/(^[A-Z](.*):)\s/)
          topic_arr[0] = last_ele + topic_arr[0]
        else
          file_write f,last_ele
        end
  			last_ele = topic_arr.last
        topic_arr.pop
  			topic_arr.each do |topic|
          file_write f,topic
  			end
  		end
		end
		f.puts "      <debatesection>"
		f.puts "    <debatebody>"
		f.puts "  <debate>"
		f.puts "<akomaNtoso>"
	end

  def file_write file,content
    itopic = content.split(":")
    head = itopic[0]
    unless head.nil?
      head.gsub!(' ', '-') 
      head.gsub!(/\n|\*{1,}/,"")
    end
    body = itopic.length == 2 ? itopic[1] : itopic[1..itopic.length-1].join('')
    body.gsub!(/\n/, '<br>') unless body.nil?
    head.downcase! unless head.nil?
    file.puts "        <speech by='##{head}' startTime='2013-02-20T00:00:00'>"
    unless head.nil?
      head.upcase!
      head.gsub!(/#|\n|\*{1,}/,"")
      head.gsub!(/-{1,}/," ")
    end
    file.puts "          <from>#{head}</from>"
    file.puts "          <p>#{body}</p>"
    file.puts
    file.puts "        </speech>"
  end

end

pf = PdfReader.new
pf.pdf_reader_action
puts "all done"