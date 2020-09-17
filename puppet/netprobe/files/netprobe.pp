## Import this .pp into the site.pp or copy the 
## class into the appropriate node
node netprobe_prod {
	class { 'netprobe':
		port            => 7040,
		attr_env        => "PROD",
		attr_type       => "INF",
        }
}
