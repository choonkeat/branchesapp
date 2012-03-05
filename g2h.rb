#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require 'gritnet'
require 'github'
require 'json'
require 'cgi'
require 'haml'
require 'ostruct'

TO_HTML_COUNT = {}
Gritnet::MBranch.class_eval do
  def h(str)
    CGI.escapeHTML(str.to_s)
  end
  def better_author_string(str)
    values = str.strip.split
    if values[-2] =~ /^\d+$/
      values[-2] = Time.at(values[-2].to_i)
      values.pop
    end
    values.join(' ')
  end
  def commit_log_for(sha, name)
    parts = self.repo.blob(sha).data.split(/\n/)
    author = parts.find {|s| s =~ /^author\b/ }
    messages = parts[ parts.index(parts.find {|s| s =~ /^committer\b/ })+1..-1 ].join("\n").strip
    # tree, parent, author, committer, message = self.repo.blob(sha).data.split(/[\r\n]+/)
    timestamp, offset = author.split[-2..-1]
    "<span class=\"message\">#{h(messages)}</span>\n<span class=\"author\">#{h(author.split[1..--3].join(' '))} <a target=\"_blank\" href=\"#{h(name2url(name, sha))}\">on #{Time.at(timestamp.to_i).strftime('%-d %b %Y %l:%M%P')}</a></span>"
  rescue Exception
    $stderr.puts parts.inspect
    raise
  end
  def past_changes_html
    "<div class=\"changes\"><div><p>" +
    if self.parent
      self.repo.commits_between(self.parent.sha, self.sha).collect do |commit|
        commit_log_for(commit.sha, self.name)
      end.join("</p><p>")
    else
      commit_log_for(self.sha, self.name)
    end +
    "</p></div></div>"
  end
  def name2url(name, sha = nil)
    owner, project = github_path.split('/')
    user, branch = name.split('/')
    if branch && sha.nil?
      "https://github.com/#{user}/#{project}/tree/#{branch}"
    else
      "https://github.com/#{owner}/#{project}/commit/#{sha ||= user}" # where 'user' is actually a sha
    end
  end
  def to_html
    TO_HTML_COUNT[self.sha] = TO_HTML_COUNT[self.sha].to_i + 1
    puts "#{TO_HTML_COUNT.keys.length}) #{self.name} (#{TO_HTML_COUNT[self.sha]})"
    [
      "<li class=\"commit\" data-name=\"#{h(self.pretty_name)}\" data-sha=\"#{h(self.sha)}\">",
      self.past_changes_html,
      "<span class=\"names\">",
      self.names.collect {|name| "<a class=\"branch-name\" title=\"#{better_author_string self.commit.author_string}\" target=\"_blank\" href=\"#{h(name2url(name))}\">#{h(name)}</a>" }.join(", "),
      "</span>",
      "<ul class=\"children\">",
      self.children.collect {|c| c.to_html }.join("\n"),
      "</ul>",
      "</li>",
    ].join("\n")
  end
  def to_json_string
    [
      "{",
      self.pretty_name.to_json + ": [",
      self.children.collect {|s| s.to_json_string }.join(', '),
      "]",
      "}",
    ].join
  end
end

def render(context, template_filename, output_filename)
  puts "Rendering: " + [context.class, template_filename, output_filename].inspect
  engine = Haml::Engine.new(IO.read(template_filename))
  temp_path = output_filename + ".new"
  real_path = output_filename
  open(temp_path, "wb") {|f| f.write(engine.render(context)) }
  File.rename temp_path, real_path
end

github_url = ARGV.shift
forks_json = JSON.parse(open(ARGV.shift, 'r:utf-8') {|f| f.read}) if ARGV.first
github = Github::Project.new(github_url, forks_json)
github.add_remotes do |working_dir|
  context = OpenStruct.new(github_path: File.join(working_dir.split('/')[-2..-1]))
  render(context, 'views/wait.html.haml', File.join(working_dir, "index.html"))
end
t = Time.now
github.fetch_all
puts "Fetching: #{Time.now - t}s"
net = Gritnet.new(github.working_dir)
t = Time.now
net.parse!
puts "Parsing: #{Time.now - t}s"
t = Time.now
render(net, 'views/index.html.haml', File.join(github.working_dir, "index.html"))
puts "Rendering: #{Time.now - t}s"
