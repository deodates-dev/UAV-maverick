# @summary
#   Maverick_web::Janus class
#   This class installs and manages the Janus WebRTC gateway.
#
# @example Declaring the class
#   This class is included from maverick_web class and should not be included from elsewhere
#
# @param active
#   If true, starts the maverick-webrtc service and enables at boot
# @param http_port
#   Port to listen on for http signalling requests
# @param https_port
#   Port to listen on for https signalling requests
# @param rtp_stream_port
#   UDP port to listen for rtp stream (from gstreamer)
# @param rtsp_stream_port
#   RTSP port to connect to for stream (assumes localhost)
# @param stream_type
#   If set to "rtsp", this connects to an rtsp source (defined as rtsp://localhost:$rtsp_stream_port/video), for visiond in rtsp mode
#   If set to "rtp", this 'listens' on a udp port for incoming rdp stream, for visiond in udp mode
#   Recommended to set to "rtsp" mode, so other clients can share the connection
#
class maverick_web::janus (
    Boolean $active = true,
    Boolean $http_transport = true,
    Integer $https_port = 6012,
    Boolean $websockets_transport = true,
    Integer $websockets_port = 6011,
    Integer $rtp_stream_port = 6013,
    Integer $rtsp_stream_port = 6010,
    String  $stream_type = "rtsp",
) {

    ensure_packages(["libmicrohttpd-dev", "libjansson-dev", "libssl-dev", "libsrtp2-dev", "libsofia-sip-ua-dev", "libglib2.0-dev", "libopus-dev", "libogg-dev", "libcurl4-openssl-dev", "liblua5.3-dev", "libconfig-dev", "gengetopt", "libwebsockets-dev", "libnice-dev"])

    file { "/srv/maverick/config/web/janus":
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => "0755",
    }

    if ! ("install_flag_janus" in $installflags) {
        oncevcsrepo { "git-janus":
            gitsource   => "https://github.com/meetecho/janus-gateway.git",
            dest        => "/srv/maverick/var/build/janus-gateway",
        } ->
        exec { "janus-autogen":
            command		=> "/srv/maverick/var/build/janus-gateway/autogen.sh >/srv/maverick/var/log/build/janus.autogen.log 2>&1",
            cwd		    => "/srv/maverick/var/build/janus-gateway",
            creates     => "/srv/maverick/var/build/janus-gateway/configure",
            require     => [ Package['libsrtp2-dev'], Package["libnice-dev"], Package["libopus-dev"] ],
            timeout		=> 0,
            user        => "mav",
        } ->
        exec { "janus-configure":
            command		=> "/srv/maverick/var/build/janus-gateway/configure --prefix=/srv/maverick/software/janus-gateway --enable-websockets-event-handler --disable-aes-gcm >/srv/maverick/var/log/build/janus.configure.log 2>&1",
            cwd		    => "/srv/maverick/var/build/janus-gateway",
            creates     => "/srv/maverick/var/build/janus-gateway/Makefile",
            timeout		=> 0,
            user        => "mav",
        } ->
        exec { "janus-build":
            command		=> "/usr/bin/make >/srv/maverick/var/log/build/janus.build.log 2>&1",
            cwd		    => "/srv/maverick/var/build/janus-gateway",
            creates     => "/srv/maverick/var/build/janus-gateway/janus",
            timeout		=> 0,
            user        => "mav",
        } ->
        exec { "janus-install":
            command		=> "/usr/bin/make install >/srv/maverick/var/log/build/janus.install.log 2>&1",
            cwd		    => "/srv/maverick/var/build/janus-gateway",
            creates     => "/srv/maverick/software/janus-gateway/bin/janus",
            timeout		=> 0,
            user        => "mav",
        } ->
        exec { "janus-install-config":
            command		=> "/bin/bash -c 'for f in *.sample; do cp \$f /srv/maverick/config/web/janus/\${f%.*}; done;' >/srv/maverick/var/log/build/janus.install-config.log 2>&1",
            cwd		    => "/srv/maverick/software/janus-gateway/etc/janus",
            creates     => "/srv/maverick/software/janus-gateway/etc/janus/janus.jcfg",
            timeout		=> 0,
            user        => "mav",
            require     => File["/srv/maverick/config/web/janus"],
            before      => [ File["/srv/maverick/config/web/janus/janus.jcfg"], File["/srv/maverick/config/web/janus/janus.eventhandler.sampleevh.jcfg"], ],
        } ->
        file { "/srv/maverick/var/build/.install_flag_janus":
            ensure      => present,
            owner       => "mav",
            group       => "mav",
        }
    }
    
    file { "/srv/maverick/config/web/janus/janus.jcfg":
        content     => template("maverick_web/janus.jcfg.erb"),
        owner       => "mav",
        group       => "mav",
        mode        => "0644",
        notify      => Service["maverick-webrtc"],
    } ->
    file { "/srv/maverick/config/web/janus/janus.transport.http.jcfg":
        content     => template("maverick_web/janus.transport.http.jcfg.erb"),
        owner       => "mav",
        group       => "mav",
        mode        => "0644",
        notify      => Service["maverick-webrtc"],
    } ->
    file { "/srv/maverick/config/web/janus/janus.transport.websockets.jcfg":
        content     => template("maverick_web/janus.transport.websockets.jcfg.erb"),
        owner       => "mav",
        group       => "mav",
        mode        => "0644",
        notify      => Service["maverick-webrtc"],
    } ->
    file { "/srv/maverick/config/web/janus/janus.plugin.streaming.jcfg":
        content     => template("maverick_web/janus.plugin.streaming.jcfg.erb"),
        owner       => "mav",
        group       => "mav",
        mode        => "0644",
        notify      => Service["maverick-webrtc"],
    } ->
    file { "/srv/maverick/config/web/janus/janus.eventhandler.wsevh.jcfg":
        content     => template("maverick_web/janus.eventhandler.wsevh.jcfg.erb"),
        owner       => "mav",
        group       => "mav",
        mode        => "0644",
        notify      => Service["maverick-webrtc"],
    } ->

    # Remove unwanted config
    file { ["/srv/maverick/config/web/janus/janus.eventhandler.sampleevh.jcfg", "/srv/maverick/config/web/janus/janus.plugin.audiobridge.jcfg", "/srv/maverick/config/web/janus/janus.plugin.echotest.jcfg", "/srv/maverick/config/web/janus/janus.plugin.recordplay.jcfg", "/srv/maverick/config/web/janus/janus.plugin.textroom.jcfg", "/srv/maverick/config/web/janus/janus.plugin.videocall.jcfg", "/srv/maverick/config/web/janus/janus.plugin.videoroom.jcfg", "/srv/maverick/config/web/janus/janus.plugin.voicemail.jcfg", "/srv/maverick/config/web/janus/janus.transport.pfunix.jcfg"]:
        ensure      => absent,
    }

    # Control running service
    if $active == true {
        $_ensure = running
        $_enable = true
    } else {
        $_ensure = stopped
        $_enable = false
    }
    file { "/etc/systemd/system/maverick-webrtc.service":
        source      => "puppet:///modules/maverick_web/maverick-webrtc.service",
        owner       => "root",
        group       => "root",
        mode        => "644",
        notify      => [ Exec["maverick-systemctl-daemon-reload"], Service["maverick-webrtc"] ],
    } ->
    service { "maverick-webrtc":
        ensure      => $_ensure,
        enable      => $_enable,
    }
    
    if defined(Class["::maverick_security"]) {
        maverick_security::firewall::firerule { "webrtc-http":
            ports       => [$websockets_port, $https_port],
            ips         => lookup("firewall_ips"),
            proto       => "tcp"
        }
    }
    
    # status.d entry
    file { "/srv/maverick/software/maverick/bin/status.d/120.web/111.webrtc.status":
        owner   => "mav",
        content => "webrtc,WebRTC Janus Gateway\n",
    }

}
