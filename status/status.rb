#!/usr/bin/env ruby

require "yaml"
require "json"
require "net/ssh"
require "thread"

USAGE_CMD = "mpstat | grep 'all' | awk '{printf \"%d\\n\", 100-\$NF}'; free -m | grep 'Mem:' | awk '{printf \"%d\\n\", (\$3/\$2)*100}';"
UPDATES_CMD = "[ -f /var/run/reboot-required ] && echo 'REBOOT REQUIRED' || (UPDATES=$(apt-get upgrade -s | grep '^Inst' | cut -d' ' -f2); [ -z \"$UPDATES\" ] && echo 'UP TO DATE' || echo 'UPDATES AVAILABLE');"
DOCKER_CMD = "docker ps --format '{{json .}}';"

CPU_WARN = 50
CPU_DANGER = 80
MEM_WARN = 70
MEM_DANGER = 85

config_path = File.join(File.dirname(__FILE__), "config.yml")

def green(str)
  "\033[32m#{str}\033[0m"
end
def yellow(str)
  "\033[33m#{str}\033[0m"
end
def red(str)
  "\033[31m#{str}\033[0m"
end
def grey(str)
  "\033[90m#{str}\033[0m"
end
def blue(str)
  "\033[94m#{str}\033[0m"
end

def process_server(server, out)
  out_server = server["name"].ljust(42)

  cmd = USAGE_CMD + UPDATES_CMD + (server["docker"] == false ? "" : DOCKER_CMD)

  ssh_options = {}
  ssh_options[:keys] = [server["identity_file"]] if server["identity_file"]

  Net::SSH.start(server["name"], server["user"] || "root", ssh_options) do |ssh|
    output = ssh.exec!(cmd)

    cpu, mem, updates, docker = output.split("\n", 4)

    cpu = cpu.to_i
    out_cpu = "CPU: #{cpu}%".ljust(10)
    out_cpu = cpu > CPU_DANGER ? red(out_cpu) : cpu > CPU_WARN ? yellow(out_cpu) : green(out_cpu)

    mem = mem.to_i
    out_mem = "MEM: #{mem}%".ljust(12)
    out_mem = mem > MEM_DANGER ? red(out_mem) : mem > MEM_WARN ? yellow(out_mem) : green(out_mem)

    out_updates = updates.ljust(20)
    out_updates = updates == "UP TO DATE" ? green(out_updates) : updates == "REBOOT REQUIRED" ? red(out_updates) : yellow(out_updates)

    out_docker = unless server["docker"] == false
      running = docker.lines.map do |line|
        docker_json = JSON.parse(line)
        docker_json["Names"]
      end
      missing = server["containers"].dup
      missing += ["kamal-proxy"] unless server["proxy"] == false
      missing.reject! { |container| running.any? { |name| name.start_with?(container) } }
      extras = running.dup.reject { |name| server["containers"].any? { |container| name.start_with?(container) } }
      extras -= ["kamal-proxy"] unless server["proxy"] == false
      if missing.any?
        red("MISSING: #{missing.join(", ")}")
      elsif extras.any?
        yellow("EXTRA: #{extras.join(", ")}")
      else
        green("DOCKER OK")
      end
    else
      grey("NO DOCKER")
    end

    # Use mutex to ensure thread-safe output
    $output_mutex.synchronize do
      out << "#{out_server} #{out_cpu} #{out_mem} #{out_updates} #{out_docker}"
    end
    print "."
  end 
rescue => e
  $output_mutex.synchronize do
    out << red("#{server["name"].ljust(45)} ERROR: #{e.message}")
  end
end

# Simple thread pool implementation
class ThreadPool
  def initialize(size)
    @size = size
    @jobs = Queue.new
    @pool = Array.new(@size) do |i|
      Thread.new do
        Thread.current[:id] = i
        catch(:exit) do
          loop do
            job, args = @jobs.pop
            job.call(*args)
          end
        end
      end
    end
  end

  def schedule(*args, &block)
    @jobs << [block, args]
  end

  def shutdown
    @size.times do
      schedule { throw :exit }
    end
    @pool.map(&:join)
  end
end

# Create a mutex for thread-safe output
$output_mutex = Mutex.new

# Create a thread pool with a maximum of 10 concurrent connections
thread_pool = ThreadPool.new(10)

# Process servers in parallel
groups = YAML.load_file(config_path)

total_servers = 0
groups.each do |group, servers|
  total_servers += servers.count
end
puts "Checking #{total_servers} servers..."
puts "⌄#{" "*(total_servers-2)}⌄"

out = {}
groups.each do |group, servers|
  containers = 0
  servers.each do |server|
    next if server["docker"] == false
    containers += server["containers"].count
    containers += 1 unless server["proxy"] == false
  end

  out[group] = [blue("#{group.upcase} | #{servers.count} SERVERS | #{containers} CONTAINERS")]

  servers.each do |server|
    thread_pool.schedule do
      process_server(server, out[group])
    end
  end
end

# Wait for all threads to complete
thread_pool.shutdown

puts "\n\n"
groups.each do |group, servers|
  puts out[group].join("\n")
  puts ""
end
