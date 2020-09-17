class netprobe ($port, $attr_env, $attr_type)
{
# These variables will be used in the template netprobe_setup.erb
	$probename       = "_INF_SA_"
	$attr_region     = "NA"
	$region_type     = "AMER_LINUX_$attr_env"
	$primary_gw      = "CER-LX-ITRS04"
	$secondary_gw    = "WDC-LX-ITRS04"
	$attr_country	 = "US"

	$attr_dc = $::ipaddress ? {
		/10.2.*/ => 'WDC',
		/10.3.*|10.8.*/ => 'CER',
		/10.4.*/ => 'CHI',
		default	 => $::ipaddress,
	}

	$attr_server = $::virtual ? {
		'vmware' => 'VIRTUAL',
		default	=> 'PHYSICAL',
	}

	$gw_port = $attr_env ? {
		'PROD' => '7037',
		'UAT' => '7038',
		'DEV' => '7039',
		default => '7038',
	}

# Please ensure that the netprobe rpms found in files are added to your yum repo.
	package { 'netprobe':
		ensure	=> installed,
	}

	file { 'netprobe_xml':
		notify	=> Service["netprobe_$port"],
		path	=> "/opt/netprobe/netprobe_$port.xml",
		owner	=> 'svc.itrs',
		group	=> 'svc.itrs',
		mode	=> 0644,
		ensure	=> file,
		content => template('netprobe/netprobe_setup.erb'),
		require => Package['netprobe'],
	}

	file { 'netprobe_init':
		path	=> "/etc/init.d/netprobe_$port",
		owner	=> 'root',
		group	=> 'root',
		mode	=> 0755,
		ensure	=> file,
		content	=> template('netprobe/netprobe_init.erb'),
		require => Package['netprobe'],
	}
	
	file {'netprobe_start':
		path	=> "/opt/netprobe/start_netprobe",
		owner	=> "svc.itrs",
		group	=> "svc.itrs",
		mode	=> 0755,
		ensure	=> file,
		source	=> "puppet:///modules/netprobe/start_netprobe",
		require	=> Package['netprobe'],
	}

        service { "netprobe_$port":
                enable => true,
                ensure => running,
		hasrestart => true,
		hasstatus => true,
		subscribe => File['netprobe_xml'],
        }
}
