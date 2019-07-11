module Aws::RailsProvisioner
  class CDKBuilder

    def initialize(options = {})
      @source_files = options[:source_files]
      @default_stack = options[:default_stack]
      @cdk_dir = options[:cdk_dir]
      @services = options[:services]
    end

    def run
      _init_cdk
      # code to files
      files = @source_files
      files.each do |path, code|
        if File.exists?(path)
          puts "replacing #{path}"
        else
          puts "creating #{path}"
        end
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') do |f|
          f.write(code)
        end
      end
      _install_dependencies
      _npm_build
    end

    private

    def _init_cdk
      unless Dir.exist?(@cdk_dir)
        FileUtils.mkdir_p(@cdk_dir)
        unless @dryrun
          Dir.chdir(@cdk_dir) do
            `npm i -g aws-cdk`
            `cdk init app --language=typescript`
          end

          if File.exists?(@default_stack)
            FileUtils.rm_f(@default_stack)
          end
        end
      end
    end

    def _install_dependencies
      pkgs = @services.inject(Set.new) do |set, svc|
        set.merge(svc.packages)
        set
      end
      Dir.chdir(@cdk_dir) do
        pkgs.each do |pkg|
          `npm install #{pkg}`
        end
      end
    end

    def _npm_build
      Dir.chdir(@cdk_dir) do
        puts "running npm run build ..."
        `npm run build`
      end
    end

  end
end
