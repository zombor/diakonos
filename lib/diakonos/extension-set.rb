module Diakonos

  class ExtensionSet

    def initialize( root_dir )
      @extensions = Hash.new
      @root_dir = File.expand_path( root_dir )
    end

    def scripts
      @extensions.values.find_all { |e| e }.map { |e| e.scripts }.flatten
    end

    # @return an Array of configuration filenames to parse
    def load( dir )
      @extensions[ dir ] = false

      confs_to_parse = []
      ext_dir = File.join( @root_dir, dir )
      info = YAML.load_file( File.join( ext_dir, 'info.yaml' ) )

      if info[ 'requirements' ] && info[ 'requirements' ][ 'diakonos' ]
        this_version = ::Diakonos.parse_version( ::Diakonos::VERSION )
        min_version = ::Diakonos.parse_version( info[ 'requirements' ][ 'diakonos' ][ 'minimum' ] )
        if min_version && this_version >= min_version
          extension = Extension.new( ext_dir )
          @extensions[ dir ] = extension
          confs_to_parse += extension.confs
        end
      end

      confs_to_parse
    end

    def loaded?( ext_dir )
      @extensions[ ext_dir ]
    end

    def loaded_extensions
      @extensions.values.find_all { |e| e }
    end

    def not_loaded_extensions
      @extensions.keys.find_all { |e| ! loaded?( e ) }
    end

  end

end