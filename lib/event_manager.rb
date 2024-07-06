require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end
def clean_phone_number(num)
  num = num.scan(/\d/).join('')
  if num.length == 10 then return num
  elsif num.length == 11 && num[0] == 1 then return num.slice(1..10)
  else return '0000000000'
  end
end
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def count_frequency(array)
  freq = array.inject(Hash.new(0)) { |h, v| h[v] += 1; h }
  return array.max_by { |v| freq[v] }
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
contents_size = CSV.read('event_attendees.csv').length
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_arr = Array.new(contents_size)
day_arr = Array.new(contents_size)
j = 0
cal = {0=>"sunday",1=>"monday",2=>"tuesday",3=>"wednesday",4=>"thursday",5=>"friday",6=>"saturday"}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  #puts clean_phone_number(row[:homephone])
  form_letter = erb_template.result(binding)
  #save_thank_you_letter(id,form_letter)
  reg_date = row[:regdate]
  reg_date_to_print = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  puts reg_date_to_print.hour
  hour_arr[j] = reg_date_to_print.hour
  day_arr[j] = reg_date_to_print.wday

  j += 1
end

puts "The hour of the day most people registered was at #{count_frequency(hour_arr)}"
puts "The weekday most people registered on was on #{cal[count_frequency(day_arr)].capitalize}"
