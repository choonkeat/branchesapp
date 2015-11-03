# encoding: utf-8

require 'grit'
require 'json'
require 'fileutils'
require 'uri'
require 'net/http'

module Github
  class Project
    attr_accessor :forks
    def initialize(proj_url, forks = nil)
      @forks = forks
      @proj = nil
      @proj_uri = URI(proj_url)
      blah, @user, @proj, *blah = @proj_uri.path.split('/')
    end
    def forks(url = "https://api.github.com/repos/#{@user}/#{@proj}/forks")
      @forks || while url do
        uri = URI(url)
        puts uri.inspect
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          req = Net::HTTP::Get.new(uri.request_uri)
          req.basic_auth ENV['HTTP_USER'], ENV['HTTP_PASSWORD'] if ENV['HTTP_USER'] && ENV['HTTP_PASSWORD']
          http.request(req)
        end
        puts "RateLimit: #{res['X-RateLimit-Remaining']} / #{res['X-RateLimit-Limit']}"
        raise res.inspect + res.body unless res.code =~ /^2\d\d/
        @forks ||= []
        @forks += JSON.parse(res.body)
        blah, url = res['Link'].to_s.match(/<(.+?)>; rel="next"/).to_a
      end
      open("#{@user}.#{@proj}.json", "w:utf-8") {|f| f.write(@forks.to_json)}
      @forks
    end
    def git_dir
      @git_dir ||= File.join(ENV['PREFIX'] || "public", @user, @proj) + '.git'
    end
    def working_dir
      @working_dir ||= File.join(ENV['PREFIX'] || "public", @user, @proj)
    end
    def add_remotes
      File.exists?(File.join(working_dir, ".git")) || begin
        FileUtils.mkdir_p(git_dir) unless File.exists?(git_dir)
        bare = Grit::Repo.init_bare(git_dir)
        print `git clone #{git_dir} #{working_dir}`
        yield working_dir if block_given?
        Dir.chdir(working_dir) do
          print `git remote add #{@user} 'git://github.com/#{@user}/#{@proj}.git'`
          forks.each_with_index do |f, i|
            login, git_url = (f['owner'] && f['owner']['login'] || "github#{f['id']}"), f['git_url']
            puts "#{i}. #{login}"
            print `git remote add #{login} #{git_url} 2>&1`
          end
        end
      end
    end
    def fetch_all
      threads = []
      names = forks.inject([@user]) do |sum, f|
        sum + [f['owner'] && f['owner']['login'] || "github#{f['id']}"]
      end
      max_fetch_count = names.length
      fetch_count = 0
      max_fetch = (ENV['MAX_FETCH'] || 10).to_i
      max_threads = (ENV['MAX_THREADS'] || 10).to_i
      cmd_prefix = "git --git-dir=#{working_dir}/.git fetch --quiet --multiple"
      while threads.length < max_threads && names.first
        threads << Thread.new do
          while (piggies = max_fetch.times.collect { names.shift }.compact).first
            fetched = Dir["#{working_dir}/.git/refs/remotes/{#{piggies.join(',')}}"].collect {|p| File.basename(p) }
            piggies -= fetched
            next if piggies.empty?
            cmd = "#{cmd_prefix} #{piggies.join(' ')}"
            puts "#{fetch_count+=piggies.length}/#{max_fetch_count}) " + cmd
            `#{cmd}`
          end
        end
      end
      threads.each {|t| t.join}
    end
  end
end
