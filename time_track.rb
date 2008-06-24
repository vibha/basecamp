require 'basecamp'
 
config = YAML::load(IO.read("access.yaml"))
session = Basecamp.new(config["url"], config["login"], config["password"])

Basecamp::Record.module_eval do
  define_method :user do
    @hash["first-name"] + " " + @hash["last-name"]
  end
  define_method :user_id do
     @hash["id"]
  end
end  

class Array; def sum; inject( nil ) { |sum,x| sum ? sum+x : x }; end; end
projects = session.projects
project_id = projects.collect { |p| "#{p.id}"}
company_id = projects.first.company.id
actions = ['Tme Tracking Report', 'Log Time', 'Delete Entry']
  
def chooser options, msg
  cmd = <<EOF
    tell app "SystemUIServer"
      activate
      choose from list { #{options.join(",") } } with prompt "#{msg}"
    end tell
EOF
  `echo '#{cmd}' | osascript`.chomp
end

puts "  Time-Tracking  " 
puts "-----------------------------------"

project_name = chooser(projects.collect { |p| "\"#{p.name}\""}, "Please choose a project:" ) 
project = projects.reject { |p| p.name != project_name }.first
abort if !project

people = session.people(company_id, project.id)
person = chooser(people.collect { |p| "\"#{p.user}\"" }, "Please choose a person:" ) 
person = people.reject { |p| p.user != person }.first
abort if !person

user_id = person.user_id

report = session.report_time(user_id, 20060601, 20080701)

total_hours = report.collect{|p| p.hours}.collect{|p| p.to_i}.sum

puts " Generating Report for #{person.user}"
puts "-----------------------------------"  
puts " Date     " + "      "  + " Description " + "    " +  " Hours "
report.each{|p| puts " #{p.date}  " + "  " + "  #{p.description}" + "  " + " #{p.hours}"}
puts "Total Hours = " + " #{total_hours}"

