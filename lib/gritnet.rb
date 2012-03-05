# encoding: utf-8

require 'grit'
require 'json'
require 'fileutils'
require 'uri'
require 'net/http'

class Gritnet
  include Grit
  DB = {}
  CMDLINE_CACHE = {}

  attr_accessor :tree, :repo, :branches, :path, :github_path
  def initialize(path = nil)
    @path = path || "."
    @github_path = File.join((@path.split('/') - ['.git'])[-2..-1])
    @tree = nil
    @repo = Repo.new(@path)
    prefix_length = (prefix = "#{@path}/.git/refs/remotes/").length
    @branches = Dir["#{prefix}*/*"]
      .collect {|s| s[prefix_length..-1] }
      .reject {|s| s =~ /\/gh-pages$/ } # special case for github
  end

  def parse!
    branches_count = @branches.length
    @branches.each_with_index do |name, index|
      next unless commit = @repo.commits(name, 1).first
      curr = MBranch.find_or_create(@repo, @path + "/.git", commit.sha, commit, name)
      $stderr.puts "#{index+1}/#{branches_count})\t#{name} #{commit.sha}" + (@tree ? " (root=#{@tree.sha})" : "") # if $DEBUG
      if @tree.nil?
        @tree = curr
      elsif @tree.sha == commit.sha
        # skip
      elsif curr.parent # conflict, shared position in @tree
        # skip
      elsif newroot = @tree.get_merge_base(curr)
        newroot.add(@tree)
        newroot.add(curr)
        @tree = newroot
      end
    end
  end

  class MCommit
    attr_accessor :sha, :repo
    def initialize(repo, sha)
      self.repo = repo
      self.sha = sha
      DB[self.sha] = self
    end
    def meta
      @meta ||= begin
        self.repo.blob(self.sha).data.split(/[\r\n]+/).collect {|s| s.split }.inject({}) do |sum, (key, *values)|
          sum.merge(key => values.join(' '))
        end
      end
    end
    def author_string
      self.meta["author"]
    end
  end

  class MBranch
    attr_accessor :name, :commit, :parent, :children, :path, :repo, :github_path, :siblings
    def sha
      self.commit && self.commit.sha
    end
    def initialize(repo, path, commit, name = nil, children = [])
      @parent          = nil # do not use attr writer
      self.repo        = repo
      self.path        = path
      self.github_path = File.join((path.split('/') - ['.git'])[-2..-1])
      self.name        = name
      self.commit      = commit
      self.children    = children
      self.siblings    = []
      DB[self.sha]     = self
    end
    def names
      [name] + self.siblings
    end
    def pretty_name
      names.join(', ')
    end
    def self.find_or_create(repo, path, sha, commit = nil, name = nil, children = [])
      (DB[sha] ||= MBranch.new(repo, path, commit || MCommit.new(repo, sha), name || sha, children)).tap do |branch|
        return branch if name.nil? || branch.siblings.index(name)
        if branch.name == branch.sha
          branch.name = name
        elsif branch.name == name
          # skip
        else
          branch.siblings << name
        end
      end
    end
    def get_merge_base(other, indent=0)
      cmdline = "git --git-dir=#{@path} merge-base #{[self.sha, other.sha].sort.join(' ')}"
      merge_base_sha = CMDLINE_CACHE[cmdline] ||= `#{cmdline}`.chomp
      if merge_base_sha.to_s != ''
        MBranch.find_or_create(@repo, @path, merge_base_sha).tap do |found|
          $stderr.puts "#{' ' * ((indent+1)*2)}#{found.name} (#{self.name}, #{other.name})" # if $DEBUG
        end
      end
    end
    def parent=(newparent)
      return if (@parent && @parent.sha) == newparent.sha
      @parent.children.delete(self) if @parent
      newparent.children.unshift(self)
      @parent = newparent
    end
    def add(other, indent=0)
      return if (other.sha == self.sha) ||
                ((other.parent && other.parent.sha) == self.sha) ||
                (self.children.find {|c| c.sha == other.sha})
      other.parent = self
      self.children.dup.each_with_index do |child, index|
        next if index == 0 # assuming "newparent.children.unshift(self)"
        newparent = child.get_merge_base(other, indent+1)
        case newparent && newparent.sha
        when self.sha
          # confirmed child & other are siblings
          next
        when child.sha
          child.add(other, indent+1)
        when other.sha
          other.add(child, indent+1)
        else
          if newparent
            newparent.add(other, indent+1)
            newparent.add(child, indent+1)
            # self.children << newparent unless self.children.find {|c| c.sha == newparent.sha }
            self.add(newparent, indent+1)
          end
        end
        break
      end
    end
    def to_json
      {
        self.pretty_name => self.children.collect {|s| s.to_json }
      }
    end
  end
end
